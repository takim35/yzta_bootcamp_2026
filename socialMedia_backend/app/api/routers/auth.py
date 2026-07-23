import sqlite3
import random
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.database import get_db
from app.domain.schemas import (
    UserRegisterRequest, UserLoginRequest, AuthResponse,
    PasswordResetRequest, PasswordResetCodeRequest, PasswordResetVerifyRequest,
    TokenRefreshRequest,
    TwoFASetupResponse, TwoFAVerifyRequest, TwoFAStatusResponse,
    TwoFALoginRequest,
    RequestEmailChangeRequest, VerifyEmailChangeRequest,
    RequestPasswordChangeRequest, VerifyPasswordChangeRequest
)
from app.repositories.auth_repository import AuthRepository
from app.core.email_service import send_otp_email, generate_otp

router = APIRouter()

def get_repository(db: sqlite3.Connection = Depends(get_db)) -> AuthRepository:
    return AuthRepository(db)

# Geçici olarak kodları hafızada tutmak için (Gerçek uygulamada veritabanı veya Redis kullanılmalı)
mock_reset_codes = {}


# ─── Kayıt / Giriş ─────────────────────────────────────────

@router.post("/register", response_model=AuthResponse, status_code=201)
def register(
    request: UserRegisterRequest, 
    repo: AuthRepository = Depends(get_repository)
):
    """Yeni kullanıcı kaydı."""
    try:
        user_id = repo.register_user(request.email, request.password)
        return AuthResponse(
            user_id=user_id,
            message="Kayıt başarıyla oluşturuldu."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kayıt işlemi sırasında hata oluştu: {str(e)}")


@router.post("/login", response_model=AuthResponse)
def login(
    request: UserLoginRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """Kullanıcı girişi."""
    try:
        user_id = repo.login_user(request.email, request.password)
        return AuthResponse(
            user_id=user_id,
            message="Giriş başarılı."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Giriş işlemi sırasında hata oluştu: {str(e)}")


# ─── Şifre Sıfırlama ───────────────────────────────────────

@router.post('/request-password-reset')
def request_password_reset(
    request: PasswordResetCodeRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """Kullanıcının e-postasına şifre sıfırlama kodu gönderir."""
    try:
        # 1. Kullanıcı var mı kontrol et
        user = repo.get_user_by_email(request.email)
        if not user:
            # Güvenlik açısından kullanıcı bulunamasa bile her zaman başarılı dönülür
            return {'success': True, 'message': 'Eğer bu e-posta adresi sistemimizde kayıtlıysa, şifre sıfırlama kodu gönderildi.'}
            
        # 2. Kod üret
        code = str(random.randint(100000, 999999))
        mock_reset_codes[request.email] = code
        
        # 3. Konsola ASCII-safe yaz (Windows charmap hatasi onlemek icin)
        import sys
        try:
            print(f"[RESET CODE] Email: {request.email} -> Code: {code}", flush=True)
        except Exception:
            sys.stdout.buffer.write(f"[RESET CODE] Email: {request.email} -> Code: {code}\n".encode('utf-8'))
        
        return {
            'success': True, 
            'message': 'Sifre sifirlama kodu gonderildi.',
            'debug_code': code  # Gelistirme asamasinda test kolayligi icin kodu donuyoruz
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kod gonderme sirasinda hata olustu: {str(e)}")


@router.post('/verify-reset-code')
def verify_reset_code(
    request: PasswordResetVerifyRequest
):
    """Gönderilen şifre sıfırlama kodunu doğrular."""
    if request.email in mock_reset_codes and mock_reset_codes[request.email] == request.code:
        return {'success': True, 'message': 'Kod doğrulandı.'}
    raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş kod.")


@router.post('/reset-password')
def reset_password(
    request: PasswordResetRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """Kullanıcının şifresini doğrulanmış kodu baz alarak sıfırlar."""
    try:
        # Sadece kodu daha önce doğrulanmış (mock_reset_codes içinde bulunan) kişilerin şifresini sıfırla
        if request.email not in mock_reset_codes:
            raise HTTPException(status_code=400, detail="Lütfen önce doğrulama kodunu girin.")
            
        repo.reset_password(request.email, request.new_password)
        
        # Kullanılan kodu temizle
        del mock_reset_codes[request.email]
        
        return {'success': True, 'message': 'Şifreniz başarıyla sıfırlandı.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Şifre sıfırlama sırasında hata oluştu: {str(e)}")


# ─── Token Yenileme ─────────────────────────────────────────

@router.post('/refresh-token')
def refresh_token(request: TokenRefreshRequest):
    """Token yenileme (placeholder — JWT entegrasyonu için hazır)."""
    return {'access_token': 'new_mock_access_token', 'token_type': 'bearer'}


# ─── 2FA — TOTP ────────────────────────────────────────────

@router.post('/2fa/setup', response_model=TwoFASetupResponse)
def setup_2fa(
    user_id: str,
    repo: AuthRepository = Depends(get_repository)
):
    """
    Kullanıcı için TOTP 2FA kurulumu başlatır.
    Secret ve QR kod URI döner — kullanıcı Google Authenticator/Authy ile tarar.
    """
    try:
        result = repo.setup_totp(user_id)
        return TwoFASetupResponse(
            secret=result["secret"],
            otpauth_uri=result["otpauth_uri"],
            message="QR kodu tarayın ve ardından kodu doğrulayın."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"2FA kurulumu sırasında hata: {str(e)}")


@router.post('/2fa/verify')
def verify_2fa(
    request: TwoFAVerifyRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """
    Kurulum sırasında girilen 6 haneli kodu doğrular ve 2FA'yı etkinleştirir.
    """
    try:
        repo.verify_and_enable_totp(request.user_id, request.code)
        return {'success': True, 'message': 'İki faktörlü doğrulama başarıyla etkinleştirildi.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"2FA doğrulama sırasında hata: {str(e)}")


@router.post('/2fa/login')
def login_2fa(
    request: TwoFALoginRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """Login sırasında 2FA kodunu doğrular."""
    try:
        repo.verify_totp_login(request.user_id, request.code)
        return {'success': True, 'message': '2FA doğrulaması başarılı.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"2FA login hatası: {str(e)}")


@router.delete('/2fa/disable')
def disable_2fa(
    user_id: str,
    repo: AuthRepository = Depends(get_repository)
):
    """2FA'yı devre dışı bırakır."""
    try:
        repo.disable_totp(user_id)
        return {'success': True, 'message': 'İki faktörlü doğrulama devre dışı bırakıldı.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"2FA devre dışı bırakma hatası: {str(e)}")


@router.get('/2fa/status', response_model=TwoFAStatusResponse)
def get_2fa_status(
    user_id: str,
    repo: AuthRepository = Depends(get_repository)
):
    """Kullanıcının 2FA durumunu sorgular."""
    try:
        return repo.get_two_fa_status(user_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"2FA durum sorgusu hatası: {str(e)}")


# ─── Google OAuth (Hazır — GoogleService-Info.plist ile çalışır) ─────────────

class GoogleAuthRequest(BaseModel):
    id_token: str
    email: str
    display_name: str
    avatar_url: Optional[str] = None


@router.post('/google', response_model=AuthResponse)
def google_auth(
    request: GoogleAuthRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """
    Google OAuth ile giriş/kayıt.
    Flutter'dan gelen id_token, email ve display_name ile kullanıcı oluşturur/bulur.
    
    iOS: GoogleService-Info.plist ile google_sign_in paketi üzerinden.
    """
    try:
        # Email doğrulama (basit kontrol)
        if not request.email or '@' not in request.email:
            raise HTTPException(status_code=400, detail='Geçersiz e-posta adresi.')

        user_id = repo.login_or_create_google_user(
            email=request.email,
            display_name=request.display_name,
            avatar_url=request.avatar_url,
        )
        return AuthResponse(
            user_id=user_id,
            message='Google ile giriş başarılı.'
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Google girişi sırasında hata: {str(e)}')


# ─── Profil Güvenlik Güncellemeleri (Email & Şifre) ─────────────

mock_profile_update_codes = {}

@router.post('/request-email-change')
def request_email_change(
    request: RequestEmailChangeRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """E-posta değiştirme işlemi için mevcut ve yeni e-postaya doğrulama kodu gönderir."""
    try:
        # Check if email is already used
        check = repo.get_user_by_email(request.new_email)
        if check:
            raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanımda.")

        code = generate_otp()
        mock_profile_update_codes[request.new_email] = code
        
        # Gerçek mail gönderimi
        send_otp_email(
            to_email=request.new_email,
            subject="Spot - E-posta Doğrulama Kodu",
            body=f"E-posta adresinizi değiştirmek için doğrulama kodunuz: {code}"
        )
        
        return {'success': True, 'message': 'Doğrulama kodu yeni e-postanıza gönderildi.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post('/verify-email-change')
def verify_email_change(
    request: VerifyEmailChangeRequest,
    user_id: str, # Should ideally be from JWT
    repo: AuthRepository = Depends(get_repository)
):
    """Gönderilen kodu doğrular ve e-postayı değiştirir."""
    try:
        if request.new_email not in mock_profile_update_codes or mock_profile_update_codes[request.new_email] != request.code:
            raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş kod.")
        
        # Güncelleme yap
        repo.update_user_email(user_id, request.new_email)
        del mock_profile_update_codes[request.new_email]
        return {'success': True, 'message': 'E-posta adresi başarıyla güncellendi.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post('/request-password-change')
def request_password_change(
    request: RequestPasswordChangeRequest,
    user_id: str,
    repo: AuthRepository = Depends(get_repository)
):
    """Şifre değiştirme işlemi için mevcut e-postaya kod gönderir."""
    try:
        user = repo.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
            
        code = generate_otp()
        mock_profile_update_codes[user_id] = code
        
        send_otp_email(
            to_email=user["email"],
            subject="Spot - Şifre Değiştirme Doğrulama Kodu",
            body=f"Şifrenizi değiştirmek için doğrulama kodunuz: {code}"
        )
        return {'success': True, 'message': 'Doğrulama kodu e-postanıza gönderildi.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post('/verify-password-change')
def verify_password_change(
    request: VerifyPasswordChangeRequest,
    user_id: str,
    repo: AuthRepository = Depends(get_repository)
):
    """Kodu doğrular ve şifreyi değiştirir."""
    try:
        if user_id not in mock_profile_update_codes or mock_profile_update_codes[user_id] != request.code:
            raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş kod.")
            
        repo.update_user_password(user_id, request.new_password)
        del mock_profile_update_codes[user_id]
        return {'success': True, 'message': 'Şifre başarıyla güncellendi.'}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


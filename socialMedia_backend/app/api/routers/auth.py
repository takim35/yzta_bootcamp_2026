import sqlite3
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.database import get_db
from app.domain.schemas import (
    UserRegisterRequest, UserLoginRequest, AuthResponse,
    PasswordResetRequest, TokenRefreshRequest,
    TwoFASetupResponse, TwoFAVerifyRequest, TwoFAStatusResponse,
    TwoFALoginRequest,
)
from app.repositories.auth_repository import AuthRepository

router = APIRouter()

def get_repository(db: sqlite3.Connection = Depends(get_db)) -> AuthRepository:
    return AuthRepository(db)


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

@router.post('/reset-password')
def reset_password(
    request: PasswordResetRequest,
    repo: AuthRepository = Depends(get_repository)
):
    """Kullanıcının şifresini gerçek veritabanı güncellemesiyle sıfırlar."""
    try:
        repo.reset_password(request.email, request.new_password)
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

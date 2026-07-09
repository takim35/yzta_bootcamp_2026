import sqlite3
from fastapi import APIRouter, Depends, HTTPException

from app.core.database import get_db
from app.domain.schemas import (
    UserRegisterRequest, UserLoginRequest, AuthResponse, 
    PasswordResetRequest, TokenRefreshRequest, VerifyEmailRequest, Verify2FARequest
)
from app.repositories.auth_repository import AuthRepository

router = APIRouter()

def get_repository(db: sqlite3.Connection = Depends(get_db)) -> AuthRepository:
    return AuthRepository(db)

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
            message="Kayıt başarıyla oluşturuldu. Lütfen e-postanıza gelen kodu girerek doğrulayın."
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
        result = repo.login_user(request.email, request.password)
        
        if result["requires_2fa"]:
            return AuthResponse(
                user_id=result["user_id"],
                message="2FA Doğrulaması gerekiyor.",
                requires_2fa=True
            )
            
        return AuthResponse(
            user_id=result["user_id"],
            message="Giriş başarılı.",
            requires_2fa=False
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Giriş işlemi sırasında hata oluştu: {str(e)}")

@router.post('/reset-password')
def reset_password(request: PasswordResetRequest, repo: AuthRepository = Depends(get_repository)):
    repo.reset_password(request.email, request.new_password)
    return {'success': True, 'message': 'Şifreniz başarıyla sıfırlandı.'}

@router.post("/verify-email")
def verify_email(request: VerifyEmailRequest, repo: AuthRepository = Depends(get_repository)):
    if repo.verify_email(request.email, request.code):
        return {"success": True, "message": "E-posta başarıyla doğrulandı."}
    raise HTTPException(status_code=400, detail="Geçersiz doğrulama kodu.")

@router.get("/2fa/setup/{user_id}")
def setup_2fa(user_id: str, repo: AuthRepository = Depends(get_repository)):
    return repo.setup_2fa(user_id)

@router.post("/2fa/verify")
def verify_2fa(request: Verify2FARequest, repo: AuthRepository = Depends(get_repository)):
    if repo.verify_and_enable_2fa(request.user_id, request.code):
        return {"success": True, "message": "2FA başarıyla aktif edildi."}
    raise HTTPException(status_code=400, detail="Geçersiz 2FA kodu.")

@router.post("/2fa/login")
def login_2fa(request: Verify2FARequest, repo: AuthRepository = Depends(get_repository)):
    if repo.verify_2fa_login(request.user_id, request.code):
        return AuthResponse(
            user_id=request.user_id,
            message="2FA Giriş başarılı.",
            requires_2fa=False
        )
    raise HTTPException(status_code=401, detail="Geçersiz 2FA kodu.")

@router.post('/refresh-token')
def refresh_token(request: TokenRefreshRequest):
    return {'access_token': 'new_mock_access_token', 'token_type': 'bearer'}


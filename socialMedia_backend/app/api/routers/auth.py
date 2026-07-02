import sqlite3
from fastapi import APIRouter, Depends, HTTPException

from app.core.database import get_db
from app.domain.schemas import UserRegisterRequest, UserLoginRequest, AuthResponse
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

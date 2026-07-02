"""
Posts Router — Post oluşturma ve profil postları.

Curl Örnekleri:
--------------
# Yeni post oluştur
curl -X POST http://localhost:8000/posts \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-a-0001",
    "image_url": "https://example.com/posts/new.jpg",
    "caption": "Yeni kombinom!",
    "outfit_items": ["item-blazer-001", "item-pantolon-001"],
    "visibility": "public",
    "ai_training_consent": true
  }'

# Profil postlarını getir (sahibi olarak)
curl "http://localhost:8000/posts/users/user-a-0001/posts?viewer_id=user-a-0001"

# Profil postlarını getir (takipçi olarak)
curl "http://localhost:8000/posts/users/user-a-0001/posts?viewer_id=user-b-0002"

# Profil postlarını getir (yabancı olarak)
curl "http://localhost:8000/posts/users/user-a-0001/posts?viewer_id=user-c-0003"
"""

import sqlite3
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional

from app.core.database import get_db
from app.domain.schemas import (
    PostCreate, PostResponse, MessageResponse, 
    LikeRequest, SaveRequest, CommentRequest, CommentResponse
)
from app.repositories.post_repository import PostRepository

router = APIRouter()

def get_repository(db: sqlite3.Connection = Depends(get_db)) -> PostRepository:
    return PostRepository(db)

@router.post("", response_model=MessageResponse, status_code=201)
def create_post(
    post: PostCreate, 
    repo: PostRepository = Depends(get_repository)
):
    """Yeni post oluşturur."""
    try:
        post_id = repo.create_post(post)
        return MessageResponse(
            success=True,
            message="Post başarıyla oluşturuldu",
            data={"post_id": post_id},
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Post oluşturulurken hata: {str(e)}")


@router.get(
    "/users/{user_id}/posts",
    response_model=list[PostResponse],
)
def get_user_posts(
    user_id: str,
    viewer_id: Optional[str] = Query(None, description="Görüntüleyen kullanıcı ID"),
    repo: PostRepository = Depends(get_repository)
):
    """Kullanıcının profil postlarını döndürür."""
    try:
        return repo.get_user_posts(user_id, viewer_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Postlar getirilirken hata: {str(e)}")


@router.get("/users/{user_id}/saved_posts", response_model=list[PostResponse])
def get_saved_posts(
    user_id: str,
    repo: PostRepository = Depends(get_repository)
):
    """Kullanıcının kaydettiği postları döndürür."""
    try:
        return repo.get_saved_posts(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")


@router.post("/{post_id}/like", response_model=MessageResponse)
def like_post(
    post_id: str,
    request: LikeRequest,
    repo: PostRepository = Depends(get_repository)
):
    try:
        repo.toggle_like(post_id, request.user_id, like=True)
        return MessageResponse(success=True, message="Post beğenildi.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")

@router.delete("/{post_id}/like", response_model=MessageResponse)
def unlike_post(
    post_id: str,
    user_id: str = Query(...),
    repo: PostRepository = Depends(get_repository)
):
    try:
        repo.toggle_like(post_id, user_id, like=False)
        return MessageResponse(success=True, message="Beğeni geri alındı.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")

@router.post("/{post_id}/save", response_model=MessageResponse)
def save_post(
    post_id: str,
    request: SaveRequest,
    repo: PostRepository = Depends(get_repository)
):
    try:
        repo.toggle_save(post_id, request.user_id, save=True)
        return MessageResponse(success=True, message="Post kaydedildi.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")

@router.delete("/{post_id}/save", response_model=MessageResponse)
def unsave_post(
    post_id: str,
    user_id: str = Query(...),
    repo: PostRepository = Depends(get_repository)
):
    try:
        repo.toggle_save(post_id, user_id, save=False)
        return MessageResponse(success=True, message="Kaydedilenlerden çıkarıldı.")
    except HTTPException:
        raise
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")

@router.post("/{post_id}/comments", response_model=MessageResponse)
def add_comment(
    post_id: str,
    request: CommentRequest,
    repo: PostRepository = Depends(get_repository)
):
    try:
        comment_id = repo.add_comment(post_id, request.user_id, request.content)
        return MessageResponse(success=True, message="Yorum eklendi.", data={"comment_id": comment_id})
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")

@router.get("/{post_id}/comments", response_model=list[CommentResponse])
def get_comments(
    post_id: str,
    repo: PostRepository = Depends(get_repository)
):
    try:
        return repo.get_comments(post_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hata: {str(e)}")


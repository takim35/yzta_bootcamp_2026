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
from app.domain.schemas import PostCreate, PostResponse, MessageResponse
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

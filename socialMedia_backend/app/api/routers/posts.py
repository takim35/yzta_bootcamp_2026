from __future__ import annotations
import uuid
import sqlite3
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, List

from app.core.database import get_db
from app.domain.schemas import PostCreate, PostResponse, OutfitItemResponse, MessageResponse
from app.repositories.post_repository import PostRepository

router = APIRouter()

@router.post("", response_model=MessageResponse, status_code=201)
def create_post(post: PostCreate, db: sqlite3.Connection = Depends(get_db)):
    try:
        return PostRepository.create_post(db, post)
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{post_id}", response_model=MessageResponse)
def delete_post(
    post_id: str,
    user_id: str = Query(..., description="Silen kullanıcı ID"),
    db: sqlite3.Connection = Depends(get_db),
):
    """Bir gönderiyi siler. Sadece gönderi sahibi silebilir."""
    try:
        row = db.execute("SELECT user_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Gönderi bulunamadı")
        if row[0] != user_id:
            raise HTTPException(status_code=403, detail="Bu gönderiyi silme yetkiniz yok")

        # İlişkili kayıtları temizle
        db.execute("DELETE FROM post_outfit_items WHERE post_id = ?", (post_id,))
        db.execute("DELETE FROM likes WHERE post_id = ?", (post_id,))
        try:
            db.execute("DELETE FROM comments WHERE post_id = ?", (post_id,))
        except Exception:
            pass  # comments tablosu yoksa geç
        db.execute("DELETE FROM posts WHERE post_id = ?", (post_id,))
        db.commit()
        return MessageResponse(success=True, message="Gönderi silindi")
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@router.get("/users/{user_id}/posts", response_model=List[PostResponse])
def get_user_posts(user_id: str, viewer_id: Optional[str] = Query(None), db: sqlite3.Connection = Depends(get_db)):
    try:
        return PostRepository.get_user_posts(db, user_id, viewer_id)
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@router.get('/users/{user_id}/saved_posts', response_model=List[PostResponse])
def get_saved_posts(user_id: str):
    return []

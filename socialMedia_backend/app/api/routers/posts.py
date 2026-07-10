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
def get_saved_posts(user_id: str, db: sqlite3.Connection = Depends(get_db)):
    """Kullanıcının kaydettiği gönderileri döndürür."""
    try:
        rows = db.execute(
            """SELECT p.*, u.username, u.display_name, u.avatar_url
               FROM saves s
               JOIN posts p ON s.post_id = p.post_id
               JOIN users u ON p.user_id = u.user_id
               WHERE s.user_id = ?
               ORDER BY s.created_at DESC""",
            (user_id,)
        ).fetchall()
        posts = []
        for row in rows:
            is_liked = db.execute('SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?', (row['post_id'], user_id)).fetchone() is not None
            outfit_rows = db.execute('SELECT item_id, category, image_url FROM post_outfit_items WHERE post_id = ?', (row['post_id'],)).fetchall()
            outfit_items = [OutfitItemResponse(item_id=oi['item_id'], category=oi['category'], image_url=oi['image_url']) for oi in outfit_rows]
            posts.append(PostResponse(post_id=row['post_id'], user_id=row['user_id'], username=row['username'], display_name=row['display_name'], avatar_url=row['avatar_url'], image_url=row['image_url'], caption=row['caption'], visibility=row['visibility'], ai_training_consent=bool(row['ai_training_consent']), likes_count=row['likes_count'], comments_count=row['comments_count'], is_liked=is_liked, is_saved=True, outfit_items=outfit_items, created_at=row['created_at']))
        return posts
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{post_id}/save", response_model=MessageResponse, status_code=201)
def save_post(post_id: str, req: dict, db: sqlite3.Connection = Depends(get_db)):
    """Gönderiyi kaydeder (bookmark)."""
    try:
        user_id = req.get('user_id')
        if not user_id:
            raise HTTPException(status_code=400, detail="user_id gerekli")
        post = db.execute("SELECT post_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")
        existing = db.execute("SELECT 1 FROM saves WHERE post_id = ? AND user_id = ?", (post_id, user_id)).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Bu gönderiyi zaten kaydetmişsiniz")
        db.execute("INSERT INTO saves (post_id, user_id) VALUES (?, ?)", (post_id, user_id))
        db.commit()
        return MessageResponse(success=True, message="Gönderi kaydedildi")
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{post_id}/save", response_model=MessageResponse)
def unsave_post(post_id: str, user_id: str = Query(...), db: sqlite3.Connection = Depends(get_db)):
    """Gönderi kaydını kaldırır."""
    try:
        db.execute("DELETE FROM saves WHERE post_id = ? AND user_id = ?", (post_id, user_id))
        db.commit()
        return MessageResponse(success=True, message="Kayıt kaldırıldı")
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))


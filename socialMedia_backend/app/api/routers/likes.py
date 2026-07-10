"""
Likes & Comments Router

Endpoints:
  POST   /posts/{post_id}/like              - Beğen
  DELETE /posts/{post_id}/like?user_id=...  - Beğeniyi kaldır
  POST   /posts/{post_id}/comments          - Yorum ekle
  GET    /posts/{post_id}/comments          - Yorumları listele
"""
from __future__ import annotations

import sqlite3
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional

from app.core.database import get_db
from app.domain.schemas import MessageResponse
from app.api.routers.notifications import create_notification

router = APIRouter()


# ─── Like Models ──────────────────────────────────────────────
class LikeRequest(BaseModel):
    user_id: str


# ─── Comment Models ───────────────────────────────────────────
class CommentRequest(BaseModel):
    user_id: str
    content: str
    parent_id: Optional[str] = None


# ══════════════════════════════════════════════════════════════
# LIKES
# ══════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/like", response_model=MessageResponse, status_code=201)
def like_post(post_id: str, req: LikeRequest, db: sqlite3.Connection = Depends(get_db)):
    """Bir postu beğenir."""
    try:
        post = db.execute("SELECT post_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")

        existing = db.execute(
            "SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?",
            (post_id, req.user_id),
        ).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Bu postu zaten beğendiniz")

        db.execute("INSERT INTO likes (post_id, user_id) VALUES (?, ?)", (post_id, req.user_id))
        db.execute("UPDATE posts SET likes_count = likes_count + 1 WHERE post_id = ?", (post_id,))

        # Bildirim gönder
        post_owner = db.execute("SELECT user_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if post_owner:
            create_notification(db, post_owner['user_id'], req.user_id, 'like', post_id=post_id)

        db.commit()

        return MessageResponse(success=True, message="Beğeni eklendi")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Beğeni eklenirken hata: {e}")


@router.delete("/posts/{post_id}/like", response_model=MessageResponse)
def unlike_post(
    post_id: str,
    user_id: str = Query(..., description="Beğeniyi kaldıran kullanıcı ID"),
    db: sqlite3.Connection = Depends(get_db),
):
    """Bir postun beğenisini kaldırır. user_id query param olarak alınır."""
    try:
        existing = db.execute(
            "SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?",
            (post_id, user_id),
        ).fetchone()
        if not existing:
            # Zaten beğenilmemiş - 404 yerine başarılı döndür (idempotent)
            return MessageResponse(success=True, message="Beğeni zaten yoktu")

        db.execute("DELETE FROM likes WHERE post_id = ? AND user_id = ?", (post_id, user_id))
        db.execute(
            "UPDATE posts SET likes_count = MAX(0, likes_count - 1) WHERE post_id = ?",
            (post_id,),
        )
        db.commit()

        return MessageResponse(success=True, message="Beğeni kaldırıldı")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Beğeni kaldırılırken hata: {e}")


# ══════════════════════════════════════════════════════════════
# COMMENTS
# ══════════════════════════════════════════════════════════════

@router.post("/posts/{post_id}/comments", status_code=201)
def add_comment(post_id: str, req: CommentRequest, db: sqlite3.Connection = Depends(get_db)):
    """Post'a veya bir yoruma yorum (yanıt) ekler."""
    try:
        post = db.execute("SELECT post_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")
            
        if req.parent_id:
            parent = db.execute("SELECT comment_id FROM comments WHERE comment_id = ? AND post_id = ?", (req.parent_id, post_id)).fetchone()
            if not parent:
                raise HTTPException(status_code=404, detail="Yanıtlanacak ana yorum bulunamadı")

        comment_id = f"cmt-{uuid.uuid4().hex[:12]}"
        now = datetime.utcnow().isoformat()

        db.execute(
            "INSERT INTO comments (comment_id, post_id, user_id, content, parent_id, created_at) VALUES (?,?,?,?,?,?)",
            (comment_id, post_id, req.user_id, req.content, req.parent_id, now),
        )
        try:
            db.execute(
                "UPDATE posts SET comments_count = comments_count + 1 WHERE post_id = ?",
                (post_id,),
            )
        except Exception:
            pass

        # Bildirim gönder
        post_owner = db.execute("SELECT user_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if post_owner:
            create_notification(db, post_owner['user_id'], req.user_id, 'comment', post_id=post_id, comment_id=comment_id)

        db.commit()

        return {"success": True, "data": {"comment_id": comment_id}}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorum eklenirken hata: {e}")


@router.get("/posts/{post_id}/comments")
def get_comments(post_id: str, user_id: Optional[str] = Query(None), db: sqlite3.Connection = Depends(get_db)):
    """Post'un yorumlarını listeler. parent_id = NULL olanları ana yorum olarak alır ve alt yorumları (replies) içerisine gömer."""
    try:
        # Tüm yorumları çek (aynı posta ait)
        rows = db.execute(
            """SELECT c.comment_id, c.user_id, u.username, u.avatar_url, c.content, c.parent_id, c.likes_count, c.created_at
               FROM comments c
               LEFT JOIN users u ON c.user_id = u.user_id
               WHERE c.post_id = ?
               ORDER BY c.created_at ASC""",
            (post_id,),
        ).fetchall()
        
        # Kullanıcının beğendiği yorumları çek
        liked_comment_ids = set()
        if user_id:
            likes = db.execute("SELECT comment_id FROM comment_likes WHERE user_id = ?", (user_id,)).fetchall()
            liked_comment_ids = {row[0] for row in likes}

        # Yorumları parent_id'ye göre grupla
        comments_dict = {}
        for r in rows:
            comment_id = r['comment_id']
            comments_dict[comment_id] = {
                "comment_id": comment_id,
                "post_id": post_id,
                "user_id": r['user_id'],
                "username": r['username'] or "Bilinmeyen",
                "avatar_url": r['avatar_url'],
                "content": r['content'],
                "parent_id": r['parent_id'],
                "likes_count": r['likes_count'],
                "is_liked": comment_id in liked_comment_ids,
                "created_at": r['created_at'],
                "replies": []
            }
            
        root_comments = []
        for c_id, c_data in comments_dict.items():
            if c_data['parent_id']:
                parent = comments_dict.get(c_data['parent_id'])
                if parent:
                    parent['replies'].append(c_data)
                else:
                    root_comments.append(c_data) # Ana yorum silinmişse kök olarak göster
            else:
                root_comments.append(c_data)

        return root_comments
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorumlar alınırken hata: {e}")

@router.post("/comments/{comment_id}/like", response_model=MessageResponse, status_code=201)
def like_comment(comment_id: str, req: LikeRequest, db: sqlite3.Connection = Depends(get_db)):
    """Bir yorumu beğenir."""
    try:
        comment = db.execute("SELECT comment_id FROM comments WHERE comment_id = ?", (comment_id,)).fetchone()
        if not comment:
            raise HTTPException(status_code=404, detail="Yorum bulunamadı")

        existing = db.execute(
            "SELECT 1 FROM comment_likes WHERE comment_id = ? AND user_id = ?",
            (comment_id, req.user_id),
        ).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Bu yorumu zaten beğendiniz")

        db.execute("INSERT INTO comment_likes (comment_id, user_id) VALUES (?, ?)", (comment_id, req.user_id))
        db.execute("UPDATE comments SET likes_count = likes_count + 1 WHERE comment_id = ?", (comment_id,))
        db.commit()

        return MessageResponse(success=True, message="Yorum beğenildi")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorum beğenilirken hata: {e}")

@router.delete("/comments/{comment_id}/like", response_model=MessageResponse)
def unlike_comment(
    comment_id: str,
    user_id: str = Query(..., description="Beğeniyi kaldıran kullanıcı ID"),
    db: sqlite3.Connection = Depends(get_db),
):
    """Bir yorumun beğenisini kaldırır."""
    try:
        existing = db.execute(
            "SELECT 1 FROM comment_likes WHERE comment_id = ? AND user_id = ?",
            (comment_id, user_id),
        ).fetchone()
        if not existing:
            return MessageResponse(success=True, message="Beğeni zaten yoktu")

        db.execute("DELETE FROM comment_likes WHERE comment_id = ? AND user_id = ?", (comment_id, user_id))
        db.execute("UPDATE comments SET likes_count = MAX(0, likes_count - 1) WHERE comment_id = ?", (comment_id,))
        db.commit()

        return MessageResponse(success=True, message="Yorum beğenisi kaldırıldı")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorum beğenisi kaldırılırken hata: {e}")

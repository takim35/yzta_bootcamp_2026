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

router = APIRouter()


# ─── Like Models ──────────────────────────────────────────────
class LikeRequest(BaseModel):
    user_id: str


# ─── Comment Models ───────────────────────────────────────────
class CommentRequest(BaseModel):
    user_id: str
    text: str


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
    """Post'a yorum ekler."""
    try:
        post = db.execute("SELECT post_id FROM posts WHERE post_id = ?", (post_id,)).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")

        comment_id = f"cmt-{uuid.uuid4().hex[:12]}"
        now = datetime.utcnow().isoformat()

        # comments tablosu yoksa oluştur
        db.execute("""
            CREATE TABLE IF NOT EXISTS comments (
                comment_id TEXT PRIMARY KEY,
                post_id    TEXT NOT NULL,
                user_id    TEXT NOT NULL,
                text       TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (post_id) REFERENCES posts(post_id),
                FOREIGN KEY (user_id) REFERENCES users(user_id)
            )
        """)

        db.execute(
            "INSERT INTO comments (comment_id, post_id, user_id, text, created_at) VALUES (?,?,?,?,?)",
            (comment_id, post_id, req.user_id, req.text, now),
        )
        try:
            db.execute(
                "UPDATE posts SET comments_count = comments_count + 1 WHERE post_id = ?",
                (post_id,),
            )
        except Exception:
            pass  # comments_count sutunu yoksa gec
        db.commit()

        return {"success": True, "data": {"comment_id": comment_id}}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorum eklenirken hata: {e}")


@router.get("/posts/{post_id}/comments")
def get_comments(post_id: str, db: sqlite3.Connection = Depends(get_db)):
    """Post'un yorumlarını listeler."""
    try:
        db.execute("""
            CREATE TABLE IF NOT EXISTS comments (
                comment_id TEXT PRIMARY KEY,
                post_id    TEXT NOT NULL,
                user_id    TEXT NOT NULL,
                text       TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)
        rows = db.execute(
            """SELECT c.comment_id, c.user_id, u.username, c.text, c.created_at
               FROM comments c
               LEFT JOIN users u ON c.user_id = u.user_id
               WHERE c.post_id = ?
               ORDER BY c.created_at ASC""",
            (post_id,),
        ).fetchall()

        return [
            {
                "comment_id": r[0],
                "user_id": r[1],
                "username": r[2] or "Bilinmeyen",
                "text": r[3],
                "created_at": r[4],
            }
            for r in rows
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Yorumlar alınırken hata: {e}")

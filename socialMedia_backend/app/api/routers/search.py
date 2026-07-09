import sqlite3
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional

from app.core.database import get_db
from app.domain.schemas import UserResponse

router = APIRouter()

@router.get("", response_model=List[UserResponse])
def search_users(
    query: str = Query(..., min_length=1, description="Arama sorgusu (kullanıcı adı veya isim)"),
    viewer_id: Optional[str] = Query(None, description="Aramayı yapan kullanıcı ID"),
    db: sqlite3.Connection = Depends(get_db)
):
    """
    Kullanıcı arama uç noktası.
    Hem 'username' hem de 'display_name' alanlarında 'LIKE' sorgusu yapar.
    """
    search_term = f"%{query}%"
    
    try:
        rows = db.execute(
            """
            SELECT user_id, email, username, display_name, avatar_url, bio,
                   followers_count, following_count, created_at, profile_visibility
            FROM users
            WHERE username LIKE ? OR display_name LIKE ?
            LIMIT 50
            """,
            (search_term, search_term)
        ).fetchall()
        
        results = []
        for row in rows:
            user_id = row["user_id"]
            
            is_following = False
            if viewer_id and viewer_id != user_id:
                follow_check = db.execute(
                    "SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ?",
                    (viewer_id, user_id)
                ).fetchone()
                is_following = follow_check is not None
                
            results.append(
                UserResponse(
                    user_id=user_id,
                    email=row["email"],
                    username=row["username"],
                    display_name=row["display_name"],
                    avatar_url=row["avatar_url"],
                    bio=row["bio"],
                    followers_count=row["followers_count"],
                    following_count=row["following_count"],
                    created_at=row["created_at"],
                    is_following=is_following,
                    profile_visibility=row["profile_visibility"],
                )
            )
            
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Arama işlemi sırasında hata oluştu: {e}")

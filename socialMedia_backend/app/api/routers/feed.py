
import sqlite3
from fastapi import APIRouter, Depends, HTTPException, Query
from app.core.database import get_db
from app.domain.schemas import PostResponse, FeedResponse
from app.repositories.post_repository import PostRepository

router = APIRouter()

@router.get("/feed", response_model=FeedResponse)
def get_feed(user_id: str, limit: int = Query(20, ge=1, le=50), db: sqlite3.Connection = Depends(get_db)):
    try:
        posts = PostRepository.get_feed(db, user_id, limit)
        return FeedResponse(posts=posts, next_cursor=None)
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

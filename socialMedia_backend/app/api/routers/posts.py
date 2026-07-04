
import uuid
import sqlite3
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional

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

@router.get("/users/{user_id}/posts", response_model=list[PostResponse])
def get_user_posts(user_id: str, viewer_id: Optional[str] = Query(None), db: sqlite3.Connection = Depends(get_db)):
    try:
        return PostRepository.get_user_posts(db, user_id, viewer_id)
    except HTTPException: raise
    except Exception as e: raise HTTPException(status_code=500, detail=str(e))

@router.get('/users/{user_id}/saved_posts', response_model=list[PostResponse])
def get_saved_posts(user_id: str):
    return []

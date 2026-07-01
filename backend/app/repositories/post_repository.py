import sqlite3
import uuid
from typing import Optional, List
from fastapi import HTTPException

from app.domain.schemas import PostCreate, PostResponse, OutfitItemResponse

class PostRepository:
    def __init__(self, db: sqlite3.Connection):
        self.db = db

    def create_post(self, post: PostCreate) -> str:
        post_id = str(uuid.uuid4())

        # Check if user exists
        user = self.db.execute("SELECT user_id FROM users WHERE user_id = ?", (post.user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        # Create post
        self.db.execute(
            """
            INSERT INTO posts (post_id, user_id, image_url, caption, visibility, ai_training_consent)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                post_id,
                post.user_id,
                post.image_url,
                post.caption,
                post.visibility,
                1 if post.ai_training_consent else 0,
            ),
        )

        # Add outfit items
        for item_id in post.outfit_items:
            self.db.execute(
                """
                INSERT INTO post_outfit_items (post_id, item_id)
                VALUES (?, ?)
                """,
                (post_id, item_id),
            )

        self.db.commit()
        return post_id

    def get_user_posts(self, user_id: str, viewer_id: Optional[str]) -> List[PostResponse]:
        # Check if user exists
        user = self.db.execute("SELECT user_id FROM users WHERE user_id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        if viewer_id and viewer_id == user_id:
            # Owner: see all
            rows = self.db.execute(
                """
                SELECT p.*, u.username, u.display_name, u.avatar_url
                FROM posts p
                JOIN users u ON p.user_id = u.user_id
                WHERE p.user_id = ?
                ORDER BY p.created_at DESC
                """,
                (user_id,),
            ).fetchall()
        elif viewer_id:
            # Follower or public
            rows = self.db.execute(
                """
                SELECT p.*, u.username, u.display_name, u.avatar_url
                FROM posts p
                JOIN users u ON p.user_id = u.user_id
                WHERE p.user_id = ?
                  AND (
                    p.visibility = 'public'
                    OR (
                      p.visibility = 'followers'
                      AND EXISTS (
                        SELECT 1 FROM follows
                        WHERE follower_id = ? AND following_id = p.user_id
                      )
                    )
                  )
                ORDER BY p.created_at DESC
                """,
                (user_id, viewer_id),
            ).fetchall()
        else:
            # Anonymous
            rows = self.db.execute(
                """
                SELECT p.*, u.username, u.display_name, u.avatar_url
                FROM posts p
                JOIN users u ON p.user_id = u.user_id
                WHERE p.user_id = ? AND p.visibility = 'public'
                ORDER BY p.created_at DESC
                """,
                (user_id,),
            ).fetchall()

        posts = []
        for row in rows:
            is_liked = False
            if viewer_id:
                like_check = self.db.execute(
                    "SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?",
                    (row["post_id"], viewer_id),
                ).fetchone()
                is_liked = like_check is not None

            outfit_rows = self.db.execute(
                "SELECT item_id, category, image_url FROM post_outfit_items WHERE post_id = ?",
                (row["post_id"],),
            ).fetchall()
            outfit_items = [
                OutfitItemResponse(
                    item_id=oi["item_id"],
                    category=oi["category"],
                    image_url=oi["image_url"],
                )
                for oi in outfit_rows
            ]

            posts.append(
                PostResponse(
                    post_id=row["post_id"],
                    user_id=row["user_id"],
                    username=row["username"],
                    display_name=row["display_name"],
                    avatar_url=row["avatar_url"],
                    image_url=row["image_url"],
                    caption=row["caption"],
                    visibility=row["visibility"],
                    ai_training_consent=bool(row["ai_training_consent"]),
                    likes_count=row["likes_count"],
                    is_liked=is_liked,
                    outfit_items=outfit_items,
                    created_at=row["created_at"],
                )
            )

        return posts

def get_post_repository(db: sqlite3.Connection) -> PostRepository:
    return PostRepository(db)

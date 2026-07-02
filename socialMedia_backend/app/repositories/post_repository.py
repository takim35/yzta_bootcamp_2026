import sqlite3
import uuid
from typing import Optional, List
from fastapi import HTTPException

from app.domain.schemas import PostCreate, PostResponse, OutfitItemResponse, CommentResponse

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
            is_saved = False
            comments_count = 0
            if viewer_id:
                like_check = self.db.execute(
                    "SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?",
                    (row["post_id"], viewer_id),
                ).fetchone()
                is_liked = like_check is not None
                
                save_check = self.db.execute(
                    "SELECT 1 FROM saves WHERE post_id = ? AND user_id = ?",
                    (row["post_id"], viewer_id),
                ).fetchone()
                is_saved = save_check is not None

            comment_count_row = self.db.execute(
                "SELECT COUNT(*) as c FROM comments WHERE post_id = ?",
                (row["post_id"],),
            ).fetchone()
            comments_count = comment_count_row["c"] if comment_count_row else 0

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
                    comments_count=comments_count,
                    is_liked=is_liked,
                    is_saved=is_saved,
                    outfit_items=outfit_items,
                    created_at=row["created_at"],
                )
            )

        return posts

    def get_saved_posts(self, user_id: str) -> List[PostResponse]:
        rows = self.db.execute(
            """
            SELECT p.*, u.username, u.display_name, u.avatar_url
            FROM saves s
            JOIN posts p ON s.post_id = p.post_id
            JOIN users u ON p.user_id = u.user_id
            WHERE s.user_id = ?
            ORDER BY s.created_at DESC
            """,
            (user_id,)
        ).fetchall()

        posts = []
        for row in rows:
            is_liked = False
            is_saved = True # Since these are saved posts
            comments_count = 0

            like_check = self.db.execute(
                "SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?",
                (row["post_id"], user_id),
            ).fetchone()
            is_liked = like_check is not None

            comment_count_row = self.db.execute(
                "SELECT COUNT(*) as c FROM comments WHERE post_id = ?",
                (row["post_id"],),
            ).fetchone()
            comments_count = comment_count_row["c"] if comment_count_row else 0

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
                    comments_count=comments_count,
                    is_liked=is_liked,
                    is_saved=is_saved,
                    outfit_items=outfit_items,
                    created_at=row["created_at"],
                )
            )
        return posts

    def toggle_like(self, post_id: str, user_id: str, like: bool):
        post = self.db.execute(
            "SELECT post_id FROM posts WHERE post_id = ?", (post_id,)
        ).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")

        if like:
            try:
                self.db.execute(
                    "INSERT INTO likes (post_id, user_id) VALUES (?, ?)",
                    (post_id, user_id),
                )
                self.db.execute(
                    "UPDATE posts SET likes_count = likes_count + 1 WHERE post_id = ?",
                    (post_id,),
                )
            except sqlite3.IntegrityError:
                pass
        else:
            res = self.db.execute(
                "DELETE FROM likes WHERE post_id = ? AND user_id = ?",
                (post_id, user_id),
            )
            if res.rowcount > 0:
                self.db.execute(
                    "UPDATE posts SET likes_count = MAX(0, likes_count - 1) WHERE post_id = ?",
                    (post_id,),
                )
        self.db.commit()

    def toggle_save(self, post_id: str, user_id: str, save: bool):
        post = self.db.execute(
            "SELECT post_id FROM posts WHERE post_id = ?", (post_id,)
        ).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı")

        if save:
            try:
                self.db.execute("INSERT INTO saves (post_id, user_id) VALUES (?, ?)", (post_id, user_id))
            except sqlite3.IntegrityError:
                pass
        else:
            self.db.execute("DELETE FROM saves WHERE post_id = ? AND user_id = ?", (post_id, user_id))
        self.db.commit()

    def add_comment(self, post_id: str, user_id: str, content: str) -> str:
        content = content.strip()
        if not content:
            raise HTTPException(status_code=400, detail="Yorum boş olamaz.")

        post = self.db.execute(
            "SELECT post_id FROM posts WHERE post_id = ?", (post_id,)
        ).fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="Post bulunamadı.")

        user = self.db.execute(
            "SELECT user_id FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

        comment_id = str(uuid.uuid4())
        self.db.execute(
            "INSERT INTO comments (comment_id, post_id, user_id, content) VALUES (?, ?, ?, ?)",
            (comment_id, post_id, user_id, content),
        )
        self.db.commit()
        return comment_id

    def get_comments(self, post_id: str) -> List[CommentResponse]:
        rows = self.db.execute(
            """
            SELECT c.*, u.username, u.avatar_url
            FROM comments c
            JOIN users u ON c.user_id = u.user_id
            WHERE c.post_id = ?
            ORDER BY c.created_at ASC
            """,
            (post_id,)
        ).fetchall()
        
        return [
            CommentResponse(
                comment_id=row["comment_id"],
                post_id=row["post_id"],
                user_id=row["user_id"],
                username=row["username"],
                avatar_url=row["avatar_url"],
                content=row["content"],
                created_at=row["created_at"]
            ) for row in rows
        ]

def get_post_repository(db: sqlite3.Connection) -> PostRepository:
    return PostRepository(db)

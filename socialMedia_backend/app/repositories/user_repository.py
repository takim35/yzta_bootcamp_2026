import sqlite3
from fastapi import HTTPException
from app.domain.schemas import UserResponse

class UserRepository:
    def __init__(self, db: sqlite3.Connection):
        self.db = db

    def get_user_profile(self, user_id: str) -> UserResponse:
        user = self.db.execute(
            """
            SELECT user_id, email, username, display_name, avatar_url, bio,
                   followers_count, following_count, created_at, profile_visibility
            FROM users WHERE user_id = ?
            """,
            (user_id,)
        ).fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
        
        return UserResponse(**dict(user))

    def update_user_profile(self, user_id: str, display_name: str | None, bio: str | None, avatar_url: str | None) -> None:
        updates = []
        params = []
        if display_name is not None:
            updates.append("display_name = ?")
            params.append(display_name)
        if bio is not None:
            updates.append("bio = ?")
            params.append(bio)
        if avatar_url is not None:
            updates.append("avatar_url = ?")
            params.append(avatar_url)
            
        if not updates:
            return
            
        params.append(user_id)
        query = f"UPDATE users SET {', '.join(updates)} WHERE user_id = ?"
        self.db.execute(query, params)
        self.db.commit()

    def update_privacy_settings(self, user_id: str, profile_visibility: str) -> None:
        self.db.execute("UPDATE users SET profile_visibility = ? WHERE user_id = ?", (profile_visibility, user_id))
        self.db.commit()

    def delete_account(self, user_id: str) -> None:
        self.db.execute("DELETE FROM users WHERE user_id = ?", (user_id,))
        self.db.commit()

from __future__ import annotations
from typing import Optional, Union
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
                   followers_count, following_count, created_at, profile_visibility,
                   height, weight, chest, waist, hips, location, timezone
            FROM users WHERE user_id = ?
            """,
            (user_id,)
        ).fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
        
        return UserResponse(**dict(user))

    def update_user_profile(
        self, user_id: str, 
        display_name: Optional[str] = None, 
        bio: Optional[str] = None, 
        avatar_url: Optional[str] = None,
        height: Optional[str] = None,
        weight: Optional[str] = None,
        chest: Optional[str] = None,
        waist: Optional[str] = None,
        hips: Optional[str] = None,
        location: Optional[str] = None,
        timezone: Optional[str] = None
    ) -> None:
        updates = []
        params = []
        
        fields = {
            "display_name": display_name,
            "bio": bio,
            "avatar_url": avatar_url,
            "height": height,
            "weight": weight,
            "chest": chest,
            "waist": waist,
            "hips": hips,
            "location": location,
            "timezone": timezone
        }
        
        for k, v in fields.items():
            if v is not None:
                updates.append(f"{k} = ?")
                params.append(v)
            
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

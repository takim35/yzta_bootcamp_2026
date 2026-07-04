import sqlite3
import hashlib
import uuid
from fastapi import HTTPException
from typing import Optional

def hash_password(password: str) -> str:
    """Şifreyi SHA-256 ile hashler."""
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

class AuthRepository:
    def __init__(self, db: sqlite3.Connection):
        self.db = db

    def register_user(self, email: str, password: str) -> str:
        """Yeni bir kullanıcı oluşturur ve veritabanına kaydeder."""
        # Email kontrolü
        existing_user = self.db.execute("SELECT user_id FROM users WHERE email = ?", (email,)).fetchone()
        if existing_user:
            raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanımda.")

        user_id = f"user-{str(uuid.uuid4())[:8]}"
        username = email.split('@')[0]
        
        # Username eşsizliğini sağlamak için
        existing_username = self.db.execute("SELECT user_id FROM users WHERE username = ?", (username,)).fetchone()
        if existing_username:
            username = f"{username}_{str(uuid.uuid4())[:4]}"

        password_hash = hash_password(password)

        try:
            self.db.execute(
                """
                INSERT INTO users (user_id, username, email, password_hash, display_name)
                VALUES (?, ?, ?, ?, ?)
                """,
                (user_id, username, email, password_hash, username)
            )
            self.db.commit()
            return user_id
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="Kayıt oluşturulurken veritabanı hatası oluştu.")

    def login_user(self, email: str, password: str) -> str:
        """Kullanıcı girişi yapar ve başarılıysa user_id döner."""
        user = self.db.execute(
            "SELECT user_id, password_hash FROM users WHERE email = ?", (email,)
        ).fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="Hesabınız bulunamadı, lütfen kayıt olun.")

        if user["password_hash"] != hash_password(password):
            raise HTTPException(status_code=401, detail="Şifre hatalı, lütfen tekrar deneyin.")

        return user["user_id"]

    def reset_password(self, email: str, new_password: str) -> None:
        """Kullanıcının şifresini sıfırlar (mocked)."""
        user = self.db.execute("SELECT user_id FROM users WHERE email = ?", (email,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.")
        
        new_hash = hash_password(new_password)
        self.db.execute("UPDATE users SET password_hash = ? WHERE email = ?", (new_hash, email))
        self.db.commit()

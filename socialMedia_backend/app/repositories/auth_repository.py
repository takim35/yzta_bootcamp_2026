import sqlite3
import hashlib
import uuid
import pyotp
import bcrypt
from fastapi import HTTPException
from typing import Optional

def hash_password(password: str) -> str:
    """Şifreyi bcrypt ile hashler."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    """Şifreyi bcrypt hash ile doğrular. Eski SHA-256 hashlerle geriye uyumlu."""
    # Eski SHA-256 hashleri destekle (64 karakter hex)
    if len(hashed) == 64 and not hashed.startswith('$2'):
        return hashlib.sha256(password.encode('utf-8')).hexdigest() == hashed
    # Yeni bcrypt hashleri
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

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

        if not verify_password(password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Şifre hatalı, lütfen tekrar deneyin.")

        return user["user_id"]

    def reset_password(self, email: str, new_password: str) -> None:
        """Kullanıcının şifresini sıfırlar — veritabanında gerçek güncelleme yapar."""
        user = self.db.execute("SELECT user_id FROM users WHERE email = ?", (email,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.")
        
        new_hash = hash_password(new_password)
        self.db.execute("UPDATE users SET password_hash = ? WHERE email = ?", (new_hash, email))
        self.db.commit()

    def get_user_by_email(self, email: str) -> Optional[dict]:
        """E-posta adresine göre kullanıcıyı bulur. Bulamazsa None döner."""
        user = self.db.execute(
            "SELECT user_id, username, email FROM users WHERE email = ?", (email,)
        ).fetchone()
        if user:
            return {"user_id": user["user_id"], "username": user["username"], "email": user["email"]}
        return None

    def get_user_by_id(self, user_id: str) -> Optional[dict]:
        """User ID'sine göre kullanıcıyı bulur."""
        user = self.db.execute(
            "SELECT user_id, username, email FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if user:
            return {"user_id": user["user_id"], "username": user["username"], "email": user["email"]}
        return None

    def update_user_email(self, user_id: str, new_email: str) -> None:
        """Kullanıcının e-postasını günceller."""
        try:
            self.db.execute("UPDATE users SET email = ? WHERE user_id = ?", (new_email, user_id))
            self.db.commit()
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanımda.")

    def update_user_password(self, user_id: str, new_password: str) -> None:
        """Kullanıcının şifresini günceller."""
        new_hash = hash_password(new_password)
        self.db.execute("UPDATE users SET password_hash = ? WHERE user_id = ?", (new_hash, user_id))
        self.db.commit()

    # ─── 2FA — TOTP ────────────────────────────────────────────

    def setup_totp(self, user_id: str) -> dict:
        """Kullanıcı için yeni TOTP secret üretir ve veritabanına kaydeder."""
        user = self.db.execute(
            "SELECT email FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

        secret = pyotp.random_base32()
        totp = pyotp.TOTP(secret)
        otpauth_uri = totp.provisioning_uri(
            name=user["email"],
            issuer_name="Dijital Gardrop"
        )

        self.db.execute(
            "UPDATE users SET totp_secret = ?, two_fa_enabled = 0 WHERE user_id = ?",
            (secret, user_id)
        )
        self.db.commit()

        return {"secret": secret, "otpauth_uri": otpauth_uri}

    def verify_and_enable_totp(self, user_id: str, code: str) -> bool:
        """Kullanıcının girdiği 6 haneli kodu doğrular ve 2FA'yı etkinleştirir."""
        user = self.db.execute(
            "SELECT totp_secret FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if not user or not user["totp_secret"]:
            raise HTTPException(status_code=400, detail="Önce 2FA kurulumu yapın.")

        totp = pyotp.TOTP(user["totp_secret"])
        if not totp.verify(code, valid_window=1):
            raise HTTPException(status_code=401, detail="Geçersiz doğrulama kodu.")

        self.db.execute(
            "UPDATE users SET two_fa_enabled = 1 WHERE user_id = ?", (user_id,)
        )
        self.db.commit()
        return True

    def verify_totp_login(self, user_id: str, code: str) -> bool:
        """Login sırasında 2FA kodunu doğrular."""
        user = self.db.execute(
            "SELECT totp_secret, two_fa_enabled FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
        if not user["two_fa_enabled"]:
            raise HTTPException(status_code=400, detail="Bu kullanıcı için 2FA etkinleştirilmemiş.")

        totp = pyotp.TOTP(user["totp_secret"])
        if not totp.verify(code, valid_window=1):
            raise HTTPException(status_code=401, detail="Geçersiz 2FA kodu.")
        return True

    def disable_totp(self, user_id: str) -> None:
        """2FA'yı devre dışı bırakır."""
        self.db.execute(
            "UPDATE users SET two_fa_enabled = 0, totp_secret = NULL WHERE user_id = ?",
            (user_id,)
        )
        self.db.commit()

    def get_two_fa_status(self, user_id: str) -> dict:
        """Kullanıcının 2FA durumunu döner."""
        user = self.db.execute(
            "SELECT two_fa_enabled FROM users WHERE user_id = ?", (user_id,)
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
        return {"user_id": user_id, "two_fa_enabled": bool(user["two_fa_enabled"])}

    # ─── Google OAuth ───────────────────────────────────────────

    def login_or_create_google_user(self, email: str, display_name: str, avatar_url: Optional[str] = None) -> str:
        """Google ile giriş: kullanıcı varsa bulur, yoksa oluşturur."""
        existing = self.db.execute(
            "SELECT user_id FROM users WHERE email = ?", (email,)
        ).fetchone()
        if existing:
            return existing["user_id"]

        # Yeni kullanıcı oluştur
        user_id = f"user-{str(uuid.uuid4())[:8]}"
        username = email.split('@')[0]

        existing_username = self.db.execute(
            "SELECT user_id FROM users WHERE username = ?", (username,)
        ).fetchone()
        if existing_username:
            username = f"{username}_{str(uuid.uuid4())[:4]}"

        try:
            self.db.execute(
                """
                INSERT INTO users (user_id, username, email, password_hash, display_name, avatar_url)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (user_id, username, email, "GOOGLE_AUTH_NO_PASSWORD", display_name or username, avatar_url)
            )
            self.db.commit()
            return user_id
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="Kullanıcı oluşturulurken hata oluştu.")

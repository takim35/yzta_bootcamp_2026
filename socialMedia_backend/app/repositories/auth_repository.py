import sqlite3
import uuid
import pyotp
from fastapi import HTTPException
from typing import Optional
import hashlib
import bcrypt

def hash_password(password: str) -> str:
    """Şifreyi bcrypt ile hashler. 72 byte limitini aşmamak için önce SHA256 ile özetlenir."""
    sha256_hash = hashlib.sha256(password.encode('utf-8')).hexdigest().encode('utf-8')
    hashed = bcrypt.hashpw(sha256_hash, bcrypt.gensalt())
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Girilen şifrenin hash ile eşleşip eşleşmediğini kontrol eder."""
    sha256_hash = hashlib.sha256(plain_password.encode('utf-8')).hexdigest().encode('utf-8')
    return bcrypt.checkpw(sha256_hash, hashed_password.encode('utf-8'))

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
        verification_code = str(uuid.uuid4().int)[:6] # 6 haneli kod
        
        try:
            self.db.execute(
                """
                INSERT INTO users (user_id, username, email, password_hash, display_name, verification_code, is_verified)
                VALUES (?, ?, ?, ?, ?, ?, 0)
                """,
                (user_id, username, email, password_hash, username, verification_code)
            )
            self.db.commit()
            print(f"MOCK EMAIL SENDER: {email} adresine doğrulama kodu gönderildi: {verification_code}")
            return user_id
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="Kayıt oluşturulurken veritabanı hatası oluştu.")

    def login_user(self, email: str, password: str) -> dict:
        """Kullanıcı girişi yapar. Eğer 2FA aktifse requires_2fa=True döner."""
        user = self.db.execute(
            "SELECT user_id, password_hash, is_verified, two_factor_enabled FROM users WHERE email = ?", (email,)
        ).fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="Hesabınız bulunamadı, lütfen kayıt olun.")

        if not verify_password(password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Şifre hatalı, lütfen tekrar deneyin.")
            
        if user["is_verified"] == 0:
            raise HTTPException(status_code=403, detail="E-posta adresiniz henüz doğrulanmamış. Lütfen doğrulayın.")

        return {
            "user_id": user["user_id"],
            "requires_2fa": bool(user["two_factor_enabled"])
        }

    def reset_password(self, email: str, new_password: str) -> None:
        """Kullanıcının şifresini sıfırlar (mocked)."""
        user = self.db.execute("SELECT user_id FROM users WHERE email = ?", (email,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.")
        
        new_hash = hash_password(new_password)
        self.db.execute("UPDATE users SET password_hash = ? WHERE email = ?", (new_hash, email))
        self.db.commit()

    def verify_email(self, email: str, code: str) -> bool:
        """Kullanıcının e-posta adresini doğrulamasını sağlar."""
        user = self.db.execute("SELECT user_id, verification_code FROM users WHERE email = ?", (email,)).fetchone()
        if not user or user["verification_code"] != code:
            return False
            
        self.db.execute("UPDATE users SET is_verified = 1, verification_code = NULL WHERE email = ?", (email,))
        self.db.commit()
        return True

    def setup_2fa(self, user_id: str) -> dict:
        """Kullanıcı için 2FA secret üretir ve döner."""
        user = self.db.execute("SELECT email FROM users WHERE user_id = ?", (user_id,)).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
            
        secret = pyotp.random_base32()
        self.db.execute("UPDATE users SET two_factor_secret = ? WHERE user_id = ?", (secret, user_id))
        self.db.commit()
        
        totp = pyotp.TOTP(secret)
        provisioning_uri = totp.provisioning_uri(name=user["email"], issuer_name="Spot App")
        
        return {"secret": secret, "qr_uri": provisioning_uri}

    def verify_and_enable_2fa(self, user_id: str, code: str) -> bool:
        """Kullanıcının girdiği kodu kontrol edip 2FA'yı aktif eder."""
        user = self.db.execute("SELECT two_factor_secret FROM users WHERE user_id = ?", (user_id,)).fetchone()
        if not user or not user["two_factor_secret"]:
            return False
            
        totp = pyotp.TOTP(user["two_factor_secret"])
        if totp.verify(code):
            self.db.execute("UPDATE users SET two_factor_enabled = 1 WHERE user_id = ?", (user_id,))
            self.db.commit()
            return True
        return False

    def verify_2fa_login(self, user_id: str, code: str) -> bool:
        """Giriş sırasında 2FA kodunu doğrular."""
        user = self.db.execute("SELECT two_factor_secret, two_factor_enabled FROM users WHERE user_id = ?", (user_id,)).fetchone()
        if not user or not user["two_factor_enabled"]:
            return True # 2FA açık değilse geç
            
        totp = pyotp.TOTP(user["two_factor_secret"])
        return totp.verify(code)

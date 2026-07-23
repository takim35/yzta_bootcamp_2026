"""
SQLite bağlantı yönetimi — Connection Pool ile optimize edilmiş.

- Thread-local connection pool: Her thread kendi bağlantısını yeniden kullanır
- WAL journal mode: Okuma/yazma çakışmasını önler
- PRAGMA optimizasyonları: cache_size, temp_store, mmap_size
- init_db() → schema.sql'i çalıştırır
- get_db() → FastAPI Depends uyumlu dependency
"""

import sqlite3
import threading
from pathlib import Path
from typing import Generator

from app.core.config import settings

SCHEMA_PATH = Path(__file__).resolve().parent.parent.parent / "schema.sql"

# Thread-local storage: Her thread kendi bağlantısını saklar
_local = threading.local()


def _connect() -> sqlite3.Connection:
    """Yeni bir SQLite bağlantısı oluşturur, performans PRAGMA'larını uygular."""
    conn = sqlite3.connect(
        settings.DATABASE_PATH,
        check_same_thread=False,
        timeout=10.0,
    )
    conn.row_factory = sqlite3.Row

    # Performans optimizasyonları
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")       # Eş zamanlı okuma/yazma
    conn.execute("PRAGMA synchronous = NORMAL")     # fsync azalt (WAL ile güvenli)
    conn.execute("PRAGMA cache_size = -8000")       # 8MB sayfa önbelleği
    conn.execute("PRAGMA temp_store = MEMORY")      # Geçici tabloları RAM'de tut
    conn.execute("PRAGMA mmap_size = 67108864")     # 64MB memory-mapped I/O

    return conn


def _get_thread_connection() -> sqlite3.Connection:
    """Mevcut thread'in bağlantısını döndürür, yoksa yeni oluşturur."""
    if not hasattr(_local, "conn") or _local.conn is None:
        _local.conn = _connect()
    return _local.conn


def get_db() -> Generator[sqlite3.Connection, None, None]:
    """
    FastAPI Depends uyumlu dependency.
    Thread-local bağlantıyı yeniden kullanır (pool etkisi).
    """
    conn = _get_thread_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        try:
            conn.rollback()
        except Exception:
            pass
        # Bağlantı bozulduysa sıfırla
        _local.conn = None
        raise


def init_db() -> None:
    """schema.sql dosyasını çalıştırarak tabloları oluşturur, ardından migration uygular."""
    if not SCHEMA_PATH.exists():
        raise FileNotFoundError(f"Schema dosyası bulunamadı: {SCHEMA_PATH}")

    schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")
    conn = _connect()
    try:
        conn.executescript(schema_sql)
        conn.commit()

        # ── Migration: 2FA kolonları ────────────────────────────
        # Mevcut veritabanlarında bu kolonlar yoksa ekler (idempotent)
        existing_cols = {
            row[1] for row in conn.execute("PRAGMA table_info(users)").fetchall()
        }
        migrations = []
        if "totp_secret" not in existing_cols:
            migrations.append("ALTER TABLE users ADD COLUMN totp_secret TEXT DEFAULT NULL")
        if "two_fa_enabled" not in existing_cols:
            migrations.append("ALTER TABLE users ADD COLUMN two_fa_enabled INTEGER NOT NULL DEFAULT 0")

        new_columns = {
            "height": "TEXT DEFAULT NULL",
            "weight": "TEXT DEFAULT NULL",
            "chest": "TEXT DEFAULT NULL",
            "waist": "TEXT DEFAULT NULL",
            "hips": "TEXT DEFAULT NULL",
            "location": "TEXT DEFAULT NULL",
            "timezone": "TEXT DEFAULT NULL"
        }

        for col, col_def in new_columns.items():
            if col not in existing_cols:
                migrations.append(f"ALTER TABLE users ADD COLUMN {col} {col_def}")

        for migration in migrations:
            conn.execute(migration)
        if migrations:
            conn.commit()

    finally:
        conn.close()

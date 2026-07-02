"""Beğeni, kaydetme ve yorum endpoint testleri."""

import hashlib
import sqlite3
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.main import app

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
SCHEMA_PATH = _BACKEND_DIR / "schema.sql"


def _hash(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


def _init_test_db() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
    conn.execute("PRAGMA foreign_keys = ON")

    user_id = "user-test-001"
    post_id = "post-test-001"
    conn.execute(
        """
        INSERT INTO users (user_id, username, email, password_hash, display_name)
        VALUES (?, ?, ?, ?, ?)
        """,
        (user_id, "tester", "tester@gmail.com", _hash("TestPass1!"), "Tester"),
    )
    conn.execute(
        """
        INSERT INTO posts (post_id, user_id, image_url, caption, visibility)
        VALUES (?, ?, ?, ?, ?)
        """,
        (post_id, user_id, "https://example.com/img.jpg", "Test post", "public"),
    )
    conn.commit()
    return conn


@pytest.fixture()
def client():
    conn = _init_test_db()

    def override_get_db():
        try:
            yield conn
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client, conn
    app.dependency_overrides.clear()
    conn.close()


def test_like_unlike_post(client):
    test_client, _ = client
    user_id = "user-test-001"
    post_id = "post-test-001"

    like = test_client.post(f"/posts/{post_id}/like", json={"user_id": user_id})
    assert like.status_code == 200

    unlike = test_client.delete(f"/posts/{post_id}/like?user_id={user_id}")
    assert unlike.status_code == 200


def test_save_unsave_post(client):
    test_client, _ = client
    user_id = "user-test-001"
    post_id = "post-test-001"

    save = test_client.post(f"/posts/{post_id}/save", json={"user_id": user_id})
    assert save.status_code == 200

    saved = test_client.get(f"/posts/users/{user_id}/saved_posts")
    assert saved.status_code == 200
    assert len(saved.json()) == 1

    unsave = test_client.delete(f"/posts/{post_id}/save?user_id={user_id}")
    assert unsave.status_code == 200


def test_add_and_list_comments(client):
    test_client, _ = client
    user_id = "user-test-001"
    post_id = "post-test-001"

    created = test_client.post(
        f"/posts/{post_id}/comments",
        json={"user_id": user_id, "content": "Harika kombin!"},
    )
    assert created.status_code == 200
    assert created.json()["data"]["comment_id"]

    comments = test_client.get(f"/posts/{post_id}/comments")
    assert comments.status_code == 200
    assert len(comments.json()) == 1
    assert comments.json()[0]["content"] == "Harika kombin!"

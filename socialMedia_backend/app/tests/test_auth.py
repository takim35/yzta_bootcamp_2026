"""Kayıt ve giriş endpoint testleri."""

import sqlite3
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.main import app

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
SCHEMA_PATH = _BACKEND_DIR / "schema.sql"


def _init_test_db() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
    conn.execute("PRAGMA foreign_keys = ON")
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
        yield test_client
    app.dependency_overrides.clear()
    conn.close()


def test_register_success(client):
    response = client.post(
        "/auth/register",
        json={"email": "newuser@gmail.com", "password": "TestPass1!"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["user_id"].startswith("user-")
    assert body["message"]


def test_register_duplicate_email_returns_400(client):
    payload = {"email": "dup@gmail.com", "password": "TestPass1!"}
    first = client.post("/auth/register", json=payload)
    second = client.post("/auth/register", json=payload)

    assert first.status_code == 201
    assert second.status_code == 400
    assert "e-posta" in second.json()["detail"].lower()


def test_login_after_register(client):
    payload = {"email": "loginflow@gmail.com", "password": "TestPass1!"}
    register = client.post("/auth/register", json=payload)
    login = client.post("/auth/login", json=payload)

    assert register.status_code == 201
    assert login.status_code == 200
    assert login.json()["user_id"] == register.json()["user_id"]

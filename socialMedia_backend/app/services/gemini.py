"""
AI Caption Servisi — Ollama (llama3.2) kullanarak kombin caption önerisi.
POST /captions/suggest
POST /upload  (resim yükleme)
"""
from __future__ import annotations

import os
import uuid
import httpx
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse
from typing import List

from app.domain.schemas import CaptionRequest, MessageResponse

router = APIRouter()

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL    = os.getenv("OLLAMA_MODEL", "llama3.2")

# Resim kayıt dizini
UPLOADS_DIR = Path(__file__).resolve().parent.parent.parent / "static" / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

SERVER_HOST = os.getenv("SERVER_HOST", "172.20.10.13")
SERVER_PORT = os.getenv("SERVER_PORT", "8000")


def _ollama_caption(outfit_desc: str, style_hint: str = "") -> str:
    """Ollama ile caption üretir."""
    prompt = (
        f"Şu kombin için kısa ve çekici bir sosyal medya caption'ı yaz "
        f"(Türkçe, max 200 karakter, emoji kullan):\n"
        f"Kombin: {outfit_desc}\n"
    )
    if style_hint:
        prompt += f"Stil: {style_hint}\n"
    prompt += "Sadece caption'ı yaz, başka açıklama ekleme."

    try:
        with httpx.Client(timeout=30.0) as client:
            resp = client.post(
                f"{OLLAMA_BASE_URL}/api/generate",
                json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
            )
            resp.raise_for_status()
            return resp.json().get("response", "").strip()[:250]
    except Exception:
        return ""


@router.post("/suggest", response_model=MessageResponse)
async def suggest_caption(req: CaptionRequest):
    """Kombin için AI caption önerisi üretir (Ollama)."""
    try:
        items_desc = ", ".join(
            [f"{item.get('category', 'parça')}: {item.get('name', item.get('tur', 'bilinmiyor'))}"
             for item in req.outfit_items]
        ) if req.outfit_items else "Kombin"

        caption = _ollama_caption(items_desc, req.style_hint or "")

        if not caption:
            caption = f"✨ {items_desc} 🔥 #moda #style #ootd"

        return MessageResponse(
            success=True,
            message="Caption önerisi üretildi",
            data={"caption": caption},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """Resim yükler ve erişilebilir URL döndürür."""
    allowed = {".jpg", ".jpeg", ".png", ".webp", ".heic"}
    ext = Path(file.filename or "img.jpg").suffix.lower()
    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Sadece jpg, png, webp desteklenir.")

    filename = f"{uuid.uuid4()}{ext}"
    dest = UPLOADS_DIR / filename
    content = await file.read()
    dest.write_bytes(content)

    url = f"http://{SERVER_HOST}:{SERVER_PORT}/static/uploads/{filename}"
    return {"url": url, "filename": filename}

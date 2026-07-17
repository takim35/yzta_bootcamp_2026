"""
AI Caption Servisi — Tamamen Yerel, Ollama tabanlı. Harici API yok.
Gemini veya herhangi bir harici API KULLANILMAZ.

Görsel analiz için: llava (vision modeli)
Fallback metin için: llama3.2

POST /captions/suggest  → Görsel + kombin bilgisinden caption üretir
POST /captions/upload   → Resim yükleyip URL döndürür
"""
from __future__ import annotations

import base64
import os
import uuid
import httpx
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File
from typing import Optional

from app.domain.schemas import CaptionRequest, MessageResponse

router = APIRouter()

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_VISION_MODEL = os.getenv("OLLAMA_VISION_MODEL", "llava")    # Görsel anlayan model
OLLAMA_TEXT_MODEL   = os.getenv("OLLAMA_MODEL",        "llama3.2") # Metin modeli

# Resim kayıt dizini
UPLOADS_DIR = Path(__file__).resolve().parent.parent.parent / "static" / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

SERVER_HOST = os.getenv("SERVER_HOST", "localhost")
SERVER_PORT = os.getenv("SERVER_PORT", "8000")


# ─────────────────────────────────────────────────────────
# Yardımcı: Görseli base64'e çevir
# ─────────────────────────────────────────────────────────

def _image_to_base64(image_url: Optional[str]) -> Optional[str]:
    """
    Görsel URL'sini alır:
    - Yerel static/uploads/ dosyasıysa diskten okur
    - Harici URL ise indirir
    None döner başarısız olursa.
    """
    if not image_url:
        return None

    # Yerel dosya
    if "static/uploads/" in image_url:
        filename = image_url.split("static/uploads/")[-1].split("?")[0]
        local_path = UPLOADS_DIR / filename
        if local_path.exists():
            return base64.b64encode(local_path.read_bytes()).decode()
        return None

    # Harici URL → indir
    try:
        with httpx.Client(timeout=10.0) as client:
            resp = client.get(image_url)
            resp.raise_for_status()
            return base64.b64encode(resp.content).decode()
    except Exception as e:
        print(f"[Vision] Görsel indirilemedi ({image_url}): {e}")
        return None


# ─────────────────────────────────────────────────────────
# 1) OLLAMA LLAVA — Görsel anlayan yerel model
# ─────────────────────────────────────────────────────────

def _caption_with_llava(image_b64: Optional[str], outfit_desc: str, style_hint: str = "") -> Optional[str]:
    """
    Ollama llava modeli ile görsel analizi yapar.
    Görsel base64 verisi varsa görseli de analiz eder.
    llava kurulu değilse None döner.
    """
    if not image_b64:
        return None  # Görsel yoksa llava'ya gerek yok, metin fallback'e geç

    prompt = (
        "Bu kıyafet/moda fotoğrafını analiz et ve kısa, çekici bir Türkçe sosyal medya caption'ı yaz. "
        "Maksimum 200 karakter, emoji kullan, hashtag ekle (#moda #ootd #style gibi). "
    )
    if outfit_desc and outfit_desc not in ("Kombin", "diğer: bilinmiyor"):
        prompt += f"Kombinde şunlar var: {outfit_desc}. "
    if style_hint:
        prompt += f"Stil tercihi: {style_hint}. "
    prompt += "Sadece caption'ı yaz, başka açıklama ekleme."

    payload = {
        "model": OLLAMA_VISION_MODEL,
        "prompt": prompt,
        "images": [image_b64],
        "stream": False,
    }

    try:
        with httpx.Client(timeout=60.0) as client:
            resp = client.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload)
            if resp.status_code == 404:
                print(f"[llava] Model '{OLLAMA_VISION_MODEL}' kurulu değil. 'ollama pull llava' çalıştır.")
                return None
            resp.raise_for_status()
            result = resp.json().get("response", "").strip()
            return result[:280] if result else None
    except httpx.ConnectError:
        print("[llava] Ollama bağlantı hatası — ollama serve çalışıyor mu?")
        return None
    except Exception as e:
        print(f"[llava] Hata: {e}")
        return None


# ─────────────────────────────────────────────────────────
# 2) OLLAMA LLAMA3.2 — Metin fallback
# ─────────────────────────────────────────────────────────

def _caption_text_only(outfit_desc: str, style_hint: str = "") -> str:
    """llama3.2 ile sadece metin bilgisine göre caption üretir."""
    prompt = (
        f"Şu kombin için kısa ve çekici bir sosyal medya caption'ı yaz "
        f"(Türkçe, max 200 karakter, emoji kullan, #moda #ootd #style gibi hashtag ekle):\n"
        f"Kombin: {outfit_desc}\n"
    )
    if style_hint:
        prompt += f"Stil: {style_hint}\n"
    prompt += "Sadece caption'ı yaz, başka açıklama ekleme."

    try:
        with httpx.Client(timeout=30.0) as client:
            resp = client.post(
                f"{OLLAMA_BASE_URL}/api/generate",
                json={"model": OLLAMA_TEXT_MODEL, "prompt": prompt, "stream": False},
            )
            resp.raise_for_status()
            return resp.json().get("response", "").strip()[:250]
    except httpx.ConnectError:
        print("[llama3.2] Ollama bağlantı hatası.")
        return ""
    except Exception as e:
        print(f"[llama3.2] Hata: {e}")
        return ""


# ─────────────────────────────────────────────────────────
# ENDPOINT: POST /captions/suggest
# ─────────────────────────────────────────────────────────

@router.post("/suggest", response_model=MessageResponse)
async def suggest_caption(req: CaptionRequest):
    """
    Kombin görseli + bilgilerinden Türkçe AI caption üretir.
    
    Öncelik sırası (hepsi yerel Ollama):
      1. llava (görsel varsa — görseli gerçekten okur)
      2. llama3.2 (görsel yoksa veya llava kurulu değilse)
      3. Statik fallback
    """
    items_desc = ", ".join(
        [f"{item.get('category', 'parça')}: {item.get('name', item.get('tur', 'bilinmiyor'))}"
         for item in req.outfit_items]
    ) if req.outfit_items else "Moda kombini"

    style_hint = req.style_hint or ""
    image_url  = req.image_url  # None olabilir

    caption: Optional[str] = None

    # 1. Görsel varsa llava ile analiz et
    if image_url:
        image_b64 = _image_to_base64(image_url)
        caption = _caption_with_llava(image_b64, items_desc, style_hint)

    # 2. Sadece metin ile dene (llava yoksa veya görsel yoksa)
    if not caption:
        caption = _caption_text_only(items_desc, style_hint)

    # 3. Statik fallback
    if not caption:
        caption = f"✨ Harika bir kombin! 🔥 #moda #style #ootd #fashion"

    return MessageResponse(
        success=True,
        message="Caption önerisi üretildi",
        data={"caption": caption},
    )


# ─────────────────────────────────────────────────────────
# ENDPOINT: POST /captions/upload
# ─────────────────────────────────────────────────────────

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """Resim yükler, erişilebilir URL döndürür."""
    allowed = {".jpg", ".jpeg", ".png", ".webp", ".heic"}
    ext = Path(file.filename or "img.jpg").suffix.lower()
    if ext not in allowed:
        raise HTTPException(status_code=400, detail="Sadece jpg, png, webp, heic desteklenir.")

    filename = f"{uuid.uuid4()}{ext}"
    dest = UPLOADS_DIR / filename
    content = await file.read()
    dest.write_bytes(content)

    url = f"http://{SERVER_HOST}:{SERVER_PORT}/static/uploads/{filename}"
    return {"url": url, "filename": filename}

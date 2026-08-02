from fastapi import APIRouter, Depends, HTTPException
import sqlite3
from pydantic import BaseModel
from typing import Optional, List
import json
from pathlib import Path

from app.core.database import get_db
from app.repositories.item_repository import ItemRepository
from app.services import ollama_client
from app.services.fashion_classifier import classifier as fashion_classifier

router = APIRouter(tags=["Wardrobe"])

# --- Models ---
class ClothCreateRequest(BaseModel):
    tur: str
    renk: str
    renk_hex: Optional[str] = None
    renk_kategori_id: Optional[str] = None
    marka: Optional[str] = None
    beden: Optional[str] = None
    kumas: Optional[str] = None
    kesim: Optional[str] = None
    yaka_tipi: Optional[str] = None
    kol_tipi: Optional[str] = None
    desen: Optional[str] = "düz"
    mevsim: Optional[str] = "tüm sezon"
    stil_etiketi: Optional[str] = None
    kullanim_sikligi: Optional[str] = None
    kombin_notu: Optional[str] = None
    temiz: bool = True
    foto_url: Optional[str] = None
    is_favorite: bool = False


class LaundryStatusRequest(BaseModel):
    is_dirty: bool


class FavoriteStatusRequest(BaseModel):
    is_favorite: bool


# Aliases for backwards compatibility
KiyafetEkleIstek = ClothCreateRequest


class ChatRequest(BaseModel):
    user_id: str
    mesaj: str
    hava_durumu: Optional[str] = None
    session_id: Optional[str] = None
    language: Optional[str] = "tr"

ChatIstek = ChatRequest


class OutfitRecommendRequest(BaseModel):
    user_id: str
    etkinlik: str
    hava_durumu: str
    stil_tercihi: Optional[str] = ""

KombinOnerIstek = OutfitRecommendRequest


class ManualOutfitCreateRequest(BaseModel):
    user_id: str
    item_ids: List[int]
    aciklama: str


class AnalyzeClothRequest(BaseModel):
    gorsel_url: str

AnalyzeKiyafetIstek = AnalyzeClothRequest


# --- Endpoints ---
@router.post("/items")
def add_cloth(user_id: str, request: ClothCreateRequest, db: sqlite3.Connection = Depends(get_db)):
    """Adds a new cloth item to user's wardrobe."""
    repo = ItemRepository(db)
    data = request.model_dump()
    cloth_id = repo.add_cloth(user_id=user_id, **data)
    return {"id": cloth_id, "mesaj": "Clothing item added", "message": "Clothing item added"}


@router.get("/items/{user_id}")
def list_clothes(user_id: str, db: sqlite3.Connection = Depends(get_db)):
    """Lists all clothes for a given user."""
    repo = ItemRepository(db)
    return repo.get_clothes(user_id)


@router.put("/items/{item_id}")
def update_cloth(item_id: int, request: ClothCreateRequest, db: sqlite3.Connection = Depends(get_db)):
    """Updates an existing cloth item."""
    repo = ItemRepository(db)
    data = request.model_dump()
    try:
        updated = repo.update_cloth(item_id=item_id, **data)
        if not updated:
            raise HTTPException(status_code=404, detail="Clothing item not found.")
        return {"mesaj": "Clothing item updated", "message": "Clothing item updated", "id": item_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error updating clothing item: {str(e)}")


@router.patch("/items/{item_id}/laundry")
def set_laundry_status(item_id: int, request: LaundryStatusRequest, db: sqlite3.Connection = Depends(get_db)):
    """Quickly toggle laundry (dirty/clean) status of a clothing item."""
    repo = ItemRepository(db)
    updated = repo.update_cloth(item_id=item_id, temiz=not request.is_dirty)
    if not updated:
        raise HTTPException(status_code=404, detail="Clothing item not found.")
    return {"message": "Laundry status updated", "id": item_id, "is_dirty": request.is_dirty}


@router.patch("/items/{item_id}/favorite")
def set_favorite_status(item_id: int, request: FavoriteStatusRequest, db: sqlite3.Connection = Depends(get_db)):
    """Quickly toggle favorite status of a clothing item."""
    repo = ItemRepository(db)
    updated = repo.update_cloth(item_id=item_id, is_favorite=request.is_favorite)
    if not updated:
        raise HTTPException(status_code=404, detail="Clothing item not found.")
    return {"message": "Favorite status updated", "id": item_id, "is_favorite": request.is_favorite}


@router.delete("/items/{item_id}")
def delete_cloth(item_id: int, db: sqlite3.Connection = Depends(get_db)):
    """Deletes a clothing item."""
    repo = ItemRepository(db)
    try:
        deleted = repo.delete_cloth(item_id=item_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Clothing item not found.")
        return {"mesaj": "Clothing item deleted", "message": "Clothing item deleted", "id": item_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error deleting clothing item: {str(e)}")


@router.post("/chat")
def chat(request: ChatRequest, db: sqlite3.Connection = Depends(get_db)):
    """Handles AI Stylist chat messages."""
    import uuid
    repo = ItemRepository(db)
    
    session_id = request.session_id
    if not session_id:
        session_id = str(uuid.uuid4())
        title = request.mesaj[:30] + "..." if len(request.mesaj) > 30 else request.mesaj
        repo.create_chat_session(request.user_id, session_id, title)

    history = repo.get_chat_history(request.user_id, session_id=session_id)
    
    # --- Detect "show my outfits" intent ---
    msg_lower = request.mesaj.lower().strip()
    show_outfits_keywords = [
        "kombinlerimi göster", "kombinlerim", "kayıtlı kombinlerim",
        "show my outfits", "show my combines", "my outfits", "my combinations",
        "saved outfits", "show combines", "list outfits", "list my outfits",
    ]
    is_show_outfits = any(kw in msg_lower for kw in show_outfits_keywords)
    
    if is_show_outfits:
        # Directly return saved outfits without calling AI
        outfits = repo.get_outfit_recommendations(request.user_id)
        all_outfit_items = []
        outfit_descriptions = []
        for o in outfits:
            clothes_in_outfit = o.get("kiyafetler", [])
            all_outfit_items.extend(clothes_in_outfit)
            desc = o.get("aciklama", "Kombin")
            items_text = ", ".join([f"{c.get('isim', c.get('kategori', 'Kıyafet'))}" for c in clothes_in_outfit])
            outfit_descriptions.append(f"• {desc}: {items_text}")
        
        if outfits:
            if request.language == "en":
                ai_text = f"Here are your saved outfits ({len(outfits)} total):\n" + "\n".join(outfit_descriptions)
            else:
                ai_text = f"İşte kayıtlı kombinlerin ({len(outfits)} adet):\n" + "\n".join(outfit_descriptions)
        else:
            ai_text = "You don't have any saved outfits yet." if request.language == "en" else "Henüz kayıtlı kombinin yok."
        
        result = {
            "asistan_mesaji": ai_text,
            "baglam": {},
            "hazir_mi": True,
            "onerilen_kiyafet_idleri": [c["id"] for c in all_outfit_items],
            "outfit_items": all_outfit_items,
        }
        
        import json
        ai_content = json.dumps({"text": ai_text, "outfit_items": all_outfit_items}, ensure_ascii=False)
        repo.save_chat_message(request.user_id, "user", request.mesaj, session_id=session_id)
        repo.save_chat_message(request.user_id, "assistant", ai_content, session_id=session_id)
        result["session_id"] = session_id
        return result
    
    # --- Normal AI chat flow ---
    context_message = request.mesaj
    if request.hava_durumu:
        context_message = f"[System Note: Current weather at location is '{request.hava_durumu}']\nUser: {request.mesaj}"

    try:
        clean_clothes = repo.get_clothes(request.user_id, clean_only=True)
        outfits = repo.get_outfit_recommendations(request.user_id)
        result = ollama_client.get_chat_response(
            history, 
            context_message, 
            available_clothes=clean_clothes,
            available_outfits=outfits,
            language=request.language
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI service error: {e}")
    
    # --- Detect "recommend outfit" intent for smart fallback ---
    recommend_keywords = [
        "kombin öner", "kombin oluştur", "ne giyeyim", "öneri",
        "recommend", "suggest", "outfit", "what should i wear",
    ]
    is_recommend = any(kw in msg_lower for kw in recommend_keywords)
    
    suggested_items = []
    if result.get("onerilen_kiyafet_idleri"):
        valid_ids = {c["id"] for c in clean_clothes}
        for item_id in result["onerilen_kiyafet_idleri"]:
            if item_id in valid_ids:
                suggested_items.append(next(c for c in clean_clothes if c["id"] == item_id))
    
    # If user asked for a recommendation but AI didn't provide items, use rule-based fallback
    if is_recommend and not suggested_items and clean_clothes:
        rec = ollama_client.generate_outfit_recommendation(
            {"etkinlik": "günlük", "hava_durumu": "normal", "stil_tercihi": "rahat"},
            clean_clothes
        )
        for item_id in rec.get("secilen_kiyafet_idleri", []):
            cloth = next((c for c in clean_clothes if c["id"] == item_id), None)
            if cloth:
                suggested_items.append(cloth)
        if suggested_items:
            items_text = ", ".join([f"{c.get('isim', c.get('kategori', 'Kıyafet'))}" for c in suggested_items])
            if request.language == "en":
                result["asistan_mesaji"] = f"Here's a great outfit combination for you: {items_text} ✨\n{rec.get('aciklama', '')}"
            else:
                result["asistan_mesaji"] = f"İşte sana harika bir kombin önerisi: {items_text} ✨\n{rec.get('aciklama', '')}"
    
    result["outfit_items"] = suggested_items
    
    import json
    ai_content = json.dumps({"text": result.get("asistan_mesaji", ""), "outfit_items": suggested_items}, ensure_ascii=False)
    
    repo.save_chat_message(request.user_id, "user", request.mesaj, session_id=session_id)
    repo.save_chat_message(request.user_id, "assistant", ai_content, session_id=session_id)
    result["session_id"] = session_id
    return result


@router.get("/chat/history/{user_id}")
def chat_history(user_id: str, session_id: Optional[str] = None, db: sqlite3.Connection = Depends(get_db)):
    """Returns chat history for a user."""
    repo = ItemRepository(db)
    return repo.get_chat_history(user_id, session_id=session_id)

@router.get("/chat/sessions/{user_id}")
def chat_sessions(user_id: str, db: sqlite3.Connection = Depends(get_db)):
    """Returns chat sessions for a user."""
    repo = ItemRepository(db)
    return repo.get_chat_sessions(user_id)


@router.post("/outfit/suggest")
def recommend_outfit(request: OutfitRecommendRequest, db: sqlite3.Connection = Depends(get_db)):
    """Generates AI outfit recommendation."""
    repo = ItemRepository(db)
    clean_clothes = repo.get_clothes(request.user_id, clean_only=True)
    
    if not clean_clothes:
        raise HTTPException(status_code=400, detail="No clean clothes available.")
        
    context = {
        "etkinlik": request.etkinlik,
        "hava_durumu": request.hava_durumu,
        "stil_tercihi": request.stil_tercihi or "",
    }
    
    try:
        result = ollama_client.generate_outfit_recommendation(context, clean_clothes)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI service error: {e}")
        
    selected_ids = result.get("secilen_kiyafet_idleri", [])
    valid_ids = {c["id"] for c in clean_clothes}
    selected_ids = [i for i in selected_ids if i in valid_ids]
    
    recommendation_id = repo.save_outfit_recommendation(
        user_id=request.user_id,
        context_json=json.dumps(context, ensure_ascii=False),
        item_ids=selected_ids,
        description=result.get("aciklama", ""),
    )
    
    selected_clothes_detail = [c for c in clean_clothes if c["id"] in selected_ids]
    
    return {
        "id": recommendation_id,
        "aciklama": result.get("aciklama", ""),
        "description": result.get("aciklama", ""),
        "secilen_kiyafetler": selected_clothes_detail,
        "selected_items": selected_clothes_detail,
    }


@router.get("/outfits/{user_id}")
def list_outfits(user_id: str, db: sqlite3.Connection = Depends(get_db)):
    """Lists saved outfit recommendations."""
    repo = ItemRepository(db)
    return repo.get_outfit_recommendations(user_id)


@router.post("/outfit/manual")
def create_manual_outfit(request: ManualOutfitCreateRequest, db: sqlite3.Connection = Depends(get_db)):
    """Creates a user-defined manual outfit."""
    repo = ItemRepository(db)
    context = {"etkinlik": "Manuel Kombin", "hava_durumu": "Belirtilmedi"}
    outfit_id = repo.save_outfit_recommendation(
        user_id=request.user_id,
        context_json=json.dumps(context, ensure_ascii=False),
        item_ids=request.item_ids,
        description=request.aciklama
    )
    return {"id": outfit_id, "mesaj": "Outfit created", "message": "Outfit created"}


@router.post("/analyze-image")
def analyze_cloth_image(request: AnalyzeClothRequest):
    """
    Kıyafet görselini AI ile analiz eder.
    FashionSigLIP → 6 özellik (tür, renk, desen, malzeme, mevsim, kullanım)
    + Moondream → zengin kıyafet açıklaması (kombin_notu için kullanılabilir)
    Tüm yanıtlar Türkçe düz metin — kullanıcı JSON görmez.
    """
    import base64 as _b64
    import httpx as _httpx

    image_url = request.gorsel_url
    if not image_url:
        raise HTTPException(status_code=400, detail="gorsel_url is required.")

    # Görseli base64'e çevir
    image_b64: Optional[str] = None
    try:
        if image_url.startswith("http://") or image_url.startswith("https://"):
            filename = image_url.split("/")[-1]
            for candidate in [
                Path("static/uploads") / filename,
                Path("uploads") / filename,
            ]:
                if candidate.exists():
                    image_b64 = _b64.b64encode(candidate.read_bytes()).decode()
                    break
            if not image_b64:
                with _httpx.Client(timeout=15.0) as c:
                    r = c.get(image_url)
                    r.raise_for_status()
                image_b64 = _b64.b64encode(r.content).decode()
        else:
            p = Path(image_url)
            if p.exists():
                image_b64 = _b64.b64encode(p.read_bytes()).decode()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Görsel alınamadı: {e}")

    if not image_b64:
        raise HTTPException(status_code=400, detail="Görsel yüklenemedi.")

    # FashionSigLIP — 6 özellik
    attrs = fashion_classifier.classify_all_attributes(image_b64=image_b64)

    if not attrs.get("success"):
        # Fallback: eski 4-özellik metodu
        attrs = fashion_classifier.classify_image(image_b64=image_b64)
        if not attrs.get("success"):
            raise HTTPException(
                status_code=503,
                detail=f"AI model hatası: {attrs.get('error', 'Bilinmeyen hata')}"
            )
        return {
            "tur":          attrs.get("tur", ""),
            "renk":         attrs.get("renk", ""),
            "desen":        "düz",
            "malzeme":      attrs.get("kumas", ""),
            "mevsim":       attrs.get("mevsim", "tüm sezon"),
            "kullanim":     attrs.get("stil_etiketi", "günlük kullanım"),
            "stil_etiketi": attrs.get("stil_etiketi", ""),
            "post_category": attrs.get("post_category", ""),
            "guven_skoru":  attrs.get("confidence", 0.0),
        }

    def _best(attr: str, fallback: str = "") -> str:
        v = attrs.get(attr)
        if isinstance(v, dict):
            return v.get("best", fallback)
        return str(v) if v else fallback

    return {
        # Gardrop formu için doğrudan kullanılabilir alanlar (düz Türkçe)
        "tur":          _best("category", "bilinmiyor"),
        "renk":         _best("color", "bilinmiyor"),
        "desen":        _best("pattern", "düz"),
        "malzeme":      _best("material", "bilinmiyor"),
        "mevsim":       _best("season", "tüm sezon"),
        "kullanim":     _best("occasion", "günlük kullanım"),
        "stil_etiketi": _best("occasion", "gündelik"),
        "post_category": attrs.get("post_category", ""),
        "guven_skoru":  round(
            attrs.get("category", {}).get("confidence", 0.0)
            if isinstance(attrs.get("category"), dict) else 0.0,
            2
        ),
        # Alternatifler (Flutter'da dropdown için)
        "alternatif_turler": [
            t["label"] for t in (
                attrs.get("category", {}).get("top_3", [])
                if isinstance(attrs.get("category"), dict) else []
            )
        ],
        "alternatif_renkler": [
            t["label"] for t in (
                attrs.get("color", {}).get("top_3", [])
                if isinstance(attrs.get("color"), dict) else []
            )
        ],
    }



@router.delete("/outfits/{outfit_id}")
def delete_outfit(outfit_id: int, db: sqlite3.Connection = Depends(get_db)):
    """Deletes an outfit recommendation."""
    repo = ItemRepository(db)
    try:
        deleted = repo.delete_outfit(outfit_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Outfit not found.")
        return {"mesaj": "Outfit deleted", "message": "Outfit deleted", "id": outfit_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error deleting outfit: {str(e)}")


# Backwards compatibility function aliases
kiyafet_ekle = add_cloth
kiyafetleri_listele = list_clothes
kiyafet_guncelle = update_cloth
kiyafet_sil = delete_cloth
kombin_oner = recommend_outfit
outfits_listele = list_outfits
manuel_kombin_olustur = create_manual_outfit
kiyafet_gorseli_analiz_et = analyze_cloth_image
kombin_sil = delete_outfit

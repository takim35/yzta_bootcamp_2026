import asyncio
from app.services.ollama_client import generate_outfit_recommendation

context = {"etkinlik": "iş", "hava_durumu": "güneşli", "stil_tercihi": "şık"}
clothes = [
    {"id": 1, "tur": "Gömlek", "renk": "Beyaz", "kategori": "Üst Giyim"},
    {"id": 2, "tur": "Pantolon", "renk": "Siyah", "kategori": "Alt Giyim"}
]

try:
    res = generate_outfit_recommendation(context, clothes)
    print("Result:", res)
except Exception as e:
    print("Error:", e)

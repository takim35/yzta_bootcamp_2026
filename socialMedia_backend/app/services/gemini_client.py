"""
gemini_client.py
----------------
Google Gemini API ile konuşan tek nokta.

İki ana fonksiyon var:
1. sohbet_yaniti_al()       -> Chatbot mesajına yanıt üretir + bağlam JSON'u çıkarır
2. kombin_onerisi_uret()    -> Bağlam + temiz kıyafet listesine göre kombin önerir

Gemini'nin "structured output" özelliğini kullanıyoruz: modele bir JSON
şeması veriyoruz, o da garanti olarak o şemaya uyan JSON döndürüyor.
Bu sayede regex/parse hatalarıyla uğraşmıyoruz.
"""

import os
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if not API_KEY or API_KEY == "BURAYA_KENDI_ANAHTARINI_YAPISTIR":
    raise RuntimeError(
        "GEMINI_API_KEY tanımlı değil. .env dosyasını oluşturup "
        "kendi API anahtarını yapıştırman gerekiyor (.env.example dosyasına bak)."
    )

client = genai.Client(api_key=API_KEY)


# ---------- 1) Chatbot ----------

CHATBOT_SISTEM_PROMPTU = """
Sen "Akıllı Dolap" uygulamasının moda asistanısın. Görevin, kullanıcıyla
kısa ve doğal bir sohbet ederek şu bilgileri öğrenmek:
- Nereye gidiyor / ne yapacak (etkinlik: iş, randevu, spor, gezi, parti vb.)
- Hava durumu (kullanıcı söylemediyse nazikçe sor)
- Varsa stil tercihi (rahat, şık, spor vb.)

Kurallar:
- Sıcak, samimi ve kısa cümlelerle konuş. Bunaltma, tek seferde tek soru sor.
- Yeterli bilgi toplayana kadar (en az etkinlik ve hava durumu) sohbete devam et.
- Yeterli bilgi toplandığında kullanıcıya "harika, hazırlanıyorum" gibi bir
  şeyle sohbeti kapat ve hazir_mi alanını true yap.
"""

# Gemini'den hep bu şemaya uyan JSON isteyeceğiz.
SOHBET_CIKIS_SEMASI = {
    "type": "object",
    "properties": {
        "asistan_mesaji": {
            "type": "string",
            "description": "Kullanıcıya gösterilecek doğal dildeki yanıt",
        },
        "baglam": {
            "type": "object",
            "properties": {
                "etkinlik": {"type": "string"},
                "hava_durumu": {"type": "string"},
                "stil_tercihi": {"type": "string"},
            },
        },
        "hazir_mi": {
            "type": "boolean",
            "description": "Kombin önerisi üretmek için yeterli bilgi toplandıysa true",
        },
    },
    "required": ["asistan_mesaji", "baglam", "hazir_mi"],
}


def sohbet_yaniti_al(gecmis: list[dict], yeni_mesaj: str) -> dict:
    """
    gecmis: [{"rol": "user"/"assistant", "mesaj": "..."}], veritabanından gelir
    yeni_mesaj: kullanıcının az önce yazdığı mesaj

    Dönen değer örneği:
    {
        "asistan_mesaji": "Harika, peki hava nasıl orada?",
        "baglam": {"etkinlik": "iş görüşmesi", "hava_durumu": "", "stil_tercihi": "şık"},
        "hazir_mi": false
    }
    """
    # Geçmiş mesajları Gemini'nin beklediği "contents" formatına çeviriyoruz
    contents = []
    for mesaj in gecmis:
        rol = "user" if mesaj["rol"] == "user" else "model"
        contents.append(
            types.Content(role=rol, parts=[types.Part(text=mesaj["mesaj"])])
        )
    contents.append(types.Content(role="user", parts=[types.Part(text=yeni_mesaj)]))

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=CHATBOT_SISTEM_PROMPTU,
            response_mime_type="application/json",
            response_schema=SOHBET_CIKIS_SEMASI,
            temperature=0.7,
        ),
    )

    return json.loads(response.text)


# ---------- 2) Kombin Önerisi ----------

KOMBIN_SISTEM_PROMPTU = """
Sen bir moda stilistisin. Sana bir bağlam (etkinlik, hava durumu, stil
tercihi) ve kullanıcının dolabındaki TEMİZ kıyafetlerin listesi verilecek.

Görevin: Bu kıyafetler arasından, verilen bağlama en uygun KOMBİNİ seçmek.
Sadece sana verilen kıyafet ID'lerini kullan, var olmayan kıyafet icat etme.
Üst+alt+ayakkabı (varsa) içeren mantıklı bir kombin oluştur.
"""

KOMBIN_CIKIS_SEMASI = {
    "type": "object",
    "properties": {
        "secilen_kiyafet_idleri": {
            "type": "array",
            "items": {"type": "integer"},
            "description": "Önerilen kombini oluşturan kıyafetlerin ID'leri",
        },
        "aciklama": {
            "type": "string",
            "description": "Kombinin neden uygun olduğuna dair kısa, kullanıcıya gösterilecek açıklama",
        },
    },
    "required": ["secilen_kiyafet_idleri", "aciklama"],
}


def kombin_onerisi_uret(baglam: dict, temiz_kiyafetler: list[dict]) -> dict:
    """
    baglam: {"etkinlik": "...", "hava_durumu": "...", "stil_tercihi": "..."}
    temiz_kiyafetler: database.temiz_kiyafetleri_getir() çıktısı

    Dönen değer örneği:
    {
        "secilen_kiyafet_idleri": [4, 7, 12],
        "aciklama": "Hava ılık ve görüşme şık bir görünüm gerektirdiği için..."
    }
    """
    kiyafet_listesi_metni = json.dumps(temiz_kiyafetler, ensure_ascii=False, indent=2)

    kullanici_mesaji = f"""
BAĞLAM:
{json.dumps(baglam, ensure_ascii=False, indent=2)}

KULLANICININ TEMİZ KIYAFETLERİ:
{kiyafet_listesi_metni}

Lütfen bu bağlama en uygun kombini, yalnızca yukarıdaki kıyafet ID'lerini
kullanarak öner.
"""

    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=kullanici_mesaji,
        config=types.GenerateContentConfig(
            system_instruction=KOMBIN_SISTEM_PROMPTU,
            response_mime_type="application/json",
            response_schema=KOMBIN_CIKIS_SEMASI,
            temperature=0.8,
        ),
    )

    return json.loads(response.text)
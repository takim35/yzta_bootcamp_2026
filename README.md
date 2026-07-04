# Dijital Gardırop - Sosyal Medya Modülü 👗📱

Bu proje, YZTA Bootcamp 2026 kapsamında geliştirilen **"Dijital Gardırop ve Sanal Deneme Kabini"** (Virtual Try On) uygulamasının sosyal medya ve arka uç modülüdür. Kullanıcılar dijital gardıroplarına kıyafet ekleyebilir, bu kıyafetlerle kombinler oluşturabilir ve bunları diğer kullanıcılarla paylaşarak etkileşime geçebilirler.

## 🚀 Teknolojiler ve Mimari

*   **Ön Yüz (Frontend):** Flutter & Dart (Cross-platform Mobil Uygulama)
*   **Arka Uç (Backend):** Python, FastAPI, SQLite (Hafif ve Hızlı API)
*   **Mimari:** Proje, **Clean Code** ve **SOLID (SRP)** prensiplerine tam uyumlu olacak şekilde geliştirilmiştir. Arka uçta veri erişimi *Repository Pattern* kullanılarak ayrıştırılmıştır.
*   **Ağ (Networking):** `http` kütüphanesi üzerinden REST API haberleşmesi.
*   **Durum Yönetimi (State Management):** Riverpod

## 📦 Kurulum ve Çalıştırma Rehberi (Geliştiriciler İçin)

Projeyi bilgisayarınıza klonladıktan sonra, hem arka ucu (Backend) hem de ön yüzü (Frontend) çalıştırmanız gerekmektedir. Lütfen aşağıdaki adımları sırasıyla izleyin.

### 1. Arka Uç (FastAPI) Kurulumu

Arka uç sunucusu Python ile yazılmıştır ve `socialMedia_backend` klasöründe yer alır.

```bash
# Backend klasörüne gidin
cd socialMedia_backend

# (İsteğe bağlı ancak önerilir) Sanal ortam oluşturun ve aktif edin
python -m venv venv
# Windows için:
venv\Scripts\activate
# Mac/Linux için:
source venv/bin/activate

# Gerekli kütüphaneleri yükleyin
pip install -r requirements.txt

# Sunucuyu başlatın
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
*Sunucu başarıyla başladığında `http://localhost:8000` adresinden yayın yapacaktır.*

### 2. Ön Yüz (Flutter) Kurulumu

Mobil uygulama `socialMedia_frontend` klasöründedir. Bilgisayarınızda [Flutter SDK](https://docs.flutter.dev/get-started/install)'nın kurulu olduğundan emin olun.

```bash
# Frontend klasörüne gidin
cd socialMedia_frontend

# Bağımlılıkları indirin
flutter pub get

# Uygulamayı bağlı bir cihaza veya emülatöre kurup başlatın
flutter run
```

### ⚠️ ÖNEMLİ: Fiziksel Telefonla Test Edenler İçin Ağ (Bağlantı) Ayarı

Frontend kodumuzda güvenlik ve istikrar (WiFi veya Firewall sorunlarını aşmak) amacıyla, arka uca bağlanmak için statik bir IP adresi (örneğin 192.168.1.107) kullanmak yerine **doğrudan USB kablosu üzerinden Güvenli Tünel (localhost)** kullanıyoruz (`api_service.dart` içerisinde baseUrl `127.0.0.1:8000` olarak ayarlıdır).

Eğer uygulamayı **fiziksel bir Android telefon** bağlayarak test ediyorsanız, sunucuya bağlanabilmesi için Terminal'e (Command Prompt/Powershell) şu kodu yazarak USB üzerinden port yönlendirmesini açmalısınız:

```bash
adb reverse tcp:8000 tcp:8000
```
*(Bu komut, telefondaki 8000 portunu bilgisayarınızın 8000 portuna bağlar. Bilgisayarı her yeniden başlattığınızda veya kabloyu çıkarıp taktığınızda bu komutu bir kez tekrar girmeniz gerekir.)*

Eğer **Android Studio Emülatörü** (Sanal Cihaz) kullanıyorsanız, `api_service.dart` içerisindeki `baseUrl` değerini `http://10.0.2.2:8000` olarak değiştirmeniz yeterlidir.

## 📂 Proje Özellikleri
- **Kullanıcı Doğrulama (Auth):** Kayıt Ol, Giriş Yap, Şifremi Unuttum.
- **Akış (Feed):** Kullanıcıların paylaştığı gönderileri görme, beğenme.
- **Profil:** Kullanıcı bilgilerini düzenleme, Avatar yükleme, gönderileri listeleme, hesap gizliliği yönetimi ve KVKK uyumlu veri silme işlemleri.
- **Güvenlik:** Şifreler veritabanında SHA-256 ile şifrelenerek (hash) saklanır.

---
*Geliştirme süreci boyunca karşılaştığınız hataları veya çakışmaları (conflict) Github Issues veya doğrudan ekip içi kanallardan bildirebilirsiniz. İyi kodlamalar!* ☕
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

/// Google Sign-In servisi
///
/// Gereksinimler (iOS):
///   1. Firebase Console → Authentication → Sign-in method → Google → Etkinleştir
///   2. Güncel GoogleService-Info.plist indir (CLIENT_ID + REVERSED_CLIENT_ID içermeli)
///   3. ios/Runner/Info.plist → CFBundleURLSchemes → REVERSED_CLIENT_ID değerini yaz
///
/// Mevcut durum: REVERSED_CLIENT_ID henüz eklenmedi → ID token alınamaz,
/// ancak email + displayName ile backend'e kayıt yapılabilir.
class GoogleAuthService {
  GoogleAuthService._internal();
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;

  // CLIENT_ID — GoogleService-Info.plist'ten
  static const _clientId =
      '777699158570-dpl8ajp9lt2qkg7p29bbldmokr3qp1l9.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: ['email', 'profile'],
  );

  /// Google ile giriş yapar ve user_id döner.
  /// null döner: kullanıcı dialogu kapattı.
  /// Exception fırlatır: gerçek hata.
  Future<String?> signIn() async {
    try {
      // Önceki oturumu kapat (hesap seçim dialogu için)
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[GoogleAuth] Kullanıcı dialogu kapattı.');
        return null;
      }

      debugPrint('[GoogleAuth] Giriş yapıldı: ${googleUser.email}');

      // ID token almayı dene (CLIENT_ID yoksa null gelebilir)
      String? idToken;
      try {
        final googleAuth = await googleUser.authentication;
        idToken = googleAuth.idToken;
        if (idToken == null) {
          debugPrint(
              '[GoogleAuth] ID token alınamadı — REVERSED_CLIENT_ID eksik olabilir.');
          debugPrint('[GoogleAuth] Email + displayName ile devam ediliyor...');
        }
      } catch (e) {
        debugPrint('[GoogleAuth] Authentication hatası: $e');
      }

      // Backend'e gönder (id_token olmasa da email + displayName ile çalışır)
      final userId = await ApiService().loginWithGoogle(
        idToken: idToken ?? 'NO_TOKEN_${DateTime.now().millisecondsSinceEpoch}',
        email: googleUser.email,
        displayName:
            googleUser.displayName ?? googleUser.email.split('@').first,
        avatarUrl: googleUser.photoUrl,
      );

      debugPrint('[GoogleAuth] user_id alındı: $userId');
      return userId;
    } on Exception catch (e) {
      debugPrint('[GoogleAuth] Hata: $e');
      rethrow;
    }
  }

  /// Google oturumunu kapat
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Mevcut Google oturumu var mı?
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = ChangeNotifierProvider((ref) => AuthProvider());

class AuthProvider extends ChangeNotifier {
  // Basit bir mock veritabanı simülasyonu
  final Map<String, String> _registeredUsers = {
    'test@gmail.com': 'Test1234!', // Örnek varsayılan kullanıcı
  };

  bool login(String email, String password) {
    if (_registeredUsers.containsKey(email)) {
      if (_registeredUsers[email] == password) {
        return true; // Giriş başarılı
      }
    }
    return false; // Hatalı giriş veya hesap yok
  }

  bool register(String email, String password) {
    if (_registeredUsers.containsKey(email)) {
      return false; // Zaten böyle bir kullanıcı var
    }
    _registeredUsers[email] = password;
    notifyListeners();
    return true; // Kayıt başarılı
  }

  bool isUserExists(String email) {
    return _registeredUsers.containsKey(email);
  }
}

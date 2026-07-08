import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

final authProvider = ChangeNotifierProvider((ref) => AuthProvider());

const _kUserIdKey = 'saved_user_id';

class AuthProvider extends ChangeNotifier {
  String? _currentUserId;
  bool _isLoading = false;
  bool _isInitializing = true;

  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _currentUserId != null && _currentUserId!.isNotEmpty;

  AuthProvider() {
    _loadSavedSession();
  }

  /// Uygulama açıldığında kayıtlı oturumu yükle
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kUserIdKey);
      if (savedId != null && savedId.isNotEmpty) {
        _currentUserId = savedId;
      }
    } catch (e) {
      debugPrint('Session yükleme hatası: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserIdKey, userId);
    } catch (e) {
      debugPrint('Session kaydetme hatası: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserIdKey);
    } catch (e) {
      debugPrint('Session silme hatası: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await ApiService().login(email, password);
      // If 2FA is required, don't save session yet. Let UI handle it.
      if (result['requires_2fa'] == false) {
        _currentUserId = result['user_id'];
        await _saveSession(result['user_id']);
        notifyListeners();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finalizeLogin(String userId) async {
    _currentUserId = userId;
    await _saveSession(userId);
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    _setLoading(true);
    try {
      final result = await ApiService().register(email, password);
      // Do not auto-login, wait for email verification
      return result;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUserId = null;
    await _clearSession();
    notifyListeners();
  }
}

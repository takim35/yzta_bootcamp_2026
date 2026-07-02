import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';

final authProvider = ChangeNotifierProvider((ref) => AuthProvider());

class AuthProvider extends ChangeNotifier {
  String? _currentUserId;
  bool _isLoading = false;

  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final userId = await ApiService().login(email, password);
      _currentUserId = userId;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      final userId = await ApiService().register(email, password);
      _currentUserId = userId;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }
}

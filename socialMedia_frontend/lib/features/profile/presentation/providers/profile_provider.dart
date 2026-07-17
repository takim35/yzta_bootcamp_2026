import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../features/profile/domain/models/user_model.dart';
import '../../../../services/api_service.dart';

final profileProvider = ChangeNotifierProvider((ref) => ProfileProvider());

class ProfileProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  UserModel? get user => _user;

  List<PostModel> _userPosts = [];
  List<PostModel> get userPosts => _userPosts;

  List<PostModel> _savedPosts = [];
  List<PostModel> get savedPosts => _savedPosts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String? _currentProfileId;
  String? _viewerId;

  bool get isOwnProfile =>
      _currentProfileId != null && _currentProfileId == _viewerId;

  int get postCount => _userPosts.length;

  // ─── Profil Yükleme ────────────────────────────────────────
  Future<void> loadProfile(String userId, String viewerId) async {
    _currentProfileId = userId;
    _viewerId = viewerId;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final futures = <Future>[
        _api.getUser(userId),
        _api.getUserPosts(userId: userId, viewerId: viewerId),
      ];
      if (userId == viewerId) {
        futures.add(_api.getSavedPosts(userId: userId));
      }

      final results = await Future.wait(futures);
      _user = results[0] as UserModel;
      _userPosts = results[1] as List<PostModel>;
      if (userId == viewerId && results.length > 2) {
        _savedPosts = results[2] as List<PostModel>;
      } else {
        _savedPosts = [];
      }
      _isLoading = false;
    } on ApiException catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.message;
      debugPrint('Profil yükleme hatası: ${e.message}');
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Beklenmeyen bir hata oluştu.';
      debugPrint('Profil yükleme hatası: $e');
    }
    notifyListeners();
  }

  // ─── Takip Et/Bırak Toggle ─────────────────────────────────
  Future<void> toggleFollow() async {
    if (_user == null || _viewerId == null) return;

    final wasFollowing = _user!.isFollowing;

    // Optimistic update
    _user = _user!.copyWith(
      isFollowing: !wasFollowing,
      followersCount: wasFollowing
          ? _user!.followersCount - 1
          : _user!.followersCount + 1,
    );
    notifyListeners();

    try {
      if (wasFollowing) {
        await _api.unfollow(
          followerId: _viewerId!,
          followingId: _user!.userId,
        );
      } else {
        await _api.follow(
          followerId: _viewerId!,
          followingId: _user!.userId,
        );
      }
    } catch (e) {
      // Revert on failure
      _user = _user!.copyWith(
        isFollowing: wasFollowing,
        followersCount: wasFollowing
            ? _user!.followersCount + 1
            : _user!.followersCount - 1,
      );
      notifyListeners();
      debugPrint('Takip hatası: $e');
    }
  }

  // ─── Gönderi Sil ────────────────────────────────────────────
  Future<void> deletePost(String postId, String userId) async {
    await _api.deletePost(postId: postId, userId: userId);
    // Yerel listeden hemen kaldır (UI anında güncellenir)
    _userPosts.removeWhere((p) => p.id == postId);
    _savedPosts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  // ─── Temizle ────────────────────────────────────────────────
  void clear() {
    _user = null;
    _userPosts = [];
    _savedPosts = [];
    _currentProfileId = null;
    _viewerId = null;
    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }
}

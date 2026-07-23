import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final searchProvider = ChangeNotifierProvider((ref) {
  return SearchProvider(ref);
});

class SearchProvider extends ChangeNotifier {
  final Ref _ref;
  final ApiService _apiService = ApiService();

  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  SearchProvider(this._ref);

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final currentUserId = _ref.read(authProvider).currentUserId;
      final results =
          await _apiService.searchUsers(query, viewerId: currentUserId);
      _searchResults = results
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> toggleFollow(
      String targetUserId, bool isCurrentlyFollowing) async {
    final currentUserId = _ref.read(authProvider).currentUserId;
    if (currentUserId == null) return;

    // Optimistic update
    final index = _searchResults.indexWhere((u) => u.userId == targetUserId);
    if (index != -1) {
      final user = _searchResults[index];
      _searchResults[index] = user.copyWith(
        isFollowing: !isCurrentlyFollowing,
        followersCount: user.followersCount + (isCurrentlyFollowing ? -1 : 1),
      );
      notifyListeners();
    }

    try {
      if (isCurrentlyFollowing) {
        await _apiService.unfollow(
            followerId: currentUserId, followingId: targetUserId);
      } else {
        await _apiService.follow(
            followerId: currentUserId, followingId: targetUserId);
      }
    } catch (e) {
      // Revert optimistic update
      if (index != -1) {
        final user = _searchResults[index];
        _searchResults[index] = user.copyWith(
          isFollowing: isCurrentlyFollowing,
          followersCount: user.followersCount + (isCurrentlyFollowing ? 1 : -1),
        );
        notifyListeners();
      }
    }
  }
}

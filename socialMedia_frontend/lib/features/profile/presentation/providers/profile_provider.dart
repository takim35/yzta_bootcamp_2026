import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../features/profile/domain/models/user_model.dart';
import '../../../../services/api_service.dart';
import '../../../../core/events/post_events.dart';
import 'dart:async';

final profileProvider = ChangeNotifierProvider.family.autoDispose<ProfileProvider, String>((ref, userId) => ProfileProvider());

class ProfileProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  StreamSubscription? _postEventSub;

  ProfileProvider() {
    _postEventSub = PostEventBus().stream.listen(_onPostEvent);
  }

  void _onPostEvent(PostUpdateEvent event) {
    bool updated = false;

    // Update in userPosts
    final index1 = _userPosts.indexWhere((p) => p.postId == event.postId);
    if (index1 != -1) {
      _userPosts[index1] = _userPosts[index1].copyWith(
        isLiked: event.isLiked ?? _userPosts[index1].isLiked,
        likesCount: event.likesCount ?? _userPosts[index1].likesCount,
        isSaved: event.isSaved ?? _userPosts[index1].isSaved,
        commentsCount: event.commentsCount ?? _userPosts[index1].commentsCount,
      );
      updated = true;
    }

    // Update in savedPosts
    final index2 = _savedPosts.indexWhere((p) => p.postId == event.postId);
    if (index2 != -1) {
      _savedPosts[index2] = _savedPosts[index2].copyWith(
        isLiked: event.isLiked ?? _savedPosts[index2].isLiked,
        likesCount: event.likesCount ?? _savedPosts[index2].likesCount,
        isSaved: event.isSaved ?? _savedPosts[index2].isSaved,
        commentsCount: event.commentsCount ?? _savedPosts[index2].commentsCount,
      );
      
      // If it was unsaved, maybe remove it from savedPosts? 
      // It's safer to remove it from saved posts if we are in own profile
      if (event.isSaved == false && isOwnProfile) {
        _savedPosts.removeAt(index2);
      }
      updated = true;
    }

    if (updated) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _postEventSub?.cancel();
    super.dispose();
  }

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
    _userPosts.removeWhere((p) => p.postId == postId);
    _savedPosts.removeWhere((p) => p.postId == postId);
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

  // Like Toggle
  Future<void> toggleLike(String postId, String userId) async {
    // Find post
    PostModel? post;
    int index1 = _userPosts.indexWhere((p) => p.postId == postId);
    int index2 = _savedPosts.indexWhere((p) => p.postId == postId);

    if (index1 != -1) post = _userPosts[index1];
    else if (index2 != -1) post = _savedPosts[index2];

    if (post == null) return;

    final wasLiked = post.isLiked;
    final newLikesCount = wasLiked ? post.likesCount - 1 : post.likesCount + 1;

    // We don't need to manually update local lists here because we broadcast an event
    // and the event listener will update the local lists.
    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      isLiked: !wasLiked,
      likesCount: newLikesCount,
    ));

    try {
      if (wasLiked) {
        await _api.unlikePost(postId: postId, userId: userId);
      } else {
        await _api.likePost(postId: postId, userId: userId);
      }
    } catch (e) {
      debugPrint('Beğeni hatası (Profil): $e');
    }
  }

  // Save Toggle
  Future<void> toggleSave(String postId, String userId) async {
    PostModel? post;
    int index1 = _userPosts.indexWhere((p) => p.postId == postId);
    int index2 = _savedPosts.indexWhere((p) => p.postId == postId);

    if (index1 != -1) post = _userPosts[index1];
    else if (index2 != -1) post = _savedPosts[index2];

    if (post == null) return;

    final wasSaved = post.isSaved;

    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      isSaved: !wasSaved,
    ));

    try {
      if (wasSaved) {
        await _api.unsavePost(postId: postId, userId: userId);
      } else {
        await _api.savePost(postId: postId, userId: userId);
      }
    } catch (e) {
      debugPrint('Kaydetme hatası (Profil): $e');
    }
  }

  void updateCommentsCount(String postId, int count) {
    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      commentsCount: count,
    ));
  }
}

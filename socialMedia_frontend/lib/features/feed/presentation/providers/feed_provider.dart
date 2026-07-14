import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../services/api_service.dart';
import '../../../../core/events/post_events.dart';
import 'dart:async';

import '../../../../features/auth/presentation/providers/auth_provider.dart';

final feedProvider = ChangeNotifierProvider((ref) {
  final currentUserId = ref.watch(authProvider).currentUserId ?? '';
  return FeedProvider(currentUserId: currentUserId);
});

class FeedProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final String currentUserId;
  late final StreamSubscription _postEventSub;

  FeedProvider({required this.currentUserId}) {
    _postEventSub = PostEventBus().stream.listen(_onPostEvent);
  }

  void _onPostEvent(PostUpdateEvent event) {
    final index = _posts.indexWhere((p) => p.postId == event.postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        isLiked: event.isLiked ?? _posts[index].isLiked,
        likesCount: event.likesCount ?? _posts[index].likesCount,
        isSaved: event.isSaved ?? _posts[index].isSaved,
        commentsCount: event.commentsCount ?? _posts[index].commentsCount,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _postEventSub.cancel();
    super.dispose();
  }

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _cursor;

  // ─── İlk Yükleme ───────────────────────────────────────────
  Future<void> loadFeed() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _api.getFeed(
        userId: currentUserId,
        limit: 20,
      );
      _posts = result.posts;
      _cursor = result.nextCursor;
      _hasMore = result.nextCursor != null;
      _isLoading = false;
    } on ApiException catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.message;
      debugPrint('Feed yükleme hatası: ${e.message}');
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Beklenmeyen bir hata oluştu.';
      debugPrint('Feed yükleme hatası: $e');
    }
    notifyListeners();
  }

  // ─── Daha Fazla Yükle (Infinite Scroll) ─────────────────────
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _cursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _api.getFeed(
        userId: currentUserId,
        cursor: _cursor,
        limit: 20,
      );
      _posts.addAll(result.posts);
      _cursor = result.nextCursor;
      _hasMore = result.nextCursor != null;
    } on ApiException catch (e) {
      debugPrint('Daha fazla yükleme hatası: ${e.message}');
    } catch (e) {
      debugPrint('Daha fazla yükleme hatası: $e');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // ─── Yenile (Pull-to-Refresh) ──────────────────────────────
  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    await loadFeed();
  }

  // ─── Beğeni Toggle ─────────────────────────────────────────
  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    // Optimistic update
    final newLikesCount = wasLiked ? post.likesCount - 1 : post.likesCount + 1;
    _posts[index] = post.copyWith(
      isLiked: !wasLiked,
      likesCount: newLikesCount,
    );
    notifyListeners();

    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      isLiked: !wasLiked,
      likesCount: newLikesCount,
    ));

    try {
      if (wasLiked) {
        await _api.unlikePost(postId: postId, userId: currentUserId);
      } else {
        await _api.likePost(postId: postId, userId: currentUserId);
      }
    } catch (e) {
      // Revert on failure
      _posts[index] = post;
      notifyListeners();
      debugPrint('Beğeni hatası: $e');
    }
  }

  // ─── Kaydetme Toggle ───────────────────────────────────────
  Future<void> toggleSave(String postId) async {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasSaved = post.isSaved;

    // Optimistic update
    _posts[index] = post.copyWith(isSaved: !wasSaved);
    notifyListeners();

    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      isSaved: !wasSaved,
    ));

    try {
      if (wasSaved) {
        await _api.unsavePost(postId: postId, userId: currentUserId);
      } else {
        await _api.savePost(postId: postId, userId: currentUserId);
      }
    } catch (e) {
      // Revert on failure
      _posts[index] = post;
      notifyListeners();
      debugPrint('Kaydetme hatası: $e');
    }
  }

  void updateCommentsCount(String postId, int count) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    _posts[index] = _posts[index].copyWith(commentsCount: count);
    notifyListeners();

    PostEventBus().broadcast(PostUpdateEvent(
      postId: postId,
      commentsCount: count,
    ));
  }
}

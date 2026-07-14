import 'dart:async';

class PostUpdateEvent {
  final String postId;
  final bool? isLiked;
  final int? likesCount;
  final bool? isSaved;
  final int? commentsCount;

  PostUpdateEvent({
    required this.postId,
    this.isLiked,
    this.likesCount,
    this.isSaved,
    this.commentsCount,
  });
}

class PostEventBus {
  static final PostEventBus _instance = PostEventBus._internal();
  factory PostEventBus() => _instance;
  PostEventBus._internal();

  final _controller = StreamController<PostUpdateEvent>.broadcast();
  Stream<PostUpdateEvent> get stream => _controller.stream;

  void broadcast(PostUpdateEvent event) {
    _controller.add(event);
  }
}

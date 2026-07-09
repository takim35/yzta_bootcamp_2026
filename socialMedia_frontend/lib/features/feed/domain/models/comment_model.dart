import 'package:timeago/timeago.dart' as timeago;

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final String? parentId;
  final int likesCount;
  final bool isLiked;
  final List<CommentModel> replies;
  final DateTime createdAt;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    this.parentId,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
    required this.createdAt,
  });

  String get timeAgo {
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    return timeago.format(createdAt, locale: 'tr');
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['comment_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      content: json['content'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

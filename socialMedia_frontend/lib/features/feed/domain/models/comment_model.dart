import 'package:timeago/timeago.dart' as timeago;

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final String? parentId;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
    this.parentId,
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString().endsWith('Z') 
              ? json['created_at'] as String 
              : '${json['created_at']}Z')
          : DateTime.now(),
      parentId: json['parent_id'] as String?,
    );
  }
}

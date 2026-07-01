import 'package:timeago/timeago.dart' as timeago;
import 'outfit_item_model.dart';

class PostModel {
  final String postId;
  final String userId;
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final String visibility;
  final int likesCount;
  final bool isLiked;
  final List<OutfitItem> outfitItems;
  final DateTime createdAt;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.visibility,
    required this.likesCount,
    required this.isLiked,
    required this.outfitItems,
    required this.createdAt,
  });

  /// Zaman farkını Türkçe olarak döndürür
  String get timeAgo {
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    return timeago.format(createdAt, locale: 'tr');
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'public',
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      outfitItems: (json['outfit_items'] as List<dynamic>?)
              ?.map((item) => OutfitItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'image_url': imageUrl,
      'caption': caption,
      'visibility': visibility,
      'likes_count': likesCount,
      'is_liked': isLiked,
      'outfit_items': outfitItems.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? postId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? imageUrl,
    String? caption,
    String? visibility,
    int? likesCount,
    bool? isLiked,
    List<OutfitItem>? outfitItems,
    DateTime? createdAt,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      visibility: visibility ?? this.visibility,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      outfitItems: outfitItems ?? this.outfitItems,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'PostModel(postId: $postId, username: $username, caption: $caption)';
}

class UserModel {
  final String userId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  const UserModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
    };
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  String toString() =>
      'UserModel(userId: $userId, username: $username, displayName: $displayName)';
}

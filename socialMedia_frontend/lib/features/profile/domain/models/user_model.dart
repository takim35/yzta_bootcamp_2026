class UserModel {
  final String userId;
  final String email;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final String profileVisibility;

  const UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    this.profileVisibility = 'public',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
      'profile_visibility': profileVisibility,
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    String? profileVisibility,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      profileVisibility: profileVisibility ?? this.profileVisibility,
    );
  }

  @override
  String toString() =>
      'UserModel(userId: $userId, email: $email, username: $username, displayName: $displayName)';
}

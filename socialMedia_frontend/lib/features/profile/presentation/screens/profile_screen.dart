import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(authProvider).currentUserId;
      final targetUserId = widget.userId ?? currentUserId;
      if (targetUserId != null && targetUserId.isNotEmpty) {
        ref.read(profileProvider).loadProfile(targetUserId, currentUserId ?? targetUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(profileProvider);
    final s = ref.watch(stringsProvider);

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentViolet),
        ),
      );
    }

    if (provider.hasError || provider.user == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: Text(
            provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Profile could not be loaded',
            style: const TextStyle(color: AppTheme.errorColor),
          ),
        ),
      );
    }

    final user = provider.user!;

    return DefaultTabController(
      length: provider.isOwnProfile ? 2 : 1,
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          title: Text(
            user.username,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.primaryDark,
          elevation: 0,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildHeader(user, provider, s)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  indicatorColor: AppTheme.accentViolet,
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: [
                    const Tab(icon: Icon(Icons.grid_on_rounded)),
                    if (provider.isOwnProfile)
                      const Tab(icon: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700))),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildPostGrid(
                provider.userPosts,
                s,
                isLocked: !provider.isOwnProfile && user.profileVisibility == 'private' && !user.isFollowing,
              ),
              if (provider.isOwnProfile)
                _buildPostGrid(
                  provider.savedPosts,
                  s,
                  emptyMessage: s.isTr
                      ? 'Henüz podyumlanmış gönderi yok'
                      : 'No runway posts yet',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, ProfileProvider provider, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with gradient ring
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceDark,
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.cardDark,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? const Icon(Icons.person,
                            size: 40, color: AppTheme.textSecondary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(provider.postCount, s.posts),
                    _buildStatColumn(
                      user.followersCount,
                      s.followers,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: user.userId,
                            initialTabIndex: 0,
                          ),
                        ),
                      ),
                    ),
                    _buildStatColumn(
                      user.followingCount,
                      s.following,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: user.userId,
                            initialTabIndex: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Display name
          Text(
            user.displayName.isNotEmpty ? user.displayName : user.username,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          // Email
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                user.email,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              user.bio,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingL),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.dividerColor),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(s.editProfile,
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.dividerColor),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(s.shareProfile,
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<PostModel> posts, AppStrings s,
      {String? emptyMessage, bool isLocked = false}) {
    if (isLocked) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              s.isTr ? 'Bu profil gizlidir' : 'This profile is private',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              s.isTr ? 'Gönderilerini görmek için takip et.' : 'Follow to see their posts.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              emptyMessage ?? s.noPostsYet,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final provider = ref.read(profileProvider);
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: post.imageUrl.startsWith('http') 
                        ? Image.network(
                            post.imageUrl,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(post.imageUrl),
                            fit: BoxFit.contain,
                          ),
                    ),
                    if (provider.isOwnProfile) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: Text(s.isTr ? 'Sil' : 'Delete', style: const TextStyle(color: Colors.white)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final userId = ref.read(authProvider).currentUserId;
                          if (userId == null) return;
                          try {
                            await provider.deletePost(post.postId, userId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.isTr ? 'Gönderi silindi.' : 'Post deleted.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Silme hatası: $e'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
          child: Container(
            color: AppTheme.surfaceDark,
            child: post.imageUrl.startsWith('http')
              ? Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error_outline, color: AppTheme.textSecondary),
                  ),
                )
              : Image.file(
                  File(post.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error_outline, color: AppTheme.textSecondary),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(int count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    ),
    );
  }
}

// ── Language Option Widget ─────────────────────────────────────
class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentViolet.withValues(alpha: 0.15)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentViolet : AppTheme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.accentViolet
                    : AppTheme.textPrimary,
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentViolet, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar Delegate ───────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppTheme.primaryDark, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

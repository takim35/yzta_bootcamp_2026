import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../features/feed/presentation/widgets/empty_state.dart';
import '../../../../features/feed/presentation/widgets/shimmer_loading.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import 'follow_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Future<void> _loadProfile() async {
    final currentUserId = ref.read(authProvider).currentUserId;
    final targetUserId = widget.userId ?? currentUserId;
    if (targetUserId != null && targetUserId.isNotEmpty) {
      await ref.read(profileProvider).loadProfile(targetUserId, currentUserId ?? targetUserId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).currentUserId;
    final targetUserId = widget.userId ?? currentUserId;
    if (targetUserId == null) return const SizedBox.shrink();

    final provider = ref.watch(profileProvider);
    final s = ref.watch(stringsProvider);

    if (provider.isLoading && provider.user == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              const CustomShimmer(width: 100, height: 100, isCircle: true),
              const SizedBox(height: 16),
              const CustomShimmer(width: 150, height: 24, borderRadius: 8),
              const SizedBox(height: 32),
              Expanded(child: const ProfileGridShimmer()),
            ],
          ),
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
        body: RefreshIndicator(
          onRefresh: _loadProfile,
          color: AppTheme.accentViolet,
          backgroundColor: AppTheme.surfaceDark,
          child: NestedScrollView(
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
                    const Tab(icon: Icon(Icons.style_rounded)),
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
                targetUserId,
                isLocked: !provider.isOwnProfile && !user.isFollowing,
              ),
              if (provider.isOwnProfile)
                _buildPostGrid(
                  provider.savedPosts,
                  s,
                  targetUserId,
                  emptyMessage: s.isTr
                      ? 'Henüz Podyumda gönderi yok'
                      : 'No Podium posts yet',
                ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildHeader(dynamic user, ProfileProvider provider, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glassmorphism Profile Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceDark.withValues(alpha: 0.8),
                  AppTheme.cardDark.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentViolet.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentViolet.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with gradient ring
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceDark,
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.cardDark,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 44, color: AppTheme.textSecondary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Display name
                Text(
                  user.displayName.isNotEmpty ? user.displayName : user.username,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingL),
                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(provider.postCount, s.posts),
                      _buildStatColumn(
                        user.followersCount,
                        s.followers,
                        onTap: () => FollowListBottomSheet.show(
                          context,
                          userId: user.userId,
                          initialTabIndex: 0,
                        ),
                      ),
                      _buildStatColumn(
                        user.followingCount,
                        s.following,
                        onTap: () => FollowListBottomSheet.show(
                          context,
                          userId: user.userId,
                          initialTabIndex: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                // Action buttons
                if (provider.isOwnProfile)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(s.editProfile, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(s.shareProfile, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.toggleFollow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isFollowing ? AppTheme.surfaceDark : AppTheme.accentViolet,
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: user.isFollowing ? const BorderSide(color: AppTheme.dividerColor) : BorderSide.none,
                            ),
                            elevation: user.isFollowing ? 0 : 2,
                          ),
                          child: Text(user.isFollowing ? 'Takibi Bırak' : 'Takip Et', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<PostModel> posts, AppStrings s, String targetUserId,
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
                        icon: const Icon(Icons.delete, color: AppTheme.textPrimary),
                        label: Text(s.isTr ? 'Sil' : 'Delete', style: const TextStyle(color: AppTheme.textPrimary)),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/profile/domain/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileHeader extends ConsumerWidget {
  final UserModel user;
  final bool isOwnProfile;
  final int postCount;
  final VoidCallback? onFollowToggle;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.postCount,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // ─── Avatar + Info Row ──────────────────────────────
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: AppTheme.spacingXL),
              Expanded(child: _buildStats()),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          // ─── Name & Bio ─────────────────────────────────────
          _buildNameBio(),
          const SizedBox(height: AppTheme.spacingL),
          // ─── Follow Button ──────────────────────────────────
          if (!isOwnProfile) _buildFollowButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Semantics(
      label: '${user.displayName} profil fotoğrafı',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).cardColor,
          backgroundImage: user.avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(user.avatarUrl)
              : null,
          child: user.avatarUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatColumn(
          count: postCount,
          label: 'Gönderi',
          semanticLabel: '$postCount gönderi',
        ),
        _StatColumn(
          count: user.followersCount,
          label: 'Takipçi',
          semanticLabel: '${user.followersCount} takipçi',
        ),
        _StatColumn(
          count: user.followingCount,
          label: 'Takip',
          semanticLabel: '${user.followingCount} takip',
        ),
      ],
    );
  }

  Widget _buildNameBio() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName,
            style: const TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            semanticsLabel: user.displayName,
          ),
          const SizedBox(height: 2),
          Text(
            '@${user.username}',
            style: const TextStyle(
              color:
                  Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              fontSize: 14,
            ),
            semanticsLabel: 'Kullanıcı adı: ${user.username}',
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              user.bio,
              style: const TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: user.isFollowing
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              )
            : AppTheme.gradientButtonDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onFollowToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingM,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  user.isFollowing ? 'Takiptesin' : 'Takip Et',
                  key: ValueKey(user.isFollowing),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: user.isFollowing
                        ? Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.grey
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends ConsumerWidget {
  final int count;
  final String label;
  final String semanticLabel;

  const _StatColumn({
    required this.count,
    required this.label,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: const TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

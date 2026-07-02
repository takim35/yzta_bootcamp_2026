import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'like_button.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;
  final ValueChanged<String> onLike;
  final ValueChanged<String>? onSave;
  final VoidCallback? onComment;
  final ValueChanged<String>? onUserTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onSave,
    this.onComment,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      decoration: AppTheme.glassDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Avatar + Username + Time ─────────────────
          _buildHeader(context),
          // ─── Post Image ───────────────────────────────────────
          _buildImage(),
          // ─── Actions & Caption ────────────────────────────────
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => onUserTap?.call(post.userId),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentViolet.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Semantics(
                label: '${post.username} profil fotoğrafı',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.cardDark,
                  backgroundImage: post.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(post.avatarUrl)
                      : null,
                  child: post.avatarUrl.isEmpty
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            // Username + Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.username,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    semanticsLabel: 'Kullanıcı: ${post.username}',
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post.timeAgo,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    semanticsLabel: 'Paylaşım zamanı: ${post.timeAgo}',
                  ),
                ],
              ),
            ),
            // More options
            IconButton(
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () {},
              tooltip: 'Daha fazla',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: CachedNetworkImage(
        imageUrl: post.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.surfaceDark,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentViolet,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.surfaceDark,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_rounded,
                color: AppTheme.textMuted,
                size: 48,
              ),
              SizedBox(height: AppTheme.spacingS),
              Text(
                'Görsel yüklenemedi',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Row (Like, Comment, Save)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  LikeButton(
                    isLiked: post.isLiked,
                    likesCount: post.likesCount,
                    onToggle: () => onLike(post.postId),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  GestureDetector(
                    onTap: onComment,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.textPrimary,
                          size: 24,
                        ),
                        if (post.commentsCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentsCount}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: post.isSaved ? AppTheme.accentViolet : AppTheme.textPrimary,
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onSave?.call(post.postId),
                tooltip: post.isSaved ? 'Kaydedilenlerden Çıkar' : 'Kaydet',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Caption
          if (post.caption.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${post.username} ',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: post.caption,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // View all comments hint
          if (post.commentsCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onComment,
              child: Text(
                '${post.commentsCount} yorumun tümünü gör',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

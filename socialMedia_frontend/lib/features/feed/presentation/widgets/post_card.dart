import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../features/shared/presentation/screens/image_viewer_screen.dart';
import '../../../../core/theme/app_theme.dart';
import 'like_button.dart';
import 'likers_bottom_sheet.dart';

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
          _buildImage(context),
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
              onPressed: () => _showPostOptions(context),
              tooltip: 'Daha fazla',
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded, color: AppTheme.accentPink),
              title: const Text('İlgileniyorum', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('Bu tarz kombinleri daha çok göreceksiniz.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İlgi alanlarınıza eklendi! ✨')),
                );
              },
            ),
            const Divider(color: AppTheme.dividerColor, height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined, color: AppTheme.textPrimary),
              title: const Text('İlgilenmiyorum', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('Bu tür gönderileri daha az göreceksiniz.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geri bildiriminiz için teşekkürler! Algoritma güncelleniyor.')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (post.imageUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewerScreen(
                imageUrl: post.imageUrl,
                heroTag: 'post_image_${post.postId}',
              ),
            ),
          );
        }
      },
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Hero(
          tag: 'post_image_${post.postId}',
          child: post.imageUrl.startsWith('http')
              ? CachedNetworkImage(
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
            )
          : Image.file(
              File(post.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
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
                      'Görsel bulunamadı',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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
                    onLikersTap: () => LikersBottomSheet.show(context, postId: post.postId),
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
                  post.isSaved ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                  color: post.isSaved ? const Color(0xFFFFD700) : AppTheme.textPrimary, // Altın sarısı/parıltı efekti
                  size: 26,
                  shadows: post.isSaved ? [
                    const BoxShadow(color: Color(0x66FFD700), blurRadius: 10, spreadRadius: 2)
                  ] : null,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onSave?.call(post.postId),
                tooltip: post.isSaved ? 'Podyum\'dan Çıkar' : 'Podyuma Çıkar',
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

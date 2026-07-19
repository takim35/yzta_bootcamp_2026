import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/feed/domain/models/post_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/feed_provider.dart';
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
          _buildHeader(context, ref),
          // ─── Post Image ───────────────────────────────────────          // 📸 Post Image
          _buildImage(context),
          // ✨ Actions & Caption ────────────────────────────────
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).currentUserId;
    final isMine = post.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => onUserTap?.call(post.userId),
            onLongPress: () {
              if (post.avatarUrl.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                          clipBehavior: Clip.none,
                          child: CachedNetworkImage(
                            imageUrl: post.avatarUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const CircularProgressIndicator(color: AppTheme.accentViolet),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            child: Container(
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
          ),
          const SizedBox(width: AppTheme.spacingM),
          // Username + Time
          Expanded(
            child: GestureDetector(
              onTap: () => onUserTap?.call(post.userId),
              behavior: HitTestBehavior.opaque,
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
          ),
            // More options
            IconButton(
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.surfaceDark,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isMine) ...[
                          ListTile(
                            leading: const Icon(Icons.edit_rounded, color: AppTheme.textPrimary),
                            title: const Text('Düzenle', style: TextStyle(color: AppTheme.textPrimary)),
                            onTap: () {
                              Navigator.pop(context);
                              _showEditDialog(context, ref);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                            title: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                            onTap: () {
                              Navigator.pop(context);
                              _showDeleteConfirm(context, ref);
                            },
                          ),
                        ] else ...[
                          ListTile(
                            leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                            title: const Text('İlgileniyorum', style: TextStyle(color: AppTheme.textPrimary)),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('İlgi alanlarınıza eklendi! ✨'),
                                  backgroundColor: Colors.pinkAccent,
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.visibility_off_outlined, color: AppTheme.textMuted),
                            title: const Text('İlgilenmiyorum', style: TextStyle(color: AppTheme.textPrimary)),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bu tarz gönderiler daha az gösterilecek.'),
                                  backgroundColor: AppTheme.surfaceDark,
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
              tooltip: 'Daha fazla',
            ),
          ],
        ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  clipBehavior: Clip.none,
                  child: post.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const CircularProgressIndicator(color: AppTheme.accentViolet),
                        )
                      : Image.file(File(post.imageUrl), fit: BoxFit.contain),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 4 / 5,
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
                icon: Opacity(
                  opacity: post.isSaved ? 1.0 : 0.4,
                  child: const Text('✨', style: TextStyle(fontSize: 24)),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => onSave?.call(post.postId),
                tooltip: post.isSaved ? 'Podyumdan Çıkar' : 'Podyuma Ekle',
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

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: post.caption);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Gönderiyi Düzenle', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Yeni açıklama...',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.accentViolet),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet', style: TextStyle(color: AppTheme.accentViolet)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final newCaption = controller.text.trim();
      try {
        await ref.read(feedProvider).updatePost(post.postId, newCaption);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gönderi güncellendi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Güncelleme hatası: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Gönderiyi Sil', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu gönderiyi kalıcı olarak silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(feedProvider).deletePost(post.postId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gönderi silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $e')),
          );
        }
      }
    }
  }
}

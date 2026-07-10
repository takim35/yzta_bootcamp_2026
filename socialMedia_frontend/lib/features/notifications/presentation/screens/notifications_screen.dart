import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getNotifications(userId: userId);
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllRead() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;
    try {
      await ApiService().markAllNotificationsRead(userId: userId);
      await _loadNotifications();
    } catch (_) {}
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return AppTheme.accentViolet;
      case 'follow':
        return Colors.blueAccent;
      case 'mention':
        return Colors.orangeAccent;
      default:
        return AppTheme.textMuted;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return timeago.format(date, locale: 'tr');
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final hasUnread = _notifications.any((n) => n['is_read'] == false);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          s.isTr ? 'Bildirimler' : 'Notifications',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                s.isTr ? 'Tümünü Oku' : 'Read All',
                style: const TextStyle(color: AppTheme.accentViolet, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_rounded, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        s.isTr ? 'Henüz bildiriminiz yok' : 'No notifications yet',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.accentViolet,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['is_read'] == true;
                      final type = notif['type'] as String? ?? '';
                      final message = notif['message'] as String? ?? '';
                      final actorAvatar = notif['actor_avatar_url'] as String?;
                      final postImageUrl = notif['post_image_url'] as String?;

                      return Container(
                        color: isRead ? Colors.transparent : AppTheme.accentViolet.withOpacity(0.05),
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.surfaceDark,
                                backgroundImage: actorAvatar != null && actorAvatar.isNotEmpty
                                    ? NetworkImage(actorAvatar)
                                    : null,
                                child: actorAvatar == null || actorAvatar.isEmpty
                                    ? const Icon(Icons.person, color: AppTheme.textSecondary)
                                    : null,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getNotifIcon(type),
                                    size: 14,
                                    color: _getNotifColor(type),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            message,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _timeAgo(notif['created_at'] as String?),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          trailing: postImageUrl != null && postImageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    postImageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                )
                              : null,
                          onTap: () async {
                            if (!isRead) {
                              try {
                                await ApiService().markNotificationRead(notif['notification_id'] as String);
                                await _loadNotifications();
                              } catch (_) {}
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

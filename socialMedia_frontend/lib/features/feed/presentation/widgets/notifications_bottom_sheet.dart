import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';

class NotificationsBottomSheet extends StatefulWidget {
  final String currentUserId;

  const NotificationsBottomSheet({
    super.key,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationsBottomSheet(
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getNotifications(widget.currentUserId);
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Bildirimler yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead(widget.currentUserId);
      await _loadNotifications();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem başarısız.')),
      );
    }
  }

  Future<void> _markRead(String notificationId) async {
    try {
      await _api.markNotificationRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n['notification_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = 1;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bildirimler 🔔',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (_notifications.any((n) => n['is_read'] == 0))
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(
                        'Tümünü Okundu Yap',
                        style: TextStyle(
                          color: AppTheme.accentViolet,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.dividerColor),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentViolet),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'Henüz bildirimin yok ✨',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingS),
      itemBuilder: (context, index) {
        final notif = _notifications[index] as Map<String, dynamic>;
        final isRead = (notif['is_read'] as int? ?? 0) == 1;
        final type = notif['type'] as String? ?? 'like';
        final message = notif['message'] as String? ?? '';
        final avatarUrl = ApiService.fixImageUrl(notif['actor_avatar_url'] as String?);
        final actorName = notif['actor_display_name'] ?? notif['actor_username'] ?? '?';

        Widget iconBadge;
        if (type == 'like') {
          iconBadge = const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14);
        } else if (type == 'comment') {
          iconBadge = const Icon(Icons.chat_bubble_rounded, color: AppTheme.accentViolet, size: 14);
        } else {
          iconBadge = const Icon(Icons.person_add_rounded, color: Colors.blueAccent, size: 14);
        }

        return Container(
          decoration: BoxDecoration(
            color: isRead ? Colors.transparent : AppTheme.cardDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              if (!isRead) {
                _markRead(notif['notification_id'].toString());
              }
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.cardDark,
                  backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          actorName.isNotEmpty ? actorName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: iconBadge,
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
            trailing: isRead
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentViolet,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

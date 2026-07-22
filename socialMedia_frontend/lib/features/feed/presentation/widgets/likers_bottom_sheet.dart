import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';

class LikersBottomSheet extends StatefulWidget {
  final String postId;

  const LikersBottomSheet({
    super.key,
    required this.postId,
  });

  static void show(BuildContext context, {required String postId}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LikersBottomSheet(postId: postId),
    );
  }

  @override
  State<LikersBottomSheet> createState() => _LikersBottomSheetState();
}

class _LikersBottomSheetState extends State<LikersBottomSheet> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _likers = [];

  @override
  void initState() {
    super.initState();
    _loadLikers();
  }

  Future<void> _loadLikers() async {
    try {
      final likers = await ApiService().getPostLikers(widget.postId);
      if (mounted) {
        setState(() {
          _likers = likers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Beğenenler yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Tutma çubuğu
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Beğenenler',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                    : _likers.isEmpty
                        ? Center(child: Text('Henüz beğenen yok.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _likers.length,
                            itemBuilder: (context, index) {
                              final liker = _likers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  backgroundImage: liker['avatar_url'] != null
                                      ? CachedNetworkImageProvider(liker['avatar_url'])
                                      : null,
                                  child: liker['avatar_url'] == null
                                      ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
                                      : null,
                                ),
                                title: Text(
                                  liker['username'] ?? '',
                                  style: const TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  liker['display_name'] ?? '',
                                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(userId: liker['user_id']),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

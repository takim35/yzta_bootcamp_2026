import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'profile_screen.dart';

class FollowListBottomSheet extends ConsumerStatefulWidget {
  final String userId;
  final int initialTabIndex;

  const FollowListBottomSheet({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  static void show(BuildContext context, {required String userId, int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FollowListBottomSheet(userId: userId, initialTabIndex: initialTabIndex),
    );
  }

  @override
  ConsumerState<FollowListBottomSheet> createState() => _FollowListBottomSheetState();
}

class _FollowListBottomSheetState extends ConsumerState<FollowListBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final followers = await _api.getFollowers(widget.userId);
      final following = await _api.getFollowing(widget.userId);
      
      setState(() {
        _followers = followers;
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToProfile(String userId) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentViolet,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(text: 'Takipçiler'),
              Tab(text: 'Takip Edilenler'),
            ],
          ),
          const Divider(color: AppTheme.dividerColor, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_followers),
                      _buildUserList(_following),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Kullanıcı bulunamadı.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        final avatarUrl = user['avatar_url'];
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.cardDark,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, color: AppTheme.textSecondary)
                : null,
          ),
          title: Text(
            user['username'] ?? '',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user['display_name'] ?? '',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          onTap: () => _navigateToProfile(user['user_id'] ?? user['id']),
        );
      },
    );
  }
}

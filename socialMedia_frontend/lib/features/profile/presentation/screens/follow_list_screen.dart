import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'profile_screen.dart';

class FollowListScreen extends ConsumerStatefulWidget {
  final String userId;
  final int initialTabIndex; // 0 for Followers, 1 for Following

  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> with SingleTickerProviderStateMixin {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: const Text('Bağlantılar', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentViolet,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_followers),
                _buildUserList(_following),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../providers/search_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchProvider).searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: s.isTr ? 'Kullanıcı Ara...' : 'Search Users...',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider).clearSearch();
                      _focusNode.requestFocus();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildBody(searchState, s.isTr),
    );
  }

  Widget _buildBody(SearchProvider searchState, bool isTr) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet));
    }

    if (searchState.errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          searchState.errorMessage,
          style: const TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              isTr ? 'Kişileri bulmak için arama yapın' : 'Search to find people',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    if (searchState.searchResults.isEmpty) {
      return Center(
        child: Text(
          isTr ? 'Sonuç bulunamadı' : 'No results found',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: searchState.searchResults.length,
      separatorBuilder: (context, index) => const Divider(color: AppTheme.dividerColor),
      itemBuilder: (context, index) {
        final user = searchState.searchResults[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: user.userId),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: AppTheme.surfaceDark,
            backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty ? const Icon(Icons.person, color: AppTheme.textSecondary) : null,
          ),
          title: Text(
            user.username,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.displayName,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          trailing: ElevatedButton(
            onPressed: () => searchState.toggleFollow(user.userId, user.isFollowing),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isFollowing ? AppTheme.surfaceDark : AppTheme.accentViolet,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: user.isFollowing ? const BorderSide(color: AppTheme.dividerColor) : BorderSide.none,
              ),
            ),
            child: Text(
              user.isFollowing 
                  ? (isTr ? 'Takibi Bırak' : 'Unfollow') 
                  : (isTr ? 'Takip Et' : 'Follow'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

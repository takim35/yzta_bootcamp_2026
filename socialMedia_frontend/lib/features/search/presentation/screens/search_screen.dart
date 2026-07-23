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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
          decoration: InputDecoration(
            hintText: s.isTr ? 'Kullanıcı Ara...' : 'Search Users...',
            hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
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
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary));
    }

    if (searchState.errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          searchState.errorMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 64,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              isTr
                  ? 'Kişileri bulmak için arama yapın'
                  : 'Search to find people',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
            ),
          ],
        ),
      );
    }

    if (searchState.searchResults.isEmpty) {
      return Center(
        child: Text(
          isTr ? 'Sonuç bulunamadı' : 'No results found',
          style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: searchState.searchResults.length,
      separatorBuilder: (context, index) =>
          Divider(color: Theme.of(context).dividerColor),
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty
                ? Icon(Icons.person,
                    color: Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey)
                : null,
          ),
          title: Text(
            user.username,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.displayName,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey),
          ),
          trailing: ElevatedButton(
            onPressed: () =>
                searchState.toggleFollow(user.userId, user.isFollowing),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isFollowing
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: user.isFollowing
                    ? BorderSide(color: Theme.of(context).dividerColor)
                    : BorderSide.none,
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

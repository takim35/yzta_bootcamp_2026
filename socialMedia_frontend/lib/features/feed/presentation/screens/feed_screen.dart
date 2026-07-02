import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/feed/presentation/providers/feed_provider.dart';
import '../../../../features/feed/presentation/widgets/post_card.dart';
import '../../../../features/feed/presentation/widgets/shimmer_loading.dart';
import '../../../../features/feed/presentation/widgets/empty_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/feed/presentation/widgets/comments_bottom_sheet.dart';
import '../../../../core/theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider).loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(feedProvider);
    final currentUserId = ref.watch(authProvider).currentUserId ?? '';

    return Scaffold(
      appBar: _buildAppBar(),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const FeedShimmer();
          }

          if (provider.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Bir şeyler ters gitti',
              subtitle: provider.errorMessage,
              actionLabel: 'Tekrar Dene',
              onAction: () => provider.loadFeed(),
            );
          }

          if (provider.posts.isEmpty) {
            return EmptyState(
              icon: Icons.explore_rounded,
              title: 'Henüz gönderi yok',
              subtitle: 'Keşfetmeye başlamak için kullanıcıları takip et!',
              actionLabel: 'Keşfet',
              onAction: () {
                // Keşfet sayfasına yönlendirme
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppTheme.accentViolet,
            backgroundColor: AppTheme.surfaceDark,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                top: AppTheme.spacingS,
                bottom: AppTheme.spacingXXL * 3,
              ),
              itemCount:
                  provider.posts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Son eleman: loading göstergesi
                if (index == provider.posts.length) {
                  return _buildLoadingMore();
                }

                final post = provider.posts[index];
                return PostCard(
                  post: post,
                  onLike: (postId) => provider.toggleLike(postId),
                  onSave: (postId) => provider.toggleSave(postId),
                  onComment: () {
                    CommentsBottomSheet.show(
                      context,
                      postId: post.postId,
                      currentUserId: currentUserId,
                      initialCommentsCount: post.commentsCount,
                      onCommentsCountChanged: (count) =>
                          provider.updateCommentsCount(post.postId, count),
                    );
                  },
                  onUserTap: (userId) {
                    debugPrint('Profil sayfasına git: $userId');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: ShaderMask(
        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: const Text(
          'Spot Online',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          semanticsLabel: 'Spot Online ana sayfa',
        ),
      ),
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.textPrimary,
          ),
          onPressed: () {},
          tooltip: 'Bildirimler',
        ),
      ],
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spacingXL),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accentViolet,
          ),
        ),
      ),
    );
  }
}

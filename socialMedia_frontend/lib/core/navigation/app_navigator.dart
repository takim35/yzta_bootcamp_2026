import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/create_post/presentation/screens/create_post_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../theme/app_theme.dart';
import '../localization/locale_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class AppNavigator extends ConsumerWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final s = ref.watch(stringsProvider);

    final screens = [
      const FeedScreen(),
      const SearchScreen(),
      const CreatePostScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.accentViolet,
        unselectedItemColor: AppTheme.textMuted,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: s.navFeed),
          BottomNavigationBarItem(icon: const Icon(Icons.search_rounded), label: s.isTr ? 'Ara' : 'Search'),
          BottomNavigationBarItem(icon: const Icon(Icons.add_box_rounded), label: s.isTr ? 'Gönderi' : 'Post'),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: s.navProfile),
        ],
      ),
    );
  }
}

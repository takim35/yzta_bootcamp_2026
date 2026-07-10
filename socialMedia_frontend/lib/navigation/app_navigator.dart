import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/create_post/presentation/screens/create_post_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/theme/app_theme.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class AppNavigator extends ConsumerStatefulWidget {
  const AppNavigator({super.key});

  @override
  ConsumerState<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends ConsumerState<AppNavigator> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const FeedScreen(),
      const CreatePostScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.cardDark,
        selectedItemColor: AppTheme.accentViolet,
        unselectedItemColor: AppTheme.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Kesfet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Gonderi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

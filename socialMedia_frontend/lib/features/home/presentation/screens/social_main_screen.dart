import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/feed/presentation/screens/feed_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SocialMainScreen extends ConsumerStatefulWidget {
  const SocialMainScreen({super.key});

  @override
  ConsumerState<SocialMainScreen> createState() => _SocialMainScreenState();
}

class _SocialMainScreenState extends ConsumerState<SocialMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).currentUserId;

    final List<Widget> screens = [
      const FeedScreen(),
      ProfileScreen(userId: currentUserId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.surfaceDark,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: AppTheme.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.public_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

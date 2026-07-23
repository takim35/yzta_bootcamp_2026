import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/wardrobe/presentation/screens/wardrobe_screen.dart';
import '../../features/profile/presentation/screens/more_screen.dart';
import '../../features/home/presentation/screens/try_on_coming_soon_screen.dart';
import '../../features/home/presentation/screens/social_main_screen.dart';

final mainNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavIndexProvider);

    final screens = [
      DashboardScreen(),
      WardrobeScreen(),
      TryOnComingSoonScreen(),
      MoreScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      // Central Floating Action Button (Social Media)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Social Media Feed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SocialMainScreen()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
        child: Icon(Icons.public_rounded, size: 28), // Social media vibe icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Custom Bottom App Bar
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => ref.read(mainNavIndexProvider.notifier).state = 0,
            ),
            _NavBarItem(
              icon: Icons.checkroom_rounded,
              label: 'Wardrobe',
              isSelected: currentIndex == 1,
              onTap: () => ref.read(mainNavIndexProvider.notifier).state = 1,
            ),
            const SizedBox(width: 48), // Empty space for FAB
            _NavBarItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Try-On',
              isSelected: currentIndex == 2,
              onTap: () => ref.read(mainNavIndexProvider.notifier).state = 2,
            ),
            _NavBarItem(
              icon: Icons.grid_view_rounded,
              label: 'More',
              isSelected: currentIndex == 3,
              onTap: () => ref.read(mainNavIndexProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

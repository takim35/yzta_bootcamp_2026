import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/wardrobe/presentation/screens/wardrobe_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/more_screen.dart';
import '../../features/wardrobe/presentation/screens/ai_stylist_screen.dart';

final mainNavIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavIndexProvider);

    final screens = [
      const DashboardScreen(),
      const WardrobeScreen(),
      const HistoryScreen(), // Placeholder for now
      const MoreScreen(), // Merged Profile/Settings
    ];

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      // Central Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AI Stylist Suggestion
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiStylistScreen()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Custom Bottom App Bar
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side tabs
            Row(
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => ref.read(mainNavIndexProvider.notifier).state = 0,
                ),
                const SizedBox(width: 24),
                _NavBarItem(
                  icon: Icons.checkroom_rounded,
                  label: 'Wardrobe',
                  isSelected: currentIndex == 1,
                  onTap: () => ref.read(mainNavIndexProvider.notifier).state = 1,
                ),
              ],
            ),
            // Right side tabs
            Row(
              children: [
                _NavBarItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'History',
                  isSelected: currentIndex == 2,
                  onTap: () => ref.read(mainNavIndexProvider.notifier).state = 2,
                ),
                const SizedBox(width: 24),
                _NavBarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  isSelected: currentIndex == 3,
                  onTap: () => ref.read(mainNavIndexProvider.notifier).state = 3,
                ),
              ],
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

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : AppTheme.textMuted;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
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

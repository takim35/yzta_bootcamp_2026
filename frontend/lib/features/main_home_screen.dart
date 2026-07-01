import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_navigator.dart';

class MainHomeScreen extends ConsumerWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                'Spot',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Dijital tarzina yon ver.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.spacingM,
                  mainAxisSpacing: AppTheme.spacingM,
                  children: [
                    _buildModuleCard(
                      context: context,
                      title: 'Gardirop',
                      subtitle: 'Kiyafetlerini yonet',
                      icon: Icons.checkroom,
                      onTap: () {
                        // Placeholder for Wardrobe Team
                      },
                    ),
                    _buildModuleCard(
                      context: context,
                      title: 'AI Stilist',
                      subtitle: 'Yapay zeka onerileri',
                      icon: Icons.auto_awesome,
                      onTap: () {
                        // Placeholder for LLM Team
                      },
                    ),
                    _buildModuleCard(
                      context: context,
                      title: 'AR Ayna',
                      subtitle: 'Sanal deneme kabini',
                      icon: Icons.camera_front,
                      onTap: () {
                        // Placeholder for AR Team
                      },
                    ),
                    _buildModuleCard(
                      context: context,
                      title: 'Sosyal',
                      subtitle: 'Toplulukla paylas',
                      icon: Icons.public,
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppNavigator(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isPrimary
            ? AppTheme.gradientButtonDecoration()
            : AppTheme.glassDecoration(),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.surfaceDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: TextStyle(
                color: isPrimary ? Colors.white70 : AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

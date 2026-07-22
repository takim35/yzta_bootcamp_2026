import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Profile Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'U', // User initial placeholder
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View your posts & podium',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      title: 'Preferences',
                      icon: Icons.tune_rounded,
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(
                      title: 'Theme',
                      icon: Icons.dark_mode_rounded,
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(
                      title: 'Sign Out',
                      icon: Icons.logout_rounded,
                      isDestructive: true,
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
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
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? AppTheme.errorColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

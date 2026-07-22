import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'local_profile_screen.dart';
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
                    MaterialPageRoute(builder: (_) => const LocalProfileScreen()),
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
                    _SettingsTile(title: 'Style Preferences', icon: Icons.palette_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Location & Timezone', icon: Icons.location_on_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Social Followings', icon: Icons.group_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Outfit Schedule', icon: Icons.calendar_today_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Try-On Photo', icon: Icons.person_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Language', icon: Icons.language_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Body Measurements', icon: Icons.straighten_rounded, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Subscription', icon: Icons.credit_card_rounded, onTap: () {}),
                  ],
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
                    _SettingsSwitch(title: 'Haptic Feedback', icon: Icons.vibration_rounded, value: true, onChanged: (v) {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsAppearance(title: 'Appearance', icon: Icons.brightness_medium_rounded),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsServer(title: 'Server', subtitle: 'app.spot.com'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: _SettingsTile(
                  title: 'Sign Out',
                  icon: Icons.logout_rounded,
                  isCenter: true,
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                  },
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
                    _SettingsTile(title: 'Terms of Use', icon: Icons.description_rounded, hasExternalIcon: true, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(title: 'Privacy Policy', icon: Icons.security_rounded, hasExternalIcon: true, onTap: () {}),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    _SettingsTile(
                      title: 'Delete Account',
                      icon: Icons.delete_outline_rounded,
                      isDestructive: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // padding for bottom nav
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
  final bool isCenter;
  final bool hasExternalIcon;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.isCenter = false,
    this.hasExternalIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: isCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
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
            if (!isCenter) const Spacer(),
            if (!isCenter)
              Icon(
                hasExternalIcon ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.successColor,
            activeTrackColor: AppTheme.successColor.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceDark,
          ),
        ],
      ),
    );
  }
}

class _SettingsAppearance extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SettingsAppearance({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SegmentItem(label: 'System', isSelected: true)),
              const SizedBox(width: 8),
              Expanded(child: _SegmentItem(label: 'Light', isSelected: false)),
              const SizedBox(width: 8),
              Expanded(child: _SegmentItem(label: 'Dark', isSelected: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _SegmentItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.dividerColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.white : AppTheme.dividerColor,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SettingsServer extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsServer({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.dns_rounded, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

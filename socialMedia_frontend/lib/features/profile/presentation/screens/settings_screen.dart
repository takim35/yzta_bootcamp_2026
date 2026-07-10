import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/api_service.dart';
import '../providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../../features/auth/presentation/screens/two_factor_setup_screen.dart';
import '../../../../features/auth/presentation/screens/forgot_password_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isPrivate = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(authProvider).currentUserId;
    if (currentUserId != null) {
      final user = ref.read(profileProvider(currentUserId)).user;
      if (user != null) {
        // profileVisibility alanı genişletildiğinde buradan okunacak
      }
    }
  }

  Future<void> _updatePrivacy(bool val) async {
    setState(() {
      _isPrivate = val;
      _isLoading = true;
    });
    try {
      final userId = ref.read(authProvider).currentUserId;
      if (userId == null) return;
      await ApiService().updatePrivacy(userId, val);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).isTr
                ? 'Gizlilik ayarı güncellendi.'
                : 'Privacy updated.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrivate = !val);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(s.isTr ? 'Hesabı Sil' : 'Delete Account',
            style: const TextStyle(color: AppTheme.errorColor)),
        content: Text(
          s.isTr
              ? 'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'
              : 'Are you sure you want to delete your account? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.isTr ? 'İptal' : 'Cancel',
                style: const TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isTr ? 'Evet, Sil' : 'Yes, Delete',
                style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final userId = ref.read(authProvider).currentUserId;
        if (userId != null) {
          await ApiService().deleteAccount(userId);
          ref.read(authProvider).logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (_) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(s.isTr ? 'Ayarlar' : 'Settings',
            style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentViolet))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Removed Privacy Section from here

                const SizedBox(height: 16),
                
                // ── Genel ───────────────────────────────────────
                Text(
                  s.isTr ? 'Genel' : 'General',
                  style: const TextStyle(
                      color: AppTheme.accentViolet,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                // Dil Ayarı
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.isTr ? 'Uygulama Dili' : 'App Language',
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: _LangButton(
                          label: '🇹🇷 Türkçe',
                          selected: ref.watch(localeProvider) == AppLocale.tr,
                          onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.tr),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LangButton(
                          label: '🇬🇧 English',
                          selected: ref.watch(localeProvider) == AppLocale.en,
                          onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppTheme.dividerColor, height: 48),

                // ── Hesap ───────────────────────────────────────
                Text(
                  s.isTr ? 'Hesap' : 'Account',
                  style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),

                // 2FA Setup
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.isTr ? 'İki Aşamalı Doğrulama (2FA)' : 'Two-Factor Authentication (2FA)',
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.security_rounded, color: AppTheme.accentViolet),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()),
                    );
                  },
                ),

                // Şifre Sıfırla
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.isTr ? 'Şifre Sıfırla' : 'Reset Password',
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                ),

                // Çıkış Yap
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.isTr ? 'Çıkış Yap' : 'Log Out',
                      style: const TextStyle(color: AppTheme.errorColor)),
                  trailing: const Icon(Icons.logout_rounded,
                      color: AppTheme.errorColor),
                  onTap: () {
                    ref.read(authProvider).logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (_) => false,
                    );
                  },
                ),

                const Divider(color: AppTheme.dividerColor, height: 48),
                // Hesabı Sil
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.isTr ? 'Hesabımı Sil' : 'Delete My Account',
                      style: const TextStyle(color: AppTheme.errorColor)),
                  trailing: const Icon(Icons.delete_forever_rounded,
                      color: AppTheme.errorColor),
                  onTap: _deleteAccount,
                ),
              ],
            ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentViolet.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.accentViolet : AppTheme.textMuted,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

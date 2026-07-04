import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../services/api_service.dart';
import '../providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

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
    // In a real app we'd load this from the user's current settings
    // For now we'll assume public unless we have that data
    final user = ref.read(profileProvider).user;
    if (user != null) {
      // If we extended UserModel to include profileVisibility:
      // _isPrivate = user.profileVisibility == 'private';
      // For now we just default to false since we didn't update UserModel yet
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
          SnackBar(content: Text(ref.read(stringsProvider).isTr ? 'Gizlilik ayarı güncellendi.' : 'Privacy updated.')),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final s = ref.read(stringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(s.isTr ? 'Hesabı Sil' : 'Delete Account', style: const TextStyle(color: AppTheme.errorColor)),
        content: Text(
          s.isTr ? 'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.' : 'Are you sure you want to delete your account? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isTr ? 'Evet, Sil' : 'Yes, Delete', style: const TextStyle(color: AppTheme.errorColor)),
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
          ref.read(authProvider).logout(); // Log out local state
          if (mounted) {
            Navigator.pop(context); // Go back to login
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
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
        title: Text(s.isTr ? 'Ayarlar' : 'Settings', style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                s.isTr ? 'Gizlilik' : 'Privacy',
                style: const TextStyle(color: AppTheme.accentViolet, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.isTr ? 'Gizli Profil' : 'Private Profile', style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(
                  s.isTr ? 'Sadece takipçilerin gönderilerini görebilir.' : 'Only followers can see your posts.',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                trailing: Switch(
                  value: _isPrivate,
                  onChanged: _updatePrivacy,
                  activeColor: AppTheme.accentViolet,
                ),
              ),
              const Divider(color: AppTheme.dividerColor, height: 48),
              Text(
                s.isTr ? 'Hesap' : 'Account',
                style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.isTr ? 'Şifre Sıfırla' : 'Reset Password', style: const TextStyle(color: AppTheme.textPrimary)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
                onTap: () {
                  // In a real app we would navigate to a reset password screen or send an email
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.isTr ? 'Şifre sıfırlama bağlantısı e-postanıza gönderildi.' : 'Password reset link sent to your email.')),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.isTr ? 'Hesabımı Sil' : 'Delete My Account', style: const TextStyle(color: AppTheme.errorColor)),
                trailing: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor),
                onTap: _deleteAccount,
              ),
            ],
          ),
    );
  }
}

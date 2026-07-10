import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../services/api_service.dart';
import '../providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isPrivate = false;
  String _avatarUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(authProvider).currentUserId;
    if (currentUserId == null) return;
    final user = ref.read(profileProvider(currentUserId)).user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _bioController.text = user.bio;
      _avatarUrl = user.avatarUrl;
      _isPrivate = user.profileVisibility == 'private';
    }
  }

  Future<void> _pickImage() async {
    final s = ref.read(stringsProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentViolet),
              title: Text(s.isTr ? 'Kamera' : 'Camera', style: const TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentViolet),
              title: Text(s.isTr ? 'Galeri' : 'Gallery', style: const TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            if (_avatarUrl.isNotEmpty || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                title: Text(s.isTr ? 'Fotoğrafı Kaldır' : 'Remove Photo', style: const TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _avatarUrl = '';
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authProvider).currentUserId;
      if (userId == null) return;

      String finalAvatarUrl = _avatarUrl;

      // If a new image was picked, upload it first
      if (_pickedImage != null) {
        try {
          final uploadResult = await ApiService().uploadImage(_pickedImage!);
          finalAvatarUrl = uploadResult;
        } catch (e) {
          // If upload fails, use local path as fallback (mock)
          finalAvatarUrl = _pickedImage!.path;
        }
      }
      
      await ApiService().updateProfile(
        userId: userId,
        displayName: _displayNameController.text,
        bio: _bioController.text,
        avatarUrl: finalAvatarUrl,
      );

      await ApiService().updatePrivacy(userId, _isPrivate);
      
      // Refresh profile data
      await ref.read(profileProvider(userId)).loadProfile(userId, userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(s.isTr ? 'Profili Düzenle' : 'Edit Profile', style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentViolet))
              : Text(s.isTr ? 'Kaydet' : 'Save', style: const TextStyle(color: AppTheme.accentViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar with camera button
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.surfaceDark,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) as ImageProvider : null),
                      child: (_pickedImage == null && _avatarUrl.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: AppTheme.textSecondary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.accentViolet,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.isTr ? 'Profil fotoğrafını değiştirmek için dokun' : 'Tap to change profile photo',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            // Display Name
            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: s.isTr ? 'Görünen Ad' : 'Display Name',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentViolet),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Bio
            TextField(
              controller: _bioController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: s.isTr ? 'Biyografi' : 'Bio',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.info_outline, color: AppTheme.textMuted),
                ),
                counterStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentViolet),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppTheme.dividerColor),
            const SizedBox(height: 16),
            // Privacy Toggle
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: AppTheme.textPrimary),
              title: Text(s.isTr ? 'Gizli Profil' : 'Private Profile',
                  style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(
                s.isTr
                    ? 'Sadece takipçilerin gönderilerini görebilir.'
                    : 'Only followers can see your posts.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              trailing: Switch(
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
                activeColor: AppTheme.accentViolet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

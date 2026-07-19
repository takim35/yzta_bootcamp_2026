import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
  final _avatarUrlController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _bioController.text = user.bio;
      _avatarUrlController.text = user.avatarUrl;
    }
  }

  Future<String?> _uploadImage(File file) async {
    final uri = Uri.parse('${ApiService.baseUrl}/captions/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String?;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1024);
    if (xfile != null) {
      setState(() => _selectedImage = File(xfile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authProvider).currentUserId;
      if (userId == null) return;
      
      String avatarUrl = _avatarUrlController.text;
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage(_selectedImage!);
        if (uploadedUrl != null) avatarUrl = uploadedUrl;
      }
      
      await ApiService().updateProfile(
        userId: userId,
        displayName: _displayNameController.text,
        bio: _bioController.text,
        avatarUrl: avatarUrl,
      );
      
      // Refresh profile data
      await ref.read(profileProvider).loadProfile(userId, userId);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
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
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.surfaceDark,
                      backgroundImage: _selectedImage != null 
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (_avatarUrlController.text.isNotEmpty ? NetworkImage(_avatarUrlController.text) : null),
                      child: (_selectedImage == null && _avatarUrlController.text.isEmpty) 
                          ? const Icon(Icons.person, size: 50, color: AppTheme.textSecondary) : null,
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
            const SizedBox(height: 32),
            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: s.isTr ? 'Görünen Ad' : 'Display Name',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.dividerColor)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentViolet)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.isTr ? 'Biyografi' : 'Bio',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.dividerColor)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentViolet)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _avatarUrlController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: s.isTr ? 'Profil Fotoğrafı URL' : 'Avatar URL',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.dividerColor)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentViolet)),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

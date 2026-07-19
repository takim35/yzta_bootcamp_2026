import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../services/api_service.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isAnalyzing = false;

  // Form state
  String _tur = 'Tişört';
  String _renk = 'Siyah';
  String _mevsim = 'Tüm Sezon';
  final _markaCtrl = TextEditingController();
  final _bedenCtrl = TextEditingController();

  static const _turler = [
    'Tişört', 'Gömlek', 'Bluz', 'Kazak', 'Sweatshirt',
    'Pantolon', 'Şort', 'Etek', 'Elbise', 'Ceket',
    'Mont', 'Kaban', 'Ayakkabı', 'Bot', 'Sneaker',
    'Çanta', 'Aksesuar', 'Diğer',
  ];

  static const _renkler = [
    'Siyah', 'Beyaz', 'Gri', 'Lacivert', 'Mavi',
    'Kırmızı', 'Pembe', 'Yeşil', 'Sarı', 'Turuncu',
    'Mor', 'Kahverengi', 'Bej', 'Bordo', 'Karışık',
  ];

  static const _mevsimler = ['Yaz', 'Kış', 'İlkbahar', 'Sonbahar', 'Tüm Sezon'];

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (xfile != null) {
      setState(() {
        _selectedImage = File(xfile.path);
        _isAnalyzing = true;
      });
      
      try {
        final bytes = await xfile.readAsBytes();
        final base64Image = base64Encode(bytes);
        final result = await ApiService().analyzeClothingItem(base64Image);
        
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          if (mounted) {
            setState(() {
              if (data['tur'] != null && _turler.contains(data['tur'])) {
                _tur = data['tur'];
              }
              if (data['renk'] != null && _renkler.contains(data['renk'])) {
                _renk = data['renk'];
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yapay zeka kıyafeti başarıyla analiz etti! ✨'),
                backgroundColor: AppTheme.accentViolet,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("AI Analyze Error: $e");
      } finally {
        if (mounted) {
          setState(() => _isAnalyzing = false);
        }
      }
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

  Future<void> _submit() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum açmanız gerekiyor.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      await ApiService().addCloth(userId, {
        'tur': _tur,
        'renk': _renk,
        'marka': _markaCtrl.text.isEmpty ? null : _markaCtrl.text,
        'beden': _bedenCtrl.text.isEmpty ? null : _bedenCtrl.text,
        'mevsim': _mevsim,
        'temiz': true,
        if (imageUrl != null) 'foto_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context, true); // true = yenile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Kıyafet eklendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceSheet() {
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
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentViolet),
              title: const Text('Kamera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentPink),
              title: const Text('Fotoğraf Kitaplığı', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Kıyafet Ekle', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentViolet),
                  ),
                )
              : TextButton(
                  onPressed: _submit,
                  child: const Text('Kaydet', style: TextStyle(color: AppTheme.accentViolet, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fotoğraf Seçimi ─────────────────────────
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppTheme.accentViolet
                        : AppTheme.dividerColor,
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                          if (_isAnalyzing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: AppTheme.accentViolet),
                                  SizedBox(height: 12),
                                  Text(
                                    'Yapay Zeka Analiz Ediyor...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 52, color: AppTheme.accentViolet.withValues(alpha: 0.7)),
                          const SizedBox(height: 12),
                          const Text('Fotoğraf ekle',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Kamera veya kitaplıktan seç',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Kategori ────────────────────────────────
            _SectionLabel(text: 'Tür *'),
            _DropdownField(
              value: _tur,
              items: _turler,
              onChanged: (v) => setState(() => _tur = v!),
            ),

            const SizedBox(height: 16),

            // ── Renk ────────────────────────────────────
            _SectionLabel(text: 'Renk *'),
            _DropdownField(
              value: _renk,
              items: _renkler,
              onChanged: (v) => setState(() => _renk = v!),
            ),

            const SizedBox(height: 16),

            // ── Mevsim ──────────────────────────────────
            _SectionLabel(text: 'Mevsim'),
            _DropdownField(
              value: _mevsim,
              items: _mevsimler,
              onChanged: (v) => setState(() => _mevsim = v!),
            ),

            const SizedBox(height: 16),

            // ── Marka ───────────────────────────────────
            _SectionLabel(text: 'Marka (opsiyonel)'),
            _TextField(controller: _markaCtrl, hint: 'Nike, Zara, H&M...'),

            const SizedBox(height: 16),

            // ── Beden ───────────────────────────────────
            _SectionLabel(text: 'Beden (opsiyonel)'),
            _TextField(controller: _bedenCtrl, hint: 'XS, S, M, L, XL, 36, 38...'),

            const SizedBox(height: 40),

            // ── Kaydet Butonu ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Kıyafeti Ekle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.cardDark,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentViolet),
        ),
      ),
    );
  }
}

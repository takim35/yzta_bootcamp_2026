import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../services/api_service.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialItem;

  const EditItemScreen({super.key, required this.initialItem});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isDeleting = false;

  late String _tur;
  late String _renk;
  late String _mevsim;

  final _markaCtrl = TextEditingController();
  final _bedenCtrl = TextEditingController();

  final List<String> _turler = ['Ãœst Giyim', 'Alt Giyim', 'DÄ±ÅŸ Giyim', 'Elbise', 'AyakkabÄ±', 'Aksesuar', 'Ã‡anta'];
  final List<String> _renkler = ['Siyah', 'Beyaz', 'KÄ±rmÄ±zÄ±', 'Mavi', 'YeÅŸil', 'SarÄ±', 'Gri', 'Kahverengi', 'Ã‡ok Renkli'];
  final List<String> _mevsimler = ['Ä°lkbahar', 'Yaz', 'Sonbahar', 'KÄ±ÅŸ', 'TÃ¼m Sezon'];

  @override
  void initState() {
    super.initState();
    _tur = _ensureValidDropdownValue(widget.initialItem['tur'], _turler);
    _renk = _ensureValidDropdownValue(widget.initialItem['renk'], _renkler);
    _mevsim = _ensureValidDropdownValue(widget.initialItem['mevsim'], _mevsimler);
    
    _markaCtrl.text = widget.initialItem['marka'] ?? '';
    _bedenCtrl.text = widget.initialItem['beden'] ?? '';
  }

  String _ensureValidDropdownValue(dynamic val, List<String> items) {
    if (val == null || !items.contains(val)) return items.first;
    return val as String;
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 70);
    if (xfile != null) {
      setState(() => _selectedImage = File(xfile.path));
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
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl = widget.initialItem['foto_url'];
      if (_selectedImage != null) {
        final uploaded = await _uploadImage(_selectedImage!);
        if (uploaded != null) imageUrl = uploaded;
      }

      await ApiService().updateCloth(widget.initialItem['id'], {
        'tur': _tur,
        'renk': _renk,
        'marka': _markaCtrl.text.isEmpty ? null : _markaCtrl.text,
        'beden': _bedenCtrl.text.isEmpty ? null : _bedenCtrl.text,
        'mevsim': _mevsim,
        'foto_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KÄ±yafet gÃ¼ncellendi!')),
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

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('KÄ±yafeti Sil', style: TextStyle(color: AppTheme.errorColor)),
        content: const Text('Bu kÄ±yafeti gardÄ±roptan silmek istediÄŸinize emin misiniz?', style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ä°ptal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await ApiService().deleteCloth(widget.initialItem['id']);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('KÄ±yafet silindi.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinirken hata oluÅŸtu: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              title: const Text('FotoÄŸraf KitaplÄ±ÄŸÄ±', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = widget.initialItem['foto_url'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('KÄ±yafeti DÃ¼zenle', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          _isDeleting 
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.errorColor, strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                onPressed: _deleteItem,
              ),
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
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : (fotoUrl != null && fotoUrl.isNotEmpty)
                        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(fotoUrl, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 52, color: AppTheme.accentViolet.withValues(alpha: 0.7)),
                              const SizedBox(height: 12),
                              const Text('FotoÄŸraf deÄŸiÅŸtir', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(text: 'Tür *'),
            _ChipsField(value: _tur, items: _turler, onChanged: (v) => setState(() => _tur = v)),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Renk *'),
            _ChipsField(value: _renk, items: _renkler, onChanged: (v) => setState(() => _renk = v)),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Mevsim'),
            _ChipsField(value: _mevsim, items: _mevsimler, onChanged: (v) => setState(() => _mevsim = v)),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Marka'),
            TextField(
              controller: _markaCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: _inputDeco('Marka giriniz'),
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Beden'),
            TextField(
              controller: _bedenCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: _inputDeco('Beden (Ã–rn: M, 38)'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
    );
  }
}

class _ChipsField extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  const _ChipsField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == value;
        return GestureDetector(
          onTap: () => onChanged(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentViolet : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.accentViolet : AppTheme.dividerColor,
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

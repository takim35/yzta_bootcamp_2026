import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import 'outfit_detail_screen.dart';

class OutfitBuilderScreen extends ConsumerStatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  ConsumerState<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _clothesFuture;
  final Set<int> _selectedItemIds = {};
  final List<Map<String, dynamic>> _selectedClothes = [];
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  void _loadClothes() {
    final userId = ref.read(authProvider).currentUserId ?? '';
    setState(() {
      _clothesFuture = _apiService.getClothes(userId);
    });
  }

  void _toggleSelection(Map<String, dynamic> cloth) {
    final id = cloth['id'] as int;
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
        _selectedClothes.removeWhere((item) => item['id'] == id);
      } else {
        _selectedItemIds.add(id);
        _selectedClothes.add(cloth);
      }
    });
  }

  Future<void> _createOutfit() async {
    final s = ref.read(stringsProvider);
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.isTr ? 'Lütfen en az bir kıyafet seçin.' : 'Please select at least one item.')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.isTr ? 'Lütfen kombine bir isim verin.' : 'Please give your outfit a name.')),
      );
      return;
    }

    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.createOutfit(
        userId,
        _nameController.text.trim(),
        _selectedItemIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.isTr ? 'Kombin başarıyla oluşturuldu! ✨' : 'Outfit created successfully! ✨'),
            backgroundColor: AppTheme.accentViolet,
          ),
        );
        // Navigate to details screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OutfitDetailScreen(
              outfitName: _nameController.text.trim(),
              clothes: _selectedClothes,
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          s.isTr ? 'Kombin Oluştur' : 'Outfit Builder',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          // Input for Outfit Name
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: s.isTr ? 'Kombin İsmi (Örn: Hafta Sonu Gezisi)' : 'Outfit Name (e.g. Weekend Trip)',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Selection Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.isTr ? 'Kıyafet Seç (${_selectedItemIds.length} seçildi)' : 'Select Clothes (${_selectedItemIds.length} selected)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Clothes Grid
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _clothesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorColor)));
                }

                final clothes = snapshot.data ?? [];
                if (clothes.isEmpty) {
                  return Center(
                    child: Text(
                      s.noClothesFound,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: clothes.length,
                  itemBuilder: (context, index) {
                    final cloth = clothes[index] as Map<String, dynamic>;
                    final id = cloth['id'] as int;
                    final isSelected = _selectedItemIds.contains(id);
                    final imageUrl = cloth['foto_url']?.toString() ?? cloth['image_url']?.toString() ?? '';

                    return GestureDetector(
                      onTap: () => _toggleSelection(cloth),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentViolet : AppTheme.dividerColor,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.checkroom_rounded, color: AppTheme.textMuted, size: 40),
                            if (isSelected)
                              Container(
                                color: AppTheme.accentViolet.withValues(alpha: 0.3),
                                child: const Center(
                                  child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOutfit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                        s.isTr ? 'Kombini Kaydet' : 'Save Outfit',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

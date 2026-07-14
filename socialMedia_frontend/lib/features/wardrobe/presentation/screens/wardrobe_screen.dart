import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _clothesFuture;
  String _selectedCategory = 'Tümü';

  final List<String> _categories = [
    'Tümü',
    'Üst Giyim',
    'Alt Giyim',
    'Ayakkabı',
    'Dış Giyim',
    'Aksesuar',
    'Kombinlerim'
  ];

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

  Future<void> _deleteCloth(int clothId) async {
    try {
      await _apiService.deleteCloth(clothId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kıyafet silindi'), backgroundColor: AppTheme.successColor),
        );
        _loadClothes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme başarısız: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _showItemOptions(BuildContext context, Map<String, dynamic> cloth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: AppTheme.accentPurple),
                ),
                title: const Text('Düzenle', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditItemScreen(initialItem: cloth),
                    ),
                  ).then((refreshed) {
                    if (refreshed == true) _loadClothes();
                  });
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
                ),
                title: const Text('Sil', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: AppTheme.cardDark,
                      title: const Text('Emin misiniz?', style: TextStyle(color: AppTheme.textPrimary)),
                      content: const Text('Bu kıyafeti gardırobundan silmek istediğine emin misin?', style: TextStyle(color: AppTheme.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dCtx);
                            _deleteCloth(int.parse(cloth['id'].toString()));
                          },
                          child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          s.digitalWardrobe,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary, size: 28),
            tooltip: 'Kıyafet Ekle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              ).then((refreshed) {
                if (refreshed == true) _loadClothes();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filter ──
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppTheme.surfaceDark,
                    selectedColor: AppTheme.accentPurple.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.accentPurple : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.accentPurple : AppTheme.dividerColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Clothes Grid ──
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _clothesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentPurple),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadClothes,
                          child: const Text('Yeniden Dene', style: TextStyle(color: AppTheme.accentPurple)),
                        ),
                      ],
                    ),
                  );
                }

                final allClothes = snapshot.data ?? [];
                final clothes = _selectedCategory == 'Tümü'
                    ? allClothes
                    : allClothes.where((c) {
                        final cat = c['tur']?.toString() ?? c['category']?.toString() ?? '';
                        // Basic fuzzy match for category
                        return cat.toLowerCase().contains(_selectedCategory.toLowerCase().split(' ')[0]);
                      }).toList();

                if (clothes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom_rounded,
                            size: 72, color: AppTheme.textPrimary.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == 'Tümü' ? s.noClothesFound : 'Bu kategoride kıyafet yok',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedCategory == 'Kombinlerim') {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Stack(
                          children: [
                            const Center(child: Icon(Icons.checkroom_rounded, size: 48, color: AppTheme.textMuted)),
                            Positioned(
                              top: 8, right: 8,
                              child: Icon(Icons.bookmark_rounded, color: AppTheme.accentPink, size: 20),
                            ),
                            Positioned(
                              bottom: 12, left: 12,
                              child: Text('Kombin #${index + 1}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: clothes.length,
                  itemBuilder: (context, index) {
                    final cloth = clothes[index] as Map<String, dynamic>;
                    final imageUrl = cloth['foto_url']?.toString() ?? cloth['image_url']?.toString() ?? '';
                    final tur = cloth['tur']?.toString() ?? cloth['category']?.toString() ?? 'Kıyafet';
                    final renk = cloth['renk']?.toString() ?? '';

                    return GestureDetector(
                      onTap: () => _showItemOptions(context, cloth),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dividerColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const _EmptyClothIcon(),
                                    )
                                  : const _EmptyClothIcon(),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: AppTheme.surfaceDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tur,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (renk.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      renk,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
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
        ],
      ),
    );
  }
}

class _EmptyClothIcon extends StatelessWidget {
  const _EmptyClothIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      child: Center(
        child: Icon(Icons.checkroom_rounded, size: 48, color: AppTheme.textPrimary.withValues(alpha: 0.1)),
      ),
    );
  }
}

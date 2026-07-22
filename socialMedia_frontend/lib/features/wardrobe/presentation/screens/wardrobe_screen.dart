import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../services/notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  void _loadClothes() {
    final userId = ref.read(authProvider).currentUserId ?? '';
    setState(() {
      _clothesFuture = _apiService.getClothes(userId).then((clothes) {
        // Temiz kıyafet sayısını kontrol et, az kalırsa bildirim gönder
        NotificationService().checkLowClothesCount(clothes);
        return clothes;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Wardrobe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
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
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _FilterChip(label: 'Favorites'),
                  _FilterChip(label: 'Shirt'),
                  _FilterChip(label: 'T-Shirt'),
                  _FilterChip(label: 'Pants'),
                  _FilterChip(label: 'Jeans'),
                  _FilterChip(label: 'Shoes'),
                  _FilterChip(label: 'Accessories'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _clothesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    );
                  }

                  final clothes = snapshot.data ?? [];
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          '${clothes.length} items',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (clothes.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No clothes found',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: clothes.length,
                            itemBuilder: (context, index) {
                              final cloth = clothes[index] as Map<String, dynamic>;
                              final imageUrl = cloth['foto_url']?.toString() ?? cloth['image_url']?.toString() ?? '';
                              
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditItemScreen(initialItem: cloth),
                                    ),
                                  ).then((refreshed) {
                                    if (refreshed == true) _loadClothes();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.dividerColor),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const _EmptyClothIcon(),
                                        )
                                      : const _EmptyClothIcon(),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
      child: const Center(
        child: Icon(Icons.checkroom_rounded, size: 52, color: AppTheme.textMuted),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

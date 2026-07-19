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
            icon: const Icon(Icons.add_rounded, color: AppTheme.accentViolet, size: 28),
            tooltip: s.isTr ? 'Kıyafet Ekle' : 'Add Clothing',
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
      body: FutureBuilder<List<dynamic>>(
        future: _clothesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentViolet),
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
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadClothes,
                    child: const Text('Retry', style: TextStyle(color: AppTheme.accentViolet)),
                  ),
                ],
              ),
            );
          }

          final clothes = snapshot.data ?? [];
          if (clothes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_rounded,
                      size: 72, color: AppTheme.accentViolet.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    s.noClothesFound,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isTr ? 'Sağ üstteki + butonuyla kıyafet ekleyin' : 'Add clothing using the + button on top right',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: clothes.length,
            itemBuilder: (context, index) {
              final cloth = clothes[index] as Map<String, dynamic>;
              final imageUrl = cloth['foto_url']?.toString() ?? cloth['image_url']?.toString() ?? '';
              final tur = cloth['tur']?.toString() ?? cloth['category']?.toString() ?? 'Clothing';
              final renk = cloth['renk']?.toString() ?? '';

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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor, width: 0.5),
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
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.translateWardrobe(tur),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (renk.isNotEmpty)
                              Text(
                                s.translateWardrobe(renk),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
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

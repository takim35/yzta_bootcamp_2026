import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';
import 'outfits_screen.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.style_rounded, color: Colors.white, size: 28),
                        tooltip: 'Kombinlerim',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OutfitsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddItemScreen()),
                          ).then((refreshed) {
                            if (refreshed == true) _loadClothes();
                          });
                        },
                      ),
                    ],
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded,
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
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
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  final clothes = snapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          '${clothes.length} items',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (clothes.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'No clothes found',
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color ??
                                      Colors.grey),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: clothes.length,
                            itemBuilder: (context, index) {
                              final cloth =
                                  clothes[index] as Map<String, dynamic>;
                              final rawImageUrl =
                                  cloth['foto_url']?.toString() ??
                                      cloth['image_url']?.toString() ??
                                      '';
                              final imageUrl =
                                  ApiService.fixImageUrl(rawImageUrl);

                              final parts = <String>[];
                              if (cloth['renk'] != null &&
                                  cloth['renk'].toString().isNotEmpty)
                                parts.add(cloth['renk'].toString());
                              if (cloth['tur'] != null &&
                                  cloth['tur'].toString().isNotEmpty)
                                parts.add(cloth['tur'].toString());
                              if (cloth['beden'] != null &&
                                  cloth['beden'].toString().isNotEmpty)
                                parts.add(cloth['beden'].toString());
                              final label = parts.join(', ');

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditItemScreen(initialItem: cloth),
                                    ),
                                  ).then((refreshed) {
                                    if (refreshed == true) _loadClothes();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const _EmptyClothIcon(),
                                            )
                                          : const _EmptyClothIcon(),
                                      if (label.isNotEmpty)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.8),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.black54,
                                                      blurRadius: 2)
                                                ],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Icon(Icons.checkroom_rounded,
            size: 52,
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
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

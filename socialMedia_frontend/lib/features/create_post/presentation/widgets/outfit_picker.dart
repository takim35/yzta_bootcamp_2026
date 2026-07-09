import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/feed/domain/models/outfit_item_model.dart';
import '../../../../core/theme/app_theme.dart';

class OutfitPicker extends ConsumerWidget {
  final List<OutfitItem> items;
  final List<OutfitItem> selectedItems;
  final ValueChanged<OutfitItem> onToggle;

  const OutfitPicker({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Kıyafet bulunamadı', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spacingM,
        mainAxisSpacing: AppTheme.spacingM,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item);
        return _OutfitCard(
          item: item,
          isSelected: isSelected,
          onTap: () => onToggle(item),
        );
      },
    );
  }
}

class _OutfitCard extends ConsumerWidget {
  final OutfitItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutfitCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 90,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Semantics(
          label: '${item.category} parçası${isSelected ? ', seçili' : ''}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Image Container ──────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentViolet
                        : AppTheme.dividerColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.accentViolet.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium - 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surfaceDark,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentViolet,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surfaceDark,
                          child: const Icon(
                            Icons.checkroom_rounded,
                            color: AppTheme.textMuted,
                            size: 28,
                          ),
                        ),
                      ),
                      // ─── Selected Overlay ─────────────────────
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentViolet.withValues(alpha: 0.3),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              // ─── Category Label ───────────────────────────────
              Text(
                item.category,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.accentPurple
                      : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

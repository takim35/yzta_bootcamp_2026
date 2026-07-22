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
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
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
      ),
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
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                          color: Theme.of(context).colorScheme.surface,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: const Icon(
                            Icons.checkroom_rounded,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            size: 28,
                          ),
                        ),
                      ),
                      // ─── Selected Overlay ─────────────────────
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
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

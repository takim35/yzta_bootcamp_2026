import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VisibilityOption {
  final String value;
  final String emoji;
  final String label;
  final String description;

  const VisibilityOption({
    required this.value,
    required this.emoji,
    required this.label,
    required this.description,
  });
}

class VisibilitySelector extends ConsumerWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const VisibilitySelector({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  static const List<VisibilityOption> _options = [
    VisibilityOption(
      value: 'public',
      emoji: '🌍',
      label: 'Herkese Açık',
      description: 'Herkes görebilir',
    ),
    VisibilityOption(
      value: 'followers',
      emoji: '👥',
      label: 'Takipçiler',
      description: 'Sadece takipçilerin görebilir',
    ),
    VisibilityOption(
      value: 'private',
      emoji: '🔒',
      label: 'Özel',
      description: 'Sadece sen görebilirsin',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Segmented Buttons ────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: _options.map((option) {
              final isSelected = currentValue == option.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingM,
                      horizontal: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge - 1),
                    ),
                    child: Semantics(
                      label: '${option.label}: ${option.description}',
                      selected: isSelected,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // ─── Description ──────────────────────────────────────
        const SizedBox(height: AppTheme.spacingS),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _options
                .firstWhere((o) => o.value == currentValue)
                .description,
            key: ValueKey(currentValue),
            style: const TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

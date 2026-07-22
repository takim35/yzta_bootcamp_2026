import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EmptyState extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Icon ─────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                semanticLabel: title,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            // ─── Title ────────────────────────────────────────
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            // ─── Subtitle ─────────────────────────────────────
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            // ─── Action Button ────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              Container(
                decoration: AppTheme.gradientButtonDecoration(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAction,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusRound),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXL,
                        vertical: AppTheme.spacingM,
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_shimmer.dart';

/// Feed için shimmer skeleton placeholder
class FeedShimmer extends ConsumerWidget {
  final int itemCount;

  const FeedShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _FeedCardShimmer(),
    );
  }
}

class _FeedCardShimmer extends ConsumerWidget {
  const _FeedCardShimmer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Shimmer ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Avatar
                const CustomShimmer(
                  width: 36,
                  height: 36,
                  isCircle: true,
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Username + time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(
                      width: 100,
                      height: 12,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                    const SizedBox(height: 6),
                    CustomShimmer(
                      width: 60,
                      height: 10,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Image Shimmer ──────────────────────────────────
          const AspectRatio(
            aspectRatio: 4 / 5,
            child: CustomShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          // ─── Actions Shimmer ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CustomShimmer(
                      width: 24,
                      height: 24,
                      isCircle: true,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    CustomShimmer(
                      width: 30,
                      height: 12,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                CustomShimmer(
                  width: double.infinity,
                  height: 12,
                  borderRadius: AppTheme.radiusSmall,
                ),
                const SizedBox(height: 6),
                CustomShimmer(
                  width: 200,
                  height: 12,
                  borderRadius: AppTheme.radiusSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil grid için shimmer skeleton placeholder
class ProfileGridShimmer extends ConsumerWidget {
  final int itemCount;

  const ProfileGridShimmer({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const CustomShimmer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0,
      ),
    );
  }
}

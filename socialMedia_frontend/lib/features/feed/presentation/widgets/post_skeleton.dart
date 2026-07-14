import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_shimmer.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      decoration: AppTheme.glassDecoration(),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Username)
          Row(
            children: [
              const CustomShimmer(width: 40, height: 40, isCircle: true),
              const SizedBox(width: AppTheme.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CustomShimmer(width: 120, height: 16),
                  SizedBox(height: 6),
                  CustomShimmer(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Image placeholder
          const CustomShimmer(width: double.infinity, height: 300, borderRadius: 16),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Action buttons placeholder
          Row(
            children: const [
              CustomShimmer(width: 32, height: 32, isCircle: true),
              SizedBox(width: 16),
              CustomShimmer(width: 32, height: 32, isCircle: true),
              Spacer(),
              CustomShimmer(width: 32, height: 32, isCircle: true),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Caption placeholder
          const CustomShimmer(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          const CustomShimmer(width: 200, height: 14),
        ],
      ),
    );
  }
}

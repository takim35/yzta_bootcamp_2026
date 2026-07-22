import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TryOnComingSoonScreen extends StatelessWidget {
  const TryOnComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentPink, width: 2),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPink, size: 48),
              ),
              const SizedBox(height: 32),
              const Text(
                'Try-On Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'See how clothes fit on you virtually!\nThis feature is coming very soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Text(
                  'Stay Tuned 👀',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

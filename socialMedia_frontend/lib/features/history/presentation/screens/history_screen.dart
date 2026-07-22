import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 64,
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your past outfit choices will appear here.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

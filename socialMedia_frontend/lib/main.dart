import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/main_home_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spot',
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Kaydedilmiş oturum varsa ana ekrana, yoksa onboarding'e yönlendir
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Oturum bilgisi yüklenirken splash göster
    if (auth.isInitializing) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentViolet),
        ),
      );
    }

    // Giriş yapılmışsa ana ekrana git
    if (auth.isLoggedIn) {
      return const MainHomeScreen();
    }

    // Giriş yapılmamışsa onboarding
    return const OnboardingScreen();
  }
}

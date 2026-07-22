import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/navigation/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildirim servisini başlat
  await NotificationService().init();

  // Bildirim izni iste
  await NotificationService().requestPermission();

  // Günlük sabah hatırlatıcısını kur (08:00)
  await NotificationService().scheduleDailyClothesReminder(hour: 8, minute: 0);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Spot',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
      return const MainNavigationScreen();
    }

    // Giriş yapılmamışsa onboarding
    return const OnboardingScreen();
  }
}

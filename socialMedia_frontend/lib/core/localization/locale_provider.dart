import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

/// Riverpod provider for current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.en); // default: English

  void setLocale(AppLocale locale) => state = locale;
  void toggleLocale() =>
      state = state == AppLocale.en ? AppLocale.tr : AppLocale.en;
}

/// Convenience provider — use this in widgets
final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});

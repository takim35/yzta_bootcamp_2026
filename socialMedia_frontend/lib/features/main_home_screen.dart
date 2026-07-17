// Bu dosya, 2FA doğrulaması sonrası yönlendirme için bir köprü sınıftır.
// Gerçek ana ekrana (HomeScreen) yönlendirir.
export '../features/home/home_screen.dart' show HomeScreen;

// MainHomeScreen, HomeScreen'in bir takma adıdır (alias).
// 2FA ekranı bu adı kullanmaktadır.
import 'features/home/home_screen.dart';

typedef MainHomeScreen = HomeScreen;

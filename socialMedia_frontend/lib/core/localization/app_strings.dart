/// Spot App — Localization Strings
/// Default: English. User can switch to Turkish from Profile.

enum AppLocale { en, tr, de, fr, ja, ko, zh }

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  bool get isTr => locale == AppLocale.tr;

  // ── General ──────────────────────────────────────────────────
  String get appName {
    switch (locale) {
      case AppLocale.tr:
        return 'Spot';
      case AppLocale.de:
        return 'Spot';
      case AppLocale.fr:
        return 'Spot';
      case AppLocale.ja:
        return 'Spot';
      case AppLocale.ko:
        return 'Spot';
      case AppLocale.zh:
        return 'Spot';
      case AppLocale.en:
      default:
        return 'Spot';
    }
  }

  // ── Onboarding ───────────────────────────────────────────────
  String get onbWardrobeTitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Dijital\nGardırobun';
      case AppLocale.de:
        return 'Your Digital\nWardrobe';
      case AppLocale.fr:
        return 'Your Digital\nWardrobe';
      case AppLocale.ja:
        return 'Your Digital\nWardrobe';
      case AppLocale.ko:
        return 'Your Digital\nWardrobe';
      case AppLocale.zh:
        return 'Your Digital\nWardrobe';
      case AppLocale.en:
      default:
        return 'Your Digital\nWardrobe';
    }
  }
  String get onbWardrobeSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Tüm kıyafetlerini cebinde taşı, ne giyeceğini düşünme derdinden kurtul.';
      case AppLocale.de:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
      case AppLocale.fr:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
      case AppLocale.ja:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
      case AppLocale.ko:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
      case AppLocale.zh:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
      case AppLocale.en:
      default:
        return 'Carry your entire closet in your pocket. Never wonder what to wear again.';
    }
  }

  String get onbARTitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Sanal\nDeneme Kabini';
      case AppLocale.de:
        return 'Virtual\nTry-On';
      case AppLocale.fr:
        return 'Virtual\nTry-On';
      case AppLocale.ja:
        return 'Virtual\nTry-On';
      case AppLocale.ko:
        return 'Virtual\nTry-On';
      case AppLocale.zh:
        return 'Virtual\nTry-On';
      case AppLocale.en:
      default:
        return 'Virtual\nTry-On';
    }
  }
  String get onbARSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Sanal deneme kabinimizle kıyafetleri giymeden önce üstünde gör.';
      case AppLocale.de:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
      case AppLocale.fr:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
      case AppLocale.ja:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
      case AppLocale.ko:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
      case AppLocale.zh:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
      case AppLocale.en:
      default:
        return 'Try outfits virtually with our virtual try-on mirror before you wear them.';
    }
  }

  String get onbAITitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Yapay Zeka\nStilist Asistanı';
      case AppLocale.de:
        return 'AI Stylist\nAssistant';
      case AppLocale.fr:
        return 'AI Stylist\nAssistant';
      case AppLocale.ja:
        return 'AI Stylist\nAssistant';
      case AppLocale.ko:
        return 'AI Stylist\nAssistant';
      case AppLocale.zh:
        return 'AI Stylist\nAssistant';
      case AppLocale.en:
      default:
        return 'AI Stylist\nAssistant';
    }
  }
  String get onbAISub {
    switch (locale) {
      case AppLocale.tr:
        return 'Yapay zeka destekli kişiselleştirilmiş kombin önerileri al.';
      case AppLocale.de:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
      case AppLocale.fr:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
      case AppLocale.ja:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
      case AppLocale.ko:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
      case AppLocale.zh:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
      case AppLocale.en:
      default:
        return 'Get personalized outfit recommendations powered by artificial intelligence.';
    }
  }

  String get onbSocialTitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Toplulukla\nPaylaş';
      case AppLocale.de:
        return 'Share with\nthe Community';
      case AppLocale.fr:
        return 'Share with\nthe Community';
      case AppLocale.ja:
        return 'Share with\nthe Community';
      case AppLocale.ko:
        return 'Share with\nthe Community';
      case AppLocale.zh:
        return 'Share with\nthe Community';
      case AppLocale.en:
      default:
        return 'Share with\nthe Community';
    }
  }
  String get onbSocialSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Tarzını sergile, trendleri keşfet ve diğerlerinden ilham al.';
      case AppLocale.de:
        return 'Showcase your style, discover trends, and get inspired by others.';
      case AppLocale.fr:
        return 'Showcase your style, discover trends, and get inspired by others.';
      case AppLocale.ja:
        return 'Showcase your style, discover trends, and get inspired by others.';
      case AppLocale.ko:
        return 'Showcase your style, discover trends, and get inspired by others.';
      case AppLocale.zh:
        return 'Showcase your style, discover trends, and get inspired by others.';
      case AppLocale.en:
      default:
        return 'Showcase your style, discover trends, and get inspired by others.';
    }
  }

  String get skip {
    switch (locale) {
      case AppLocale.tr:
        return 'Geç';
      case AppLocale.de:
        return 'Skip';
      case AppLocale.fr:
        return 'Skip';
      case AppLocale.ja:
        return 'Skip';
      case AppLocale.ko:
        return 'Skip';
      case AppLocale.zh:
        return 'Skip';
      case AppLocale.en:
      default:
        return 'Skip';
    }
  }
  String get next {
    switch (locale) {
      case AppLocale.tr:
        return 'İleri';
      case AppLocale.de:
        return 'Next';
      case AppLocale.fr:
        return 'Next';
      case AppLocale.ja:
        return 'Next';
      case AppLocale.ko:
        return 'Next';
      case AppLocale.zh:
        return 'Next';
      case AppLocale.en:
      default:
        return 'Next';
    }
  }
  String get letsGo {
    switch (locale) {
      case AppLocale.tr:
        return 'Başlayalım\' : "Let\'s Go";

  // ── Auth ─────────────────────────────────────────────────────
  String get welcomeBack => isTr ? \'Tekrar Hoş Geldin';
      case AppLocale.de:
        return 'Welcome back';
      case AppLocale.fr:
        return 'Welcome back';
      case AppLocale.ja:
        return 'Welcome back';
      case AppLocale.ko:
        return 'Welcome back';
      case AppLocale.zh:
        return 'Welcome back';
      case AppLocale.en:
      default:
        return 'Welcome back';
    }
  }
  String get signInToSpot => isTr ? "Spot'a Giriş Yap" : 'Sign in to Spot';
  String get emailAddress {
    switch (locale) {
      case AppLocale.tr:
        return 'E-posta Adresi';
      case AppLocale.de:
        return 'Email address';
      case AppLocale.fr:
        return 'Email address';
      case AppLocale.ja:
        return 'Email address';
      case AppLocale.ko:
        return 'Email address';
      case AppLocale.zh:
        return 'Email address';
      case AppLocale.en:
      default:
        return 'Email address';
    }
  }
  String get password {
    switch (locale) {
      case AppLocale.tr:
        return 'Şifre';
      case AppLocale.de:
        return 'Password';
      case AppLocale.fr:
        return 'Password';
      case AppLocale.ja:
        return 'Password';
      case AppLocale.ko:
        return 'Password';
      case AppLocale.zh:
        return 'Password';
      case AppLocale.en:
      default:
        return 'Password';
    }
  }
  String get forgotPassword {
    switch (locale) {
      case AppLocale.tr:
        return 'Şifremi Unuttum';
      case AppLocale.de:
        return 'Forgot password?';
      case AppLocale.fr:
        return 'Forgot password?';
      case AppLocale.ja:
        return 'Forgot password?';
      case AppLocale.ko:
        return 'Forgot password?';
      case AppLocale.zh:
        return 'Forgot password?';
      case AppLocale.en:
      default:
        return 'Forgot password?';
    }
  }
  String get signIn {
    switch (locale) {
      case AppLocale.tr:
        return 'Giriş Yap';
      case AppLocale.de:
        return 'Sign In';
      case AppLocale.fr:
        return 'Sign In';
      case AppLocale.ja:
        return 'Sign In';
      case AppLocale.ko:
        return 'Sign In';
      case AppLocale.zh:
        return 'Sign In';
      case AppLocale.en:
      default:
        return 'Sign In';
    }
  }
  String get noAccount {
    switch (locale) {
      case AppLocale.tr:
        return 'Hesabın yok mu?\' : "Don\'t have an account?";
  String get signUp => isTr ? \'Kayıt Ol';
      case AppLocale.de:
        return 'Sign up';
      case AppLocale.fr:
        return 'Sign up';
      case AppLocale.ja:
        return 'Sign up';
      case AppLocale.ko:
        return 'Sign up';
      case AppLocale.zh:
        return 'Sign up';
      case AppLocale.en:
      default:
        return 'Sign up';
    }
  }
  String get haveAccount {
    switch (locale) {
      case AppLocale.tr:
        return 'Zaten hesabın var mı?';
      case AppLocale.de:
        return 'Already have an account?';
      case AppLocale.fr:
        return 'Already have an account?';
      case AppLocale.ja:
        return 'Already have an account?';
      case AppLocale.ko:
        return 'Already have an account?';
      case AppLocale.zh:
        return 'Already have an account?';
      case AppLocale.en:
      default:
        return 'Already have an account?';
    }
  }
  String get createAccount {
    switch (locale) {
      case AppLocale.tr:
        return 'Hesap Oluştur';
      case AppLocale.de:
        return 'Create Account';
      case AppLocale.fr:
        return 'Create Account';
      case AppLocale.ja:
        return 'Create Account';
      case AppLocale.ko:
        return 'Create Account';
      case AppLocale.zh:
        return 'Create Account';
      case AppLocale.en:
      default:
        return 'Create Account';
    }
  }
  String get joinSpot => isTr ? "Spot'a Katıl" : 'Join Spot';
  String get username {
    switch (locale) {
      case AppLocale.tr:
        return 'Kullanıcı Adı';
      case AppLocale.de:
        return 'Username';
      case AppLocale.fr:
        return 'Username';
      case AppLocale.ja:
        return 'Username';
      case AppLocale.ko:
        return 'Username';
      case AppLocale.zh:
        return 'Username';
      case AppLocale.en:
      default:
        return 'Username';
    }
  }
  String get register {
    switch (locale) {
      case AppLocale.tr:
        return 'Kayıt Ol';
      case AppLocale.de:
        return 'Register';
      case AppLocale.fr:
        return 'Register';
      case AppLocale.ja:
        return 'Register';
      case AppLocale.ko:
        return 'Register';
      case AppLocale.zh:
        return 'Register';
      case AppLocale.en:
      default:
        return 'Register';
    }
  }
  String get pleaseEnterEmail {
    switch (locale) {
      case AppLocale.tr:
        return 'Lütfen e-posta adresinizi girin';
      case AppLocale.de:
        return 'Please enter your email';
      case AppLocale.fr:
        return 'Please enter your email';
      case AppLocale.ja:
        return 'Please enter your email';
      case AppLocale.ko:
        return 'Please enter your email';
      case AppLocale.zh:
        return 'Please enter your email';
      case AppLocale.en:
      default:
        return 'Please enter your email';
    }
  }
  String get invalidEmail {
    switch (locale) {
      case AppLocale.tr:
        return 'Sadece @gmail.com, @hotmail.com veya @outlook.com kullanılabilir';
      case AppLocale.de:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
      case AppLocale.fr:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
      case AppLocale.ja:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
      case AppLocale.ko:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
      case AppLocale.zh:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
      case AppLocale.en:
      default:
        return 'Only @gmail.com, @hotmail.com or @outlook.com';
    }
  }
  String get pleaseEnterPassword {
    switch (locale) {
      case AppLocale.tr:
        return 'Lütfen şifrenizi girin';
      case AppLocale.de:
        return 'Please enter your password';
      case AppLocale.fr:
        return 'Please enter your password';
      case AppLocale.ja:
        return 'Please enter your password';
      case AppLocale.ko:
        return 'Please enter your password';
      case AppLocale.zh:
        return 'Please enter your password';
      case AppLocale.en:
      default:
        return 'Please enter your password';
    }
  }
  String get loginFailed {
    switch (locale) {
      case AppLocale.tr:
        return 'Giriş yapılamadı, lütfen bilgilerinizi kontrol edin.';
      case AppLocale.de:
        return 'Login failed. Please check your credentials.';
      case AppLocale.fr:
        return 'Login failed. Please check your credentials.';
      case AppLocale.ja:
        return 'Login failed. Please check your credentials.';
      case AppLocale.ko:
        return 'Login failed. Please check your credentials.';
      case AppLocale.zh:
        return 'Login failed. Please check your credentials.';
      case AppLocale.en:
      default:
        return 'Login failed. Please check your credentials.';
    }
  }

  // ── Main Home ────────────────────────────────────────────────
  String get mainSubtitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Dijital tarzına yön ver.';
      case AppLocale.de:
        return 'Define your digital style.';
      case AppLocale.fr:
        return 'Define your digital style.';
      case AppLocale.ja:
        return 'Define your digital style.';
      case AppLocale.ko:
        return 'Define your digital style.';
      case AppLocale.zh:
        return 'Define your digital style.';
      case AppLocale.en:
      default:
        return 'Define your digital style.';
    }
  }
  String get wardrobe {
    switch (locale) {
      case AppLocale.tr:
        return 'Gardırop';
      case AppLocale.de:
        return 'Wardrobe';
      case AppLocale.fr:
        return 'Wardrobe';
      case AppLocale.ja:
        return 'Wardrobe';
      case AppLocale.ko:
        return 'Wardrobe';
      case AppLocale.zh:
        return 'Wardrobe';
      case AppLocale.en:
      default:
        return 'Wardrobe';
    }
  }
  String get wardrobeSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Kıyafetlerini yönet';
      case AppLocale.de:
        return 'Manage your clothes';
      case AppLocale.fr:
        return 'Manage your clothes';
      case AppLocale.ja:
        return 'Manage your clothes';
      case AppLocale.ko:
        return 'Manage your clothes';
      case AppLocale.zh:
        return 'Manage your clothes';
      case AppLocale.en:
      default:
        return 'Manage your clothes';
    }
  }
  String get aiStylist {
    switch (locale) {
      case AppLocale.tr:
        return 'AI Stilist';
      case AppLocale.de:
        return 'AI Stylist';
      case AppLocale.fr:
        return 'AI Stylist';
      case AppLocale.ja:
        return 'AI Stylist';
      case AppLocale.ko:
        return 'AI Stylist';
      case AppLocale.zh:
        return 'AI Stylist';
      case AppLocale.en:
      default:
        return 'AI Stylist';
    }
  }
  String get aiStylistSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Yapay zeka önerileri';
      case AppLocale.de:
        return 'AI powered looks';
      case AppLocale.fr:
        return 'AI powered looks';
      case AppLocale.ja:
        return 'AI powered looks';
      case AppLocale.ko:
        return 'AI powered looks';
      case AppLocale.zh:
        return 'AI powered looks';
      case AppLocale.en:
      default:
        return 'AI powered looks';
    }
  }
  String get arMirror {
    switch (locale) {
      case AppLocale.tr:
        return 'Sanal Deneme';
      case AppLocale.de:
        return 'Virtual Try On';
      case AppLocale.fr:
        return 'Virtual Try On';
      case AppLocale.ja:
        return 'Virtual Try On';
      case AppLocale.ko:
        return 'Virtual Try On';
      case AppLocale.zh:
        return 'Virtual Try On';
      case AppLocale.en:
      default:
        return 'Virtual Try On';
    }
  }
  String get arMirrorSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Sanal deneme kabini';
      case AppLocale.de:
        return 'Virtual fitting room';
      case AppLocale.fr:
        return 'Virtual fitting room';
      case AppLocale.ja:
        return 'Virtual fitting room';
      case AppLocale.ko:
        return 'Virtual fitting room';
      case AppLocale.zh:
        return 'Virtual fitting room';
      case AppLocale.en:
      default:
        return 'Virtual fitting room';
    }
  }
  String get social {
    switch (locale) {
      case AppLocale.tr:
        return 'Sosyal';
      case AppLocale.de:
        return 'Social';
      case AppLocale.fr:
        return 'Social';
      case AppLocale.ja:
        return 'Social';
      case AppLocale.ko:
        return 'Social';
      case AppLocale.zh:
        return 'Social';
      case AppLocale.en:
      default:
        return 'Social';
    }
  }
  String get socialSub {
    switch (locale) {
      case AppLocale.tr:
        return 'Toplulukla paylaş';
      case AppLocale.de:
        return 'Share with community';
      case AppLocale.fr:
        return 'Share with community';
      case AppLocale.ja:
        return 'Share with community';
      case AppLocale.ko:
        return 'Share with community';
      case AppLocale.zh:
        return 'Share with community';
      case AppLocale.en:
      default:
        return 'Share with community';
    }
  }
  String get comingSoon {
    switch (locale) {
      case AppLocale.tr:
        return 'Yakında';
      case AppLocale.de:
        return 'Coming Soon';
      case AppLocale.fr:
        return 'Coming Soon';
      case AppLocale.ja:
        return 'Coming Soon';
      case AppLocale.ko:
        return 'Coming Soon';
      case AppLocale.zh:
        return 'Coming Soon';
      case AppLocale.en:
      default:
        return 'Coming Soon';
    }
  }

  // ── Feed ────────────────────────────────────────────────────
  String get feed {
    switch (locale) {
      case AppLocale.tr:
        return 'Akış';
      case AppLocale.de:
        return 'Feed';
      case AppLocale.fr:
        return 'Feed';
      case AppLocale.ja:
        return 'Feed';
      case AppLocale.ko:
        return 'Feed';
      case AppLocale.zh:
        return 'Feed';
      case AppLocale.en:
      default:
        return 'Feed';
    }
  }
  String get noPostsYet {
    switch (locale) {
      case AppLocale.tr:
        return 'Henüz gönderi yok';
      case AppLocale.de:
        return 'Noch keine Beiträge';
      case AppLocale.fr:
        return 'Aucune publication';
      case AppLocale.ja:
        return '投稿はまだありません';
      case AppLocale.ko:
        return '아직 게시물이 없습니다';
      case AppLocale.zh:
        return '还没有帖子';
      case AppLocale.en:
      default:
        return 'No posts yet';
    }
  }
  String get followPeopleHint {
    switch (locale) {
      case AppLocale.tr:
        return 'Birileri takip et veya ilk gönderiyi oluştur!';
      case AppLocale.de:
        return 'Follow people or create the first post!';
      case AppLocale.fr:
        return 'Follow people or create the first post!';
      case AppLocale.ja:
        return 'Follow people or create the first post!';
      case AppLocale.ko:
        return 'Follow people or create the first post!';
      case AppLocale.zh:
        return 'Follow people or create the first post!';
      case AppLocale.en:
      default:
        return 'Follow people or create the first post!';
    }
  }
  String get errorLoading {
    switch (locale) {
      case AppLocale.tr:
        return 'Yükleme başarısız';
      case AppLocale.de:
        return 'Failed to load';
      case AppLocale.fr:
        return 'Failed to load';
      case AppLocale.ja:
        return 'Failed to load';
      case AppLocale.ko:
        return 'Failed to load';
      case AppLocale.zh:
        return 'Failed to load';
      case AppLocale.en:
      default:
        return 'Failed to load';
    }
  }
  String get retry {
    switch (locale) {
      case AppLocale.tr:
        return 'Tekrar Dene';
      case AppLocale.de:
        return 'Wiederholen';
      case AppLocale.fr:
        return 'Réessayer';
      case AppLocale.ja:
        return '再試行';
      case AppLocale.ko:
        return '다시 시도';
      case AppLocale.zh:
        return '重试';
      case AppLocale.en:
      default:
        return 'Retry';
    }
  }

  // ── Create Post ──────────────────────────────────────────────
  String get newPost {
    switch (locale) {
      case AppLocale.tr:
        return 'Yeni Paylaşım';
      case AppLocale.de:
        return 'Neuer Beitrag';
      case AppLocale.fr:
        return 'Nouveau Post';
      case AppLocale.ja:
        return '新規投稿';
      case AppLocale.ko:
        return '새 게시물';
      case AppLocale.zh:
        return '新帖子';
      case AppLocale.en:
      default:
        return 'New Post';
    }
  }
  String get photo {
    switch (locale) {
      case AppLocale.tr:
        return '📸 Fotoğraf';
      case AppLocale.de:
        return '📸 Photo';
      case AppLocale.fr:
        return '📸 Photo';
      case AppLocale.ja:
        return '📸 Photo';
      case AppLocale.ko:
        return '📸 Photo';
      case AppLocale.zh:
        return '📸 Photo';
      case AppLocale.en:
      default:
        return '📸 Photo';
    }
  }
  String get outfitPieces {
    switch (locale) {
      case AppLocale.tr:
        return '👗 Kombin Parçaları';
      case AppLocale.de:
        return '👗 Outfit Pieces';
      case AppLocale.fr:
        return '👗 Outfit Pieces';
      case AppLocale.ja:
        return '👗 Outfit Pieces';
      case AppLocale.ko:
        return '👗 Outfit Pieces';
      case AppLocale.zh:
        return '👗 Outfit Pieces';
      case AppLocale.en:
      default:
        return '👗 Outfit Pieces';
    }
  }
  String get caption {
    switch (locale) {
      case AppLocale.tr:
        return '✏️ Açıklama';
      case AppLocale.de:
        return '✏️ Caption';
      case AppLocale.fr:
        return '✏️ Caption';
      case AppLocale.ja:
        return '✏️ Caption';
      case AppLocale.ko:
        return '✏️ Caption';
      case AppLocale.zh:
        return '✏️ Caption';
      case AppLocale.en:
      default:
        return '✏️ Caption';
    }
  }
  String get privacy {
    switch (locale) {
      case AppLocale.tr:
        return '🔐 Gizlilik';
      case AppLocale.de:
        return '🔐 Privacy';
      case AppLocale.fr:
        return '🔐 Privacy';
      case AppLocale.ja:
        return '🔐 Privacy';
      case AppLocale.ko:
        return '🔐 Privacy';
      case AppLocale.zh:
        return '🔐 Privacy';
      case AppLocale.en:
      default:
        return '🔐 Privacy';
    }
  }
  String get aiConsent {
    switch (locale) {
      case AppLocale.tr:
        return 'Bu görsel, modelin gelişmesi için kullanılabilir';
      case AppLocale.de:
        return 'This image may be used to improve our AI model';
      case AppLocale.fr:
        return 'This image may be used to improve our AI model';
      case AppLocale.ja:
        return 'This image may be used to improve our AI model';
      case AppLocale.ko:
        return 'This image may be used to improve our AI model';
      case AppLocale.zh:
        return 'This image may be used to improve our AI model';
      case AppLocale.en:
      default:
        return 'This image may be used to improve our AI model';
    }
  }
  String get share {
    switch (locale) {
      case AppLocale.tr:
        return 'Paylaş';
      case AppLocale.de:
        return 'Teilen';
      case AppLocale.fr:
        return 'Partager';
      case AppLocale.ja:
        return 'シェア';
      case AppLocale.ko:
        return '공유';
      case AppLocale.zh:
        return '分享';
      case AppLocale.en:
      default:
        return 'Share';
    }
  }
  String get close {
    switch (locale) {
      case AppLocale.tr:
        return 'Kapat';
      case AppLocale.de:
        return 'Schließen';
      case AppLocale.fr:
        return 'Fermer';
      case AppLocale.ja:
        return '閉じる';
      case AppLocale.ko:
        return '닫기';
      case AppLocale.zh:
        return '关闭';
      case AppLocale.en:
      default:
        return 'Close';
    }
  }
  String get pickFromGallery {
    switch (locale) {
      case AppLocale.tr:
        return 'Galeriden Seç';
      case AppLocale.de:
        return 'Pick from Gallery';
      case AppLocale.fr:
        return 'Pick from Gallery';
      case AppLocale.ja:
        return 'Pick from Gallery';
      case AppLocale.ko:
        return 'Pick from Gallery';
      case AppLocale.zh:
        return 'Pick from Gallery';
      case AppLocale.en:
      default:
        return 'Pick from Gallery';
    }
  }
  String get pickHint {
    switch (locale) {
      case AppLocale.tr:
        return 'Kombinini paylaşmak için bir fotoğraf seç';
      case AppLocale.de:
        return 'Pick a photo to share your outfit';
      case AppLocale.fr:
        return 'Pick a photo to share your outfit';
      case AppLocale.ja:
        return 'Pick a photo to share your outfit';
      case AppLocale.ko:
        return 'Pick a photo to share your outfit';
      case AppLocale.zh:
        return 'Pick a photo to share your outfit';
      case AppLocale.en:
      default:
        return 'Pick a photo to share your outfit';
    }
  }
  String get change {
    switch (locale) {
      case AppLocale.tr:
        return 'Değiştir';
      case AppLocale.de:
        return 'Change';
      case AppLocale.fr:
        return 'Change';
      case AppLocale.ja:
        return 'Change';
      case AppLocale.ko:
        return 'Change';
      case AppLocale.zh:
        return 'Change';
      case AppLocale.en:
      default:
        return 'Change';
    }
  }
  String get captionHint {
    switch (locale) {
      case AppLocale.tr:
        return 'Kombinin hakkında bir şeyler yaz...';
      case AppLocale.de:
        return 'Write something about your outfit...';
      case AppLocale.fr:
        return 'Write something about your outfit...';
      case AppLocale.ja:
        return 'Write something about your outfit...';
      case AppLocale.ko:
        return 'Write something about your outfit...';
      case AppLocale.zh:
        return 'Write something about your outfit...';
      case AppLocale.en:
      default:
        return 'Write something about your outfit...';
    }
  }
  String get aiSuggest {
    switch (locale) {
      case AppLocale.tr:
        return '✨ AI Öneri Al';
      case AppLocale.de:
        return '✨ AI Suggest';
      case AppLocale.fr:
        return '✨ AI Suggest';
      case AppLocale.ja:
        return '✨ AI Suggest';
      case AppLocale.ko:
        return '✨ AI Suggest';
      case AppLocale.zh:
        return '✨ AI Suggest';
      case AppLocale.en:
      default:
        return '✨ AI Suggest';
    }
  }
  String get suggesting {
    switch (locale) {
      case AppLocale.tr:
        return 'Öneri alınıyor...';
      case AppLocale.de:
        return 'Suggesting...';
      case AppLocale.fr:
        return 'Suggesting...';
      case AppLocale.ja:
        return 'Suggesting...';
      case AppLocale.ko:
        return 'Suggesting...';
      case AppLocale.zh:
        return 'Suggesting...';
      case AppLocale.en:
      default:
        return 'Suggesting...';
    }
  }
  String get sharedSuccess {
    switch (locale) {
      case AppLocale.tr:
        return 'Paylaşım başarıyla oluşturuldu! 🎉';
      case AppLocale.de:
        return 'Post shared successfully! 🎉';
      case AppLocale.fr:
        return 'Post shared successfully! 🎉';
      case AppLocale.ja:
        return 'Post shared successfully! 🎉';
      case AppLocale.ko:
        return 'Post shared successfully! 🎉';
      case AppLocale.zh:
        return 'Post shared successfully! 🎉';
      case AppLocale.en:
      default:
        return 'Post shared successfully! 🎉';
    }
  }

  // ── Profile ──────────────────────────────────────────────────
  String get profile {
    switch (locale) {
      case AppLocale.tr:
        return 'Profil';
      case AppLocale.de:
        return 'Profile';
      case AppLocale.fr:
        return 'Profile';
      case AppLocale.ja:
        return 'Profile';
      case AppLocale.ko:
        return 'Profile';
      case AppLocale.zh:
        return 'Profile';
      case AppLocale.en:
      default:
        return 'Profile';
    }
  }
  String get posts {
    switch (locale) {
      case AppLocale.tr:
        return 'Gönderi';
      case AppLocale.de:
        return 'Beiträge';
      case AppLocale.fr:
        return 'Publications';
      case AppLocale.ja:
        return '投稿';
      case AppLocale.ko:
        return '게시물';
      case AppLocale.zh:
        return '帖子';
      case AppLocale.en:
      default:
        return 'Posts';
    }
  }
  String get followers {
    switch (locale) {
      case AppLocale.tr:
        return 'Takipçi';
      case AppLocale.de:
        return 'Followers';
      case AppLocale.fr:
        return 'Abonnés';
      case AppLocale.ja:
        return 'フォロワー';
      case AppLocale.ko:
        return '팔로워';
      case AppLocale.zh:
        return '关注者';
      case AppLocale.en:
      default:
        return 'Followers';
    }
  }
  String get following {
    switch (locale) {
      case AppLocale.tr:
        return 'Takip';
      case AppLocale.de:
        return 'Folgt';
      case AppLocale.fr:
        return 'Abonnements';
      case AppLocale.ja:
        return 'フォロー中';
      case AppLocale.ko:
        return '팔로잉';
      case AppLocale.zh:
        return '正在关注';
      case AppLocale.en:
      default:
        return 'Following';
    }
  }
  String get editProfile {
    switch (locale) {
      case AppLocale.tr:
        return 'Profili Düzenle';
      case AppLocale.de:
        return 'Profil bearbeiten';
      case AppLocale.fr:
        return 'Modifier le profil';
      case AppLocale.ja:
        return 'プロフィール編集';
      case AppLocale.ko:
        return '프로필 편집';
      case AppLocale.zh:
        return '编辑资料';
      case AppLocale.en:
      default:
        return 'Edit Profile';
    }
  }
  String get shareProfile {
    switch (locale) {
      case AppLocale.tr:
        return 'Profili Paylaş';
      case AppLocale.de:
        return 'Profil teilen';
      case AppLocale.fr:
        return 'Partager le profil';
      case AppLocale.ja:
        return 'プロフィール共有';
      case AppLocale.ko:
        return '프로필 공유';
      case AppLocale.zh:
        return '分享资料';
      case AppLocale.en:
      default:
        return 'Share Profile';
    }
  }
  String get logout {
    switch (locale) {
      case AppLocale.tr:
        return 'Çıkış Yap';
      case AppLocale.de:
        return 'Abmelden';
      case AppLocale.fr:
        return 'Déconnexion';
      case AppLocale.ja:
        return 'ログアウト';
      case AppLocale.ko:
        return '로그아웃';
      case AppLocale.zh:
        return '登出';
      case AppLocale.en:
      default:
        return 'Sign Out';
    }
  }
  String get language {
    switch (locale) {
      case AppLocale.tr:
        return 'Dil';
      case AppLocale.de:
        return 'Sprache';
      case AppLocale.fr:
        return 'Langue';
      case AppLocale.ja:
        return '言語';
      case AppLocale.ko:
        return '언어';
      case AppLocale.zh:
        return '语言';
      case AppLocale.en:
      default:
        return 'Language';
    }
  }
  String get languageTitle {
    switch (locale) {
      case AppLocale.tr:
        return 'Uygulama Dili';
      case AppLocale.de:
        return 'App-Sprache';
      case AppLocale.fr:
        return 'Langue de l\'app';
      case AppLocale.ja:
        return 'アプリの言語';
      case AppLocale.ko:
        return '앱 언어';
      case AppLocale.zh:
        return '应用语言';
      case AppLocale.en:
      default:
        return 'App Language';
    }
  }
  String get english {
    switch (locale) {
      case AppLocale.tr:
        return 'English';
      case AppLocale.de:
        return 'Englisch';
      case AppLocale.fr:
        return 'Anglais';
      case AppLocale.ja:
        return '英語';
      case AppLocale.ko:
        return '영어';
      case AppLocale.zh:
        return '英语';
      case AppLocale.en:
      default:
        return 'English';
    }
  }
  String get turkish {
    switch (locale) {
      case AppLocale.tr:
        return 'Türkçe';
      case AppLocale.de:
        return 'Türkisch';
      case AppLocale.fr:
        return 'Turc';
      case AppLocale.ja:
        return 'トルコ語';
      case AppLocale.ko:
        return '터키어';
      case AppLocale.zh:
        return '土耳其语';
      case AppLocale.en:
      default:
        return 'Türkçe';
    }
  }

  // ── Navigation ───────────────────────────────────────────────
  String get navFeed {
    switch (locale) {
      case AppLocale.tr:
        return 'Akış';
      case AppLocale.de:
        return 'Feed';
      case AppLocale.fr:
        return 'Flux';
      case AppLocale.ja:
        return 'フィード';
      case AppLocale.ko:
        return '피드';
      case AppLocale.zh:
        return '动态';
      case AppLocale.en:
      default:
        return 'Feed';
    }
  }
  String get navCreate {
    switch (locale) {
      case AppLocale.tr:
        return 'Oluştur';
      case AppLocale.de:
        return 'Erstellen';
      case AppLocale.fr:
        return 'Créer';
      case AppLocale.ja:
        return '作成';
      case AppLocale.ko:
        return '만들기';
      case AppLocale.zh:
        return '创建';
      case AppLocale.en:
      default:
        return 'Create';
    }
  }
  String get navProfile {
    switch (locale) {
      case AppLocale.tr:
        return 'Profil';
      case AppLocale.de:
        return 'Profil';
      case AppLocale.fr:
        return 'Profil';
      case AppLocale.ja:
        return 'プロフィール';
      case AppLocale.ko:
        return '프로필';
      case AppLocale.zh:
        return '个人资料';
      case AppLocale.en:
      default:
        return 'Profile';
    }
  }

  // ── Comments / Likes / Save ──────────────────────────────────
  String get viewAllComments {
    switch (locale) {
      case AppLocale.tr:
        return ' yorumun tümünü gör';
      case AppLocale.de:
        return ' view all comments';
      case AppLocale.fr:
        return ' view all comments';
      case AppLocale.ja:
        return ' view all comments';
      case AppLocale.ko:
        return ' view all comments';
      case AppLocale.zh:
        return ' view all comments';
      case AppLocale.en:
      default:
        return ' view all comments';
    }
  }
  String get save {
    switch (locale) {
      case AppLocale.tr:
        return 'Kaydet';
      case AppLocale.de:
        return 'Speichern';
      case AppLocale.fr:
        return 'Enregistrer';
      case AppLocale.ja:
        return '保存';
      case AppLocale.ko:
        return '저장';
      case AppLocale.zh:
        return '保存';
      case AppLocale.en:
      default:
        return 'Save';
    }
  }
  String get unsave {
    switch (locale) {
      case AppLocale.tr:
        return 'Kaydedilenlerden Çıkar';
      case AppLocale.de:
        return 'Unsave';
      case AppLocale.fr:
        return 'Unsave';
      case AppLocale.ja:
        return 'Unsave';
      case AppLocale.ko:
        return 'Unsave';
      case AppLocale.zh:
        return 'Unsave';
      case AppLocale.en:
      default:
        return 'Unsave';
    }
  }

  // ── Wardrobe & AI Stylist ────────────────────────────────────
  String get digitalWardrobe {
    switch (locale) {
      case AppLocale.tr:
        return 'Dijital Gardırop';
      case AppLocale.de:
        return 'Digital Wardrobe';
      case AppLocale.fr:
        return 'Digital Wardrobe';
      case AppLocale.ja:
        return 'Digital Wardrobe';
      case AppLocale.ko:
        return 'Digital Wardrobe';
      case AppLocale.zh:
        return 'Digital Wardrobe';
      case AppLocale.en:
      default:
        return 'Digital Wardrobe';
    }
  }
  String get noClothesFound {
    switch (locale) {
      case AppLocale.tr:
        return 'Henüz kıyafet yok. Biraz ekle!';
      case AppLocale.de:
        return 'No clothes found. Add some!';
      case AppLocale.fr:
        return 'No clothes found. Add some!';
      case AppLocale.ja:
        return 'No clothes found. Add some!';
      case AppLocale.ko:
        return 'No clothes found. Add some!';
      case AppLocale.zh:
        return 'No clothes found. Add some!';
      case AppLocale.en:
      default:
        return 'No clothes found. Add some!';
    }
  }
  String get askForSuggestions {
    switch (locale) {
      case AppLocale.tr:
        return 'Kombin önerisi iste...';
      case AppLocale.de:
        return 'Ask for outfit suggestions...';
      case AppLocale.fr:
        return 'Ask for outfit suggestions...';
      case AppLocale.ja:
        return 'Ask for outfit suggestions...';
      case AppLocale.ko:
        return 'Ask for outfit suggestions...';
      case AppLocale.zh:
        return 'Ask for outfit suggestions...';
      case AppLocale.en:
      default:
        return 'Ask for outfit suggestions...';
    }
  }
  String get cannotGenerateResponse {
    switch (locale) {
      case AppLocale.tr:
        return 'Yanıt oluşturulamadı.';
      case AppLocale.de:
        return 'I could not generate a response.';
      case AppLocale.fr:
        return 'I could not generate a response.';
      case AppLocale.ja:
        return 'I could not generate a response.';
      case AppLocale.ko:
        return 'I could not generate a response.';
      case AppLocale.zh:
        return 'I could not generate a response.';
      case AppLocale.en:
      default:
        return 'I could not generate a response.';
    }
  }

  String translateWardrobe(String val) {
    if (isTr) return val;
    final map = {
      'Tişör': 'T-Shirt',
      'Tişört': 'T-Shirt',
      'Gömlek': 'Shirt',
      'Bluz': 'Blouse',
      'Kazak': 'Sweater',
      'Sweatshirt': 'Sweatshirt',
      'Pantolon': 'Trousers',
      'Şort': 'Shorts',
      'Etek': 'Skirt',
      'Elbise': 'Dress',
      'Ceket': 'Jacket',
      'Mont': 'Coat',
      'Kaban': 'Overcoat',
      'Ayakkabı': 'Shoes',
      'Bot': 'Boots',
      'Sneaker': 'Sneaker',
      'Çanta': 'Bag',
      'Aksesuar': 'Accessory',
      'Diğer': 'Other',
      'Üst Giyim': 'Top Wear',
      'Alt Giyim': 'Bottom Wear',
      'Dış Giyim': 'Outerwear',
      'Siyah': 'Black',
      'Beyaz': 'White',
      'Gri': 'Grey',
      'Lacivert': 'Navy Blue',
      'Mavi': 'Blue',
      'Kırmızı': 'Red',
      'Pembe': 'Pink',
      'Yeşil': 'Green',
      'Sarı': 'Yellow',
      'Turuncu': 'Orange',
      'Mor': 'Purple',
      'Kahverengi': 'Brown',
      'Bej': 'Beige',
      'Bordo': 'Burgundy',
      'Karışık': 'Mixed',
      'Çok Renkli': 'Multicolor',
      'Yaz': 'Summer',
      'Kış': 'Winter',
      'İlkbahar': 'Spring',
      'Sonbahar': 'Autumn',
      'Tüm Sezon': 'All Seasons',
    };
    return map[val] ?? val;
  }
}


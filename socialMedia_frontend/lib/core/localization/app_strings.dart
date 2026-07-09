/// Spot App — Localization Strings
/// Default: English. User can switch to Turkish from Profile.

enum AppLocale { en, tr }

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  bool get isTr => locale == AppLocale.tr;

  // ── General ──────────────────────────────────────────────────
  String get appName => 'Spot';

  // ── Onboarding ───────────────────────────────────────────────
  String get onbWardrobeTitle => isTr ? 'Dijital\nGardırobun' : 'Your Digital\nWardrobe';
  String get onbWardrobeSub => isTr
      ? 'Tüm kıyafetlerini cebinde taşı, ne giyeceğini düşünme derdinden kurtul.'
      : 'Carry your entire closet in your pocket. Never wonder what to wear again.';

  String get onbARTitle => isTr ? 'Sanal\nDeneme Kabini' : 'Virtual\nTry-On';
  String get onbARSub => isTr
      ? 'Sanal deneme kabinimizle kıyafetleri giymeden önce üstünde gör.'
      : 'Try outfits virtually with our virtual try-on mirror before you wear them.';

  String get onbAITitle => isTr ? 'Yapay Zeka\nStilist Asistanı' : 'AI Stylist\nAssistant';
  String get onbAISub => isTr
      ? 'Yapay zeka destekli kişiselleştirilmiş kombin önerileri al.'
      : 'Get personalized outfit recommendations powered by artificial intelligence.';

  String get onbSocialTitle => isTr ? 'Toplulukla\nPaylaş' : 'Share with\nthe Community';
  String get onbSocialSub => isTr
      ? 'Tarzını sergile, trendleri keşfet ve diğerlerinden ilham al.'
      : 'Showcase your style, discover trends, and get inspired by others.';

  String get skip => isTr ? 'Geç' : 'Skip';
  String get next => isTr ? 'İleri' : 'Next';
  String get letsGo => isTr ? 'Başlayalım' : "Let's Go";

  // ── Auth ─────────────────────────────────────────────────────
  String get welcomeBack => isTr ? 'Tekrar Hoş Geldin' : 'Welcome back';
  String get signInToSpot => isTr ? "Spot'a Giriş Yap" : 'Sign in to Spot';
  String get emailAddress => isTr ? 'E-posta Adresi' : 'Email address';
  String get password => isTr ? 'Şifre' : 'Password';
  String get forgotPassword => isTr ? 'Şifremi Unuttum' : 'Forgot password?';
  String get signIn => isTr ? 'Giriş Yap' : 'Sign In';
  String get noAccount => isTr ? 'Hesabın yok mu?' : "Don't have an account?";
  String get signUp => isTr ? 'Kayıt Ol' : 'Sign up';
  String get haveAccount => isTr ? 'Zaten hesabın var mı?' : 'Already have an account?';
  String get createAccount => isTr ? 'Hesap Oluştur' : 'Create Account';
  String get joinSpot => isTr ? "Spot'a Katıl" : 'Join Spot';
  String get username => isTr ? 'Kullanıcı Adı' : 'Username';
  String get register => isTr ? 'Kayıt Ol' : 'Register';
  String get pleaseEnterEmail => isTr ? 'Lütfen e-posta adresinizi girin' : 'Please enter your email';
  String get invalidEmail => isTr
      ? 'Sadece @gmail.com, @hotmail.com veya @outlook.com kullanılabilir'
      : 'Only @gmail.com, @hotmail.com or @outlook.com';
  String get pleaseEnterPassword => isTr ? 'Lütfen şifrenizi girin' : 'Please enter your password';
  String get loginFailed => isTr
      ? 'Giriş yapılamadı, lütfen bilgilerinizi kontrol edin.'
      : 'Login failed. Please check your credentials.';

  // ── Main Home ────────────────────────────────────────────────
  String get mainSubtitle => isTr ? 'Dijital tarzına yön ver.' : 'Define your digital style.';
  String get homeWelcomeBack => isTr ? 'Tekrar hoş geldin, ' : 'Welcome back, ';
  String get homeWhatToWear => isTr ? 'Bugün ne giysek?' : 'What to wear today?';
  String get homeWhatToWearSub => isTr ? 'Sana özel önerilere göz at' : 'Check out your personalized outfits';
  String get wardrobe => isTr ? 'Gardırop' : 'Wardrobe';
  String get wardrobeSub => isTr ? 'Kıyafetlerini yönet' : 'Manage your clothes';
  String get aiStylist => isTr ? 'AI Stilist' : 'AI Stylist';
  String get aiStylistSub => isTr ? 'Yapay zeka önerileri' : 'AI powered looks';
  String get arMirror => isTr ? 'Sanal Deneme' : 'Virtual Try On';
  String get arMirrorSub => isTr ? 'Sanal deneme kabini' : 'Virtual fitting room';
  String get social => isTr ? 'Sosyal' : 'Social';
  String get socialSub => isTr ? 'Toplulukla paylaş' : 'Share with community';
  String get comingSoon => isTr ? 'Yakında' : 'Coming Soon';

  // ── Feed ────────────────────────────────────────────────────
  String get feed => isTr ? 'Akış' : 'Feed';
  String get noPostsYet => isTr ? 'Henüz gönderi yok' : 'No posts yet';
  String get followPeopleHint => isTr
      ? 'Birileri takip et veya ilk gönderiyi oluştur!'
      : 'Follow people or create the first post!';
  String get errorLoading => isTr ? 'Yükleme başarısız' : 'Failed to load';
  String get retry => isTr ? 'Tekrar Dene' : 'Retry';

  // ── Create Post ──────────────────────────────────────────────
  String get newPost => isTr ? 'Yeni Paylaşım' : 'New Post';
  String get photo => isTr ? '📸 Fotoğraf' : '📸 Photo';
  String get outfitPieces => isTr ? '👗 Kombin Parçaları' : '👗 Outfit Pieces';
  String get caption => isTr ? '✏️ Açıklama' : '✏️ Caption';
  String get privacy => isTr ? '🔐 Gizlilik' : '🔐 Privacy';
  String get aiConsent => isTr
      ? 'Bu görsel, modelin gelişmesi için kullanılabilir'
      : 'This image may be used to improve our AI model';
  String get share => isTr ? 'Paylaş' : 'Share';
  String get close => isTr ? 'Kapat' : 'Close';
  String get pickFromGallery => isTr ? 'Galeriden Seç' : 'Pick from Gallery';
  String get pickHint => isTr
      ? 'Kombinini paylaşmak için bir fotoğraf seç'
      : 'Pick a photo to share your outfit';
  String get change => isTr ? 'Değiştir' : 'Change';
  String get captionHint => isTr
      ? 'Kombinin hakkında bir şeyler yaz...'
      : 'Write something about your outfit...';
  String get aiSuggest => isTr ? '✨ AI Öneri Al' : '✨ AI Suggest';
  String get suggesting => isTr ? 'Öneri alınıyor...' : 'Suggesting...';
  String get sharedSuccess => isTr
      ? 'Paylaşım başarıyla oluşturuldu! 🎉'
      : 'Post shared successfully! 🎉';

  // ── Profile ──────────────────────────────────────────────────
  String get profile => isTr ? 'Profil' : 'Profile';
  String get posts => isTr ? 'Gönderi' : 'Posts';
  String get followers => isTr ? 'Takipçi' : 'Followers';
  String get following => isTr ? 'Takip' : 'Following';
  String get editProfile => isTr ? 'Profili Düzenle' : 'Edit Profile';
  String get shareProfile => isTr ? 'Profili Paylaş' : 'Share Profile';
  String get logout => isTr ? 'Çıkış Yap' : 'Sign Out';
  String get language => isTr ? 'Dil' : 'Language';
  String get languageTitle => isTr ? 'Uygulama Dili' : 'App Language';
  String get english => 'English';
  String get turkish => 'Türkçe';

  // ── Navigation ───────────────────────────────────────────────
  String get navFeed => isTr ? 'Akış' : 'Feed';
  String get navCreate => isTr ? 'Oluştur' : 'Create';
  String get navProfile => isTr ? 'Profil' : 'Profile';

  // ── Comments / Likes / Save ──────────────────────────────────
  String get viewAllComments => isTr ? ' yorumun tümünü gör' : ' view all comments';
  String get save => isTr ? 'Kaydet' : 'Save';
  String get unsave => isTr ? 'Kaydedilenlerden Çıkar' : 'Unsave';

  // ── Wardrobe & AI Stylist ────────────────────────────────────
  String get digitalWardrobe => isTr ? 'Dijital Gardırop' : 'Digital Wardrobe';
  String get noClothesFound => isTr ? 'Henüz kıyafet yok. Biraz ekle!' : 'No clothes found. Add some!';
  String get askForSuggestions => isTr ? 'Kombin önerisi iste...' : 'Ask for outfit suggestions...';
  String get cannotGenerateResponse => isTr ? 'Yanıt oluşturulamadı.' : 'I could not generate a response.';
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../providers/auth_provider.dart';

/// 2FA Kurulum ve Doğrulama Ekranı
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isEnabled = false;
  String? _secret;
  String? _otpauthUri;
  String? _errorMessage;

  late AnimationController _entryController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _setup2FA();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _setup2FA() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await TwoFAApiService().setup(userId);
      setState(() {
        _secret = result['secret'] as String?;
        _otpauthUri = result['otpauth_uri'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '2FA kurulumu başlatılamadı: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verify() async {
    final userId = ref.read(authProvider).currentUserId;
    if (userId == null) return;

    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = '6 haneli kodu girin.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });

    try {
      await TwoFAApiService().verify(userId, code);
      setState(() => _isEnabled = true);
    } catch (e) {
      final msg = e.toString().contains('ApiException')
          ? e.toString().split('ApiException: ').last.split(' (status:').first
          : 'Kod doğrulanamadı.';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _copySecret() {
    if (_secret != null) {
      Clipboard.setData(ClipboardData(text: _secret!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secret kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
            color:
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
        title: const Text(
          'İki Faktörlü Doğrulama',
          style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary),
              )
            : _isEnabled
                ? _buildSuccessView()
                : SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildSetupView(),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 28),
            const Text(
              '2FA Etkinleştirildi!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hesabınız artık iki faktörlü doğrulamayla korunuyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey,
                  fontSize: 15),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Google Authenticator veya Authy uygulamasıyla QR kodu tarayın.',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.grey,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── QR Kodu ───────────────────────────────
          if (_otpauthUri != null) ...[
            const Text(
              '1. QR Kodu Tarayın',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _otpauthUri!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Manuel Secret ─────────────────────
            const Text(
              'QR tarayamıyor musunuz? Manuel olarak girin:',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey,
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _copySecret,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _secret ?? '',
                        style: const TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Icon(Icons.copy_rounded,
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey,
                        size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // ── Kod Girişi ────────────────────────────
          const Text(
            '2. Doğrulama Kodunu Girin',
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Authenticator uygulamasındaki 6 haneli kodu girin.',
            style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 13),
          ),
          const SizedBox(height: 16),

          // ── Hata kutusu ──────────────────────────
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ),
          ],

          // ── 6 haneli kod ─────────────────────────
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey,
                  letterSpacing: 8,
                  fontSize: 22),
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Doğrula Butonu ────────────────────────
          GestureDetector(
            onTap: _isVerifying ? null : _verify,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                gradient: _isVerifying ? null : AppTheme.primaryGradient,
                color:
                    _isVerifying ? Theme.of(context).colorScheme.surface : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isVerifying
                    ? []
                    : [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Doğrula ve Etkinleştir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 2FA için API çağrıları — ApiService'i genişletir
class TwoFAApiService {
  final _api = ApiService();

  Future<Map<String, dynamic>> setup(String userId) async {
    return await _api.post2FA('/auth/2fa/setup?user_id=$userId', {});
  }

  Future<void> verify(String userId, String code) async {
    await _api.post2FA('/auth/2fa/verify', {
      'user_id': userId,
      'code': code,
    });
  }

  Future<void> disable(String userId) async {
    await _api.delete2FA('/auth/2fa/disable?user_id=$userId');
  }

  Future<Map<String, dynamic>> getStatus(String userId) async {
    return await _api.get2FAStatus('/auth/2fa/status?user_id=$userId');
  }
}

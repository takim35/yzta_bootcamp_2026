import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _success = false;
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
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().resetPassword(
        _emailController.text.trim(),
        _newPasswordController.text,
      );
      if (mounted) {
        setState(() => _success = true);
      }
    } catch (e) {
      final msg = e.toString().contains('ApiException')
          ? e.toString().split('ApiException: ').last.split(' (status:').first
          : 'Şifre sıfırlanırken bir hata oluştu.';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          'Şifremi Sıfırla',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _success ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
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
                color: AppTheme.accentViolet.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 28),
        const Text(
          'Şifreniz Sıfırlandı!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Yeni şifrenizle giriş yapabilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Giriş Ekranına Dön',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── İkon ─────────────────────────────────
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentViolet.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Şifrenizi Sıfırlayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'E-posta adresinizi ve yeni şifrenizi girin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 36),

          // ── Hata kutusu ──────────────────────────
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── E-posta ──────────────────────────────
          _buildTextField(
            controller: _emailController,
            hintText: 'E-posta Adresi',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Lütfen e-posta adresinizi girin.';
              if (!v.contains('@')) return 'Geçerli bir e-posta adresi girin.';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Yeni Şifre ───────────────────────────
          _buildTextField(
            controller: _newPasswordController,
            hintText: 'Yeni Şifre',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isVisible: _isNewPasswordVisible,
            onToggleVisibility: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Yeni şifrenizi girin.';
              if (v.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Şifre Tekrar ─────────────────────────
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Şifreyi Tekrar Girin',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifrenizi tekrar girin.';
              if (v != _newPasswordController.text) return 'Şifreler eşleşmiyor.';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Gönder Butonu ─────────────────────────
          GestureDetector(
            onTap: _isLoading ? null : _onSubmit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppTheme.primaryGradient,
                color: _isLoading ? AppTheme.surfaceDark : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: AppTheme.accentViolet.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.accentViolet,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Şifremi Sıfırla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accentViolet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
      ),
    );
  }
}

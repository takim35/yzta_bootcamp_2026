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
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1;
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
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRequestCode() async {
    setState(() => _errorMessage = null);
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'Geçerli bir e-posta adresi girin.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().requestPasswordResetCode(_emailController.text.trim());
      if (mounted) setState(() => _currentStep = 2);
    } catch (e) {
      final msg = e.toString().contains('ApiException')
          ? e.toString().split('ApiException: ').last.split(' (status:').first
          : 'Kod gönderilirken bir hata oluştu.';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onVerifyCode() async {
    setState(() => _errorMessage = null);
    if (_codeController.text.trim().length < 4) {
      setState(() => _errorMessage = 'Lütfen geçerli bir kod girin.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().verifyResetCode(_emailController.text.trim(), _codeController.text.trim());
      if (mounted) setState(() => _currentStep = 3);
    } catch (e) {
      final msg = e.toString().contains('ApiException')
          ? e.toString().split('ApiException: ').last.split(' (status:').first
          : 'Kod doğrulanırken bir hata oluştu.';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSubmitNewPassword() async {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
        title: const Text(
          'Şifremi Sıfırla',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, fontWeight: FontWeight.w700),
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
                child: _success ? _buildSuccessState() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 80,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Başarılı!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          'Şifreniz başarıyla güncellendi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Giriş Yap',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Şifrenizi Sıfırlayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _currentStep == 1 
                ? 'E-posta adresinize bir sıfırlama kodu göndereceğiz.'
                : _currentStep == 2
                    ? 'E-postanıza gelen 6 haneli kodu girin.'
                    : 'Yeni şifrenizi belirleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 36),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_currentStep == 1) ...[
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
            const SizedBox(height: 28),
            _buildButton('Kodu Gönder', _onRequestCode),
          ] else if (_currentStep == 2) ...[
            _buildTextField(
              controller: _codeController,
              hintText: '6 Haneli Kod',
              icon: Icons.lock_clock_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),
            _buildButton('Kodu Doğrula', _onVerifyCode),
          ] else if (_currentStep == 3) ...[
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
            _buildButton('Şifreyi Yenile', _onSubmitNewPassword),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : AppTheme.primaryGradient,
          color: _isLoading ? Theme.of(context).colorScheme.surface : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
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
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 15),
        prefixIcon: Icon(icon, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
        ),
      ),
    );
  }
}

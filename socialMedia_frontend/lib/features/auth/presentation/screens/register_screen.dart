import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../core/navigation/main_navigation_screen.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmailDomain(String email) {
    final validDomains = ['@gmail.com', '@hotmail.com', '@outlook.com'];
    return validDomains.any((d) => email.toLowerCase().endsWith(d));
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#%^&*(),.?":{}|<>\-_$]'))) return false;
    return true;
  }

  Future<void> _onRegisterTap() async {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authProv = ref.read(authProvider);

      try {
        await authProv.register(email, password);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainNavigationScreen()),
            (route) => false,
          );
        }
      } on ApiException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } catch (_) {
        setState(() {
          _errorMessage = ref.read(stringsProvider).isTr
              ? 'Kayıt işlemi başarısız, lütfen bilgilerinizi kontrol edin.'
              : 'Registration failed, please check your information.';
        });
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final success = await ref.read(authProvider).loginWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      final msg = e.toString().contains('ApiException')
          ? e.toString().split('ApiException: ').last.split(' (status:').first
          : 'Google ile giriş başarısız oldu.';
      if (mounted) setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.joinSpot,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    s.isTr
                        ? 'Aramıza katıl ve gardırobunu dijitalleştir'
                        : 'Join us and digitize your wardrobe',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXXL),

                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  _buildTextField(
                    controller: _emailController,
                    hintText: s.emailAddress,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.pleaseEnterEmail;
                      }
                      if (!_isValidEmailDomain(value)) {
                        return s.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingL),

                  _buildTextField(
                    controller: _passwordController,
                    hintText: s.password,
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.pleaseEnterPassword;
                      }
                      if (!_isValidPassword(value)) {
                        return s.isTr
                            ? 'Şifreniz kurallara uymuyor.'
                            : 'Password does not meet requirements.';
                      }
                      return null;
                    },
                  ),

                  // Şifre kuralları bilgilendirme metni
                  Padding(
                    padding: EdgeInsets.only(
                        top: AppTheme.spacingS, bottom: AppTheme.spacingL),
                    child: Text(
                      s.isTr
                          ? 'Şifreniz en az 8 karakter uzunluğunda olmalı; en az bir büyük harf, bir rakam ve bir sembol (!@#\$%^&*) içermelidir.'
                          : 'Password must be at least 8 characters long, containing at least one uppercase letter, one digit, and one symbol (!@#\$%^&*).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.grey.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ),

                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: s.isTr ? 'Şifre Tekrar' : 'Confirm Password',
                    icon: Icons.lock_reset_rounded,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.isTr
                            ? 'Lütfen şifrenizi tekrar girin'
                            : 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return s.isTr
                            ? 'Şifreler birbiriyle uyuşmuyor'
                            : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingXXL),

                  // Kayıt butonu
                  GestureDetector(
                    onTap: _isLoading ? null : _onRegisterTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : AppTheme.primaryGradient,
                        color: _isLoading
                            ? Theme.of(context).colorScheme.surface
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                s.signUp,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // ── Google ile Kayıt ──────────────────────────
                  GestureDetector(
                    onTap: _isLoading ? null : _onGoogleSignIn,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            s.isTr
                                ? 'Google ile Devam Et'
                                : 'Continue with Google',
                            style: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
        prefixIcon: Icon(icon,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

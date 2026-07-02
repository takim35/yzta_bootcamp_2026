import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/api_service.dart';
import '../../../main_home_screen.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _ProfileHeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.dividerColor,
    );
  }
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
            MaterialPageRoute(builder: (_) => const MainHomeScreen()),
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.joinSpot,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    s.isTr
                        ? 'Aramıza katıl ve gardırobunu dijitalleştir'
                        : 'Join us and digitize your wardrobe',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor),
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
                  const SizedBox(height: AppTheme.spacingL),
                  
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
                    padding: const EdgeInsets.only(top: AppTheme.spacingS, bottom: AppTheme.spacingL),
                    child: Text(
                      s.isTr
                          ? 'Şifreniz en az 8 karakter uzunluğunda olmalı; en az bir büyük harf, bir rakam ve bir sembol (!@#\$%^&*) içermelidir.'
                          : 'Password must be at least 8 characters long, containing at least one uppercase letter, one digit, and one symbol (!@#\$%^&*).',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
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
                        return s.isTr ? 'Lütfen şifrenizi tekrar girin' : 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return s.isTr ? 'Şifreler birbiriyle uyuşmuyor' : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  GestureDetector(
                    onTap: _isLoading ? null : _onRegisterTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : AppTheme.primaryGradient,
                        color: _isLoading ? AppTheme.surfaceDark : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: AppTheme.accentViolet.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
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
                            : Text(
                                s.signUp,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentViolet),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
    );
  }
}

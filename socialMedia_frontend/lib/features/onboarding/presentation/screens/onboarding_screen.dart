import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../services/analytics_service.dart';

import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _getPages(AppStrings s) => [
    {
      'title': s.onbWardrobeTitle,
      'subtitle': s.onbWardrobeSub,
      'icon': Icons.checkroom_rounded,
      'color': const Color(0xFF7C3AED),
      'bgIcon': Icons.style_rounded,
    },
    {
      'title': s.onbARTitle,
      'subtitle': s.onbARSub,
      'icon': Icons.camera_enhance_rounded,
      'color': const Color(0xFFDB2777),
      'bgIcon': Icons.view_in_ar_rounded,
    },
    {
      'title': s.onbAITitle,
      'subtitle': s.onbAISub,
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF0EA5E9),
      'bgIcon': Icons.psychology_rounded,
    },
    {
      'title': s.onbSocialTitle,
      'subtitle': s.onbSocialSub,
      'icon': Icons.diversity_3_rounded,
      'color': const Color(0xFF10B981),
      'bgIcon': Icons.group_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Log first step viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logOnboardingStep(0, 'Wardrobe Intro');
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    AnalyticsService().logOnboardingStep(index, 'Step $index');
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _showPermissionPrompt() async {
    final s = ref.read(stringsProvider);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.isTr ? 'İzinler Gerekli' : 'Permissions Required',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          s.isTr 
              ? 'Dijital Gardrop deneyimini tam anlamıyla yaşayabilmen için kamerana ve fotoğraf galerine erişim iznine ihtiyacımız var. (Kıyafetlerini yükleyebilmen için)' 
              : 'To fully experience Digital Wardrobe, we need access to your camera and photo gallery. (So you can upload your clothes)',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AnalyticsService().logEvent('permission_prompt_skipped');
              _finishOnboarding();
            },
            child: Text(s.isTr ? 'Atla' : 'Skip', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              AnalyticsService().logEvent('permission_prompt_accepted');
              // Request permissions
              await [
                Permission.camera,
                Permission.photos,
                // On Android 13+ we need photos, but on older we need storage
                Permission.storage,
              ].request();
              _finishOnboarding();
            },
            child: Text(s.isTr ? 'İzin Ver' : 'Allow', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() {
    AnalyticsService().logOnboardingCompleted();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onNext(List<Map<String, dynamic>> pages) {
    if (_currentPage == pages.length - 1) {
      _showPermissionPrompt();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onSkip() {
    AnalyticsService().logOnboardingSkipped(_currentPage);
    _showPermissionPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final pages = _getPages(s);
    final page = pages[_currentPage];
    final color = page['color'] as Color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated background blobs
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) {
              return Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -60,
                    child: Transform.rotate(
                      angle: _rotateController.value * 2 * math.pi,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withValues(alpha: 0.25),
                              color.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -80,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Faint large background icon
          Positioned(
            top: size.height * 0.08,
            right: -20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: 0.04,
              child: Icon(
                page['bgIcon'] as IconData,
                size: 220,
                color: Colors.white,
              ),
            ),
          ),

          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _currentPage < pages.length - 1
                    ? TextButton(
                        onPressed: _onSkip,
                        child: Text(
                          s.skip,
                          style: const TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),

                  // Spot wordmark
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: const Text(
                      'SPOT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Floating icon
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                color.withValues(alpha: 0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Page content via PageView (text only)
                  SizedBox(
                    height: size.height * 0.25,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final p = pages[index];
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SingleChildScrollView(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                p['title'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                p['subtitle'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Dots + Next button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dots
                        Row(
                          children: List.generate(
                            pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 6),
                              height: 8,
                              width: _currentPage == i ? 28 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == i
                                    ? color
                                    : Theme.of(context).dividerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        // Next / Get Started button
                        GestureDetector(
                          onTap: () => _onNext(pages),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  _currentPage == pages.length - 1 ? 28 : 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.75)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == pages.length - 1
                                      ? s.letsGo
                                      : s.next,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Dijital Gardırobuna Hoş Geldin',
      'description': 'Tüm kıyafetlerini cebinde taşı, ne giyeceğini düşünme derdinden kurtul.',
      'icon': 'checkroom',
    },
    {
      'title': 'Kombinlerini Paylaş',
      'description': 'Kendi tarzını yarat ve diğer kullanıcıların kombinlerinden ilham al.',
      'icon': 'diversity_1',
    },
    {
      'title': 'Yapay Zeka Asistanı',
      'description': 'Hava durumuna ve tarzına en uygun kıyafetleri saniyeler içinde önerelim.',
      'icon': 'auto_awesome',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextTap() {
    if (_currentPage == _onboardingData.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return _buildPage(
                title: _onboardingData[index]['title']!,
                description: _onboardingData[index]['description']!,
                icon: _onboardingData[index]['icon']!,
              );
            },
          ),
          Positioned(
            bottom: AppTheme.spacingXXL,
            left: AppTheme.spacingL,
            right: AppTheme.spacingL,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPageIndicator(),
                _buildNextButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String description, required String icon}) {
    IconData iconData;
    switch (icon) {
      case 'checkroom':
        iconData = Icons.checkroom_rounded;
        break;
      case 'diversity_1':
        iconData = Icons.diversity_1_rounded;
        break;
      case 'auto_awesome':
        iconData = Icons.auto_awesome_rounded;
        break;
      default:
        iconData = Icons.star_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXXL),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentViolet.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXXL),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      children: List.generate(
        _onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppTheme.accentViolet : AppTheme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == _onboardingData.length - 1;
    
    return GestureDetector(
      onTap: _onNextTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isLastPage ? 32 : 24,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentViolet.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Başlayın' : 'İleri',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isLastPage) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

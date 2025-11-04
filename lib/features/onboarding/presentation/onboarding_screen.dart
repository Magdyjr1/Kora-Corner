import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/game_on_theme.dart';
import '../../../core/utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Kora Corner',
      description:
      'Test your football knowledge with exciting quiz challenges and compete with friends!',
    ),
    OnboardingPage(
      title: 'Multiple Challenge Types',
      description:
      'Play Bank, Password, Risk, and many more unique football quiz formats designed for ultimate fun.',
    ),
    OnboardingPage(
      title: 'Compete & Learn',
      description:
      'Track your progress, earn points, and discover interesting facts about football while having fun!',
    ),
  ];



  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KoraCornerColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // ✅ Expanded يحل مشكلة الـ RenderBox
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return ResponsivePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/word.png',
            height: Responsive.getAvatarSize(context) * 2.0,
          ),
          SizedBox(height: Responsive.getSpacing(context) * 3),
          ResponsiveText(
            page.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: KoraCornerColors.textPrimary,
              fontSize: Responsive.getTitleSize(context) * 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.getSpacing(context) * 1.5),
          ResponsiveText(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: KoraCornerColors.textSecondary,
              height: 1.5,
              fontSize: Responsive.getBodySize(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return ResponsivePadding(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
                  (index) => Container(
                margin: EdgeInsets.symmetric(
                    horizontal: Responsive.getSpacing(context) * 0.25),
                width: _currentPage == index
                    ? Responsive.getSpacing(context) * 1.5
                    : Responsive.getSpacing(context) * 0.5,
                height: Responsive.getSpacing(context) * 0.5,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? KoraCornerColors.primaryGreen
                      : KoraCornerColors.textSecondary,
                  borderRadius: BorderRadius.circular(
                      Responsive.getSpacing(context) * 0.25),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context) * 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  context.go('/login');
                }
              },
              style: KoraCornerTheme.primaryButtonStyle.copyWith(
                backgroundColor: MaterialStateProperty.all(KoraCornerColors.primaryGreen),
              ),
              child: ResponsiveText(
                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Skip',
                style: TextStyle(color: KoraCornerColors.primaryGreen),
                ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;

  OnboardingPage({
    required this.title,
    required this.description,
  });
}

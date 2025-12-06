import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../ads/banner_ad_widget.dart';

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
      title: 'مرحبًا بك في كورة كورنر',
      description:
      'اختبر معرفتك الكروية من خلال تحديات وأسئلة مثيرة وتنافس مع أصدقائك!',
      icon: Icons.sports_soccer,
      color: AppColors.gameOnGreen,
      showImage: true,
    ),
    OnboardingPage(
      title: 'أنواع متعددة من التحديات',
      description:
      'استمتع بأنماط لعب مختلفة مثل بنك، باسورد، ريسك، وغيرها من اختبارات كرة القدم الفريدة والممتعة!',
      icon: Icons.quiz,
      color: AppColors.brightGold,
      showImage: false,
    ),
    OnboardingPage(
      title: 'تنافس وتعلّم',
      description:
      'تابع تقدمك، اجمع النقاط، واكتشف حقائق شيقة عن كرة القدم أثناء استمتاعك باللعب!',
      icon: Icons.emoji_events,
      color: AppColors.gameOnGreen,
      showImage: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
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
              const BannerAdWidget(),
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
          page.showImage
              ? Image.asset(
            'assets/images/word.png',
            height: Responsive.getAvatarSize(context) * 2.4,
          )
              : Container(
            width: Responsive.getAvatarSize(context) * 2.4,
            height: Responsive.getAvatarSize(context) * 2.4,
            decoration: BoxDecoration(
              color: page.color,
              borderRadius: BorderRadius.circular(
                  Responsive.getAvatarSize(context) * 1.2),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: Responsive.getAvatarSize(context) * 1.2,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context) * 3),
          ResponsiveText(
            page.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              fontSize: Responsive.getTitleSize(context) * 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.getSpacing(context) * 1.5),
          ResponsiveText(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.lightGrey,
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
                      ? AppColors.gameOnGreen
                      : AppColors.grey,
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
                  _completeOnboarding();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    vertical: Responsive.getSpacing(context)),
              ),
              child: ResponsiveText(
                _currentPage < _pages.length - 1 ? 'التالي' : 'ابدأ الآن',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('تخطي'),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool showImage;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.showImage,
  });
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_on_theme.dart';
import '../../../ads/banner_ad_widget.dart';

// Supabase client
final supabase = Supabase.instance.client;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isBankGameLoading = false;

  final List<CategoryItem> _categories = const [
    CategoryItem(
      name: 'بنك',
      icon: Icons.account_balance,
      color: KoraCornerColors.primaryGreen,
      route: '/bank',
    ),
    CategoryItem(
      name: 'ريسك',
      icon: Icons.warning,
      color: AppColors.brightGold,
      route: '/risk-challenge',
    ),
    CategoryItem(
      name: 'اهبد صح',
      icon: Icons.gps_fixed,
      color: KoraCornerColors.primaryGreen,
      route: '/GuessRightScreen',
    ),
    CategoryItem(
      name: 'اوفسايد',
      icon: Icons.block,
      color: AppColors.brightGold,
      route: '/OffsideChallengeScreen',
    ),
    CategoryItem(
      name: 'باسورد',
      icon: Icons.lock,
      color: KoraCornerColors.primaryGreen,
      route: '/password',
    ),
    CategoryItem(
      name: 'أنا مين',
      icon: Icons.help,
      color: AppColors.brightGold,
      route: '/who-am-i',
    ),
    CategoryItem(
      name: 'توب 10',
      icon: Icons.format_list_numbered,
      color: KoraCornerColors.primaryGreen,
      route: '/top-10',
    ),
    CategoryItem(
      name: 'مين ف الصورة',
      icon: Icons.image,
      color: AppColors.brightGold,
      route: '/who-is-in-picture',
    ),
    CategoryItem(
      name: 'X O',
      icon: Icons.close,
      color: KoraCornerColors.primaryGreen,
      route: '/XOXOChallengeScreen',
    ),
  ];

  Future<void> _loadAndStartBankGame() async {
    if (_isBankGameLoading) return;

    setState(() {
      _isBankGameLoading = true;
    });

    try {
      print('🔍 Starting to load bank questions...');

      // Direct query from bank table
      final response = await supabase
          .from('bank')
          .select('*')
          .limit(1000);

      print('📦 Response type: ${response.runtimeType}');
      print('📦 Response length: ${response.length}');

      if (!mounted) return;

      if (response.isEmpty) {
        _showErrorSnackBar(
          'الجدول فاضي! محتاج تضيف أسئلة في جدول bank',
        );
        print('❌ No questions found in bank table');
        return;
      }

      // Check if we have the required fields
      final firstItem = response.first;
      if (!firstItem.containsKey('question_text') ||
          !firstItem.containsKey('correct_answer')) {
        _showErrorSnackBar(
          'الأعمدة غلط! لازم يكون في question_text و correct_answer',
        );
        print('❌ Missing required fields: $firstItem');
        return;
      }

      // Shuffle and take 72 questions
      final shuffled = List.from(response)..shuffle();
      final questions = shuffled.take(72).toList();

      print('✅ Loaded ${questions.length} questions');

      if (questions.length < 72) {
        _showErrorSnackBar(
          'محتاج 72 سؤال على الأقل. موجود حالياً ${questions.length}',
        );
        return;
      }

      // Navigate with questions
      if (mounted) {
        print('🚀 Navigating to bank screen...');
        context.go('/bank', extra: questions);
      }
    } on PostgrestException catch (e) {
      print('❌ PostgrestException: ${e.message}');
      print('   Code: ${e.code}');
      print('   Details: ${e.details}');
      print('   Hint: ${e.hint}');

      if (mounted) {
        String errorMsg = 'خطأ في قاعدة البيانات';

        if (e.message.contains('permission denied') ||
            e.message.contains('not found')) {
          errorMsg = 'مفيش صلاحية للوصول للجدول. تأكد من RLS Policies';
        } else if (e.message.contains('relation') &&
            e.message.contains('does not exist')) {
          errorMsg = 'الجدول مش موجود! تأكد إن الاسم "bank"';
        }

        _showErrorSnackBar('$errorMsg\n${e.message}');
      }
    } catch (e, stackTrace) {
      print('❌ General Error: $e');
      print('   Stack: $stackTrace');

      if (mounted) {
        _showErrorSnackBar('حصل خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBankGameLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('Challenge Categories'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(context, category);
                  },
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem category) {
    final isThisCardLoading = category.route == '/bank' && _isBankGameLoading;

    return GestureDetector(
      onTap: isThisCardLoading
          ? null
          : () {
        if (category.route == '/bank') {
          _loadAndStartBankGame();
        } else if (category.route == '/offside' ||
            category.route == '/x-or-o') {
          _showComingSoonDialog(context, category.name);
        } else {
          context.go(category.route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                color: AppColors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isThisCardLoading
                        ? 'جاري التحميل...'
                        : 'اضغط للبدء',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isThisCardLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: category.color,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '$categoryName Challenge',
          style: const TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'هذا التحدي قريباً! ترقبوا المزيد من التحديات المثيرة.',
          style: TextStyle(color: AppColors.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'حسناً',
              style: TextStyle(color: KoraCornerColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final String route;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.route,
  });
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_on_theme.dart'; // Import the new theme

// Supabase client
final supabase = Supabase.instance.client;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Loading state for the Bank game specifically
  bool _isBankGameLoading = false;

  final List<CategoryItem> _categories = const [
    CategoryItem(
      name: 'بنك',
      icon: Icons.account_balance,
      color: KoraCornerColors.primaryGreen, // Corrected color
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
      color: KoraCornerColors.primaryGreen, // Corrected color
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
      color: KoraCornerColors.primaryGreen, // Corrected color
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
      color: KoraCornerColors.primaryGreen, // Corrected color
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
      color: KoraCornerColors.primaryGreen, // Corrected color
      route: '/XOXOChallengeScreen',
    ),
  ];

  // This function loads data for the Bank game and then navigates
  Future<void> _loadAndStartBankGame() async {
    setState(() {
      _isBankGameLoading = true;
    });

    try {
      final response = await supabase.rpc(
        'get_bank_questions',
        params: {'p_count': 72}, // Corrected parameter name
      );

      if (mounted && response is List) {
        if (response.isNotEmpty) {
          context.go('/bank', extra: response);
        } else {
          _showErrorSnackBar('Failed to load questions. The server returned an empty list.');
        }
      } else {
         _showErrorSnackBar('Failed to load questions. Invalid response from server.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred: ${e.toString()}');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
      body: Padding(
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
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem category) {
    // Check if this card is the Bank game card and if it's loading
    final isThisCardLoading = category.route == '/bank' && _isBankGameLoading;

    return GestureDetector(
      // Disable tap while loading
      onTap: isThisCardLoading ? null : () {
        if (category.route == '/bank') {
          // Call the data loading function for the bank game
          _loadAndStartBankGame();
        } else if (category.route == '/offside' || category.route == '/x-or-o') {
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
                    isThisCardLoading ? 'Loading Game...' : 'Tap to start challenge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightGrey,
                        ),
                  ),
                ],
              ),
            ),
            // Show a loading indicator instead of the arrow
            if (isThisCardLoading)
              const CircularProgressIndicator()
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
        content: Text(
          'This challenge is coming soon! Stay tuned for more exciting football quiz formats.',
          style: const TextStyle(color: AppColors.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: KoraCornerColors.primaryGreen), // Corrected color
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
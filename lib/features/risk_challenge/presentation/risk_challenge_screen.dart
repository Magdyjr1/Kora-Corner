import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/challenge_providers.dart';
import '../../../core/providers/risk_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/riverpod_timer.dart';

class RiskChallengeScreen extends ConsumerStatefulWidget {
  const RiskChallengeScreen({super.key});

  @override
  ConsumerState<RiskChallengeScreen> createState() => _RiskChallengeScreenState();
}

class _RiskChallengeScreenState extends ConsumerState<RiskChallengeScreen> {
  int _activeTeam = 1;
  int _team1Score = 0;
  int _team2Score = 0;

  final Set<String> _doubledCards = {};
  final Set<String> _usedCards = {};
  int? _selectedCategoryIndex;
  int? _selectedButtonIndex;
  bool _isDoubleUsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riskTimerProvider.notifier).startTimer();
    });
  }

  final List<int> _pointValues = const [5, 10, 20, 40];

  String _cardKey(int categoryIndex, int buttonIndex) => '$categoryIndex-$buttonIndex';

  bool _isCardDoubled(int categoryIndex, int buttonIndex) {
    return _doubledCards.contains(_cardKey(categoryIndex, buttonIndex));
  }

  bool _isCardUsed(int categoryIndex, int buttonIndex) {
    return _usedCards.contains(_cardKey(categoryIndex, buttonIndex));
  }

  void _toggleDoubleCard(int categoryIndex, int buttonIndex) {
    if (_isDoubleUsed && !_isCardDoubled(categoryIndex, buttonIndex)) {
      _showDoubleUsedWarning();
      return;
    }

    final key = _cardKey(categoryIndex, buttonIndex);
    setState(() {
      if (_doubledCards.contains(key)) {
        _doubledCards.remove(key);
        _isDoubleUsed = false;
      } else {
        _doubledCards.clear();
        _doubledCards.add(key);
        _isDoubleUsed = true;
      }
    });
  }

  void _showDoubleUsedWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Double Already Used', style: TextStyle(color: Colors.white)),
        content: const Text('You can only use the double option once per game. Remove the current double first to assign it to another question.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onCardTap(int categoryIndex, int buttonIndex, String categoryName, List<RiskQuestion> questions) {
    if (_isCardUsed(categoryIndex, buttonIndex)) {
      return;
    }

    setState(() {
      _selectedCategoryIndex = categoryIndex;
      _selectedButtonIndex = buttonIndex;
    });

    final question = questions[buttonIndex];
    final points = _pointValues[buttonIndex];
    final doubled = _isCardDoubled(categoryIndex, buttonIndex);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F0F),
          title: Text(categoryName, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question for $points points${doubled ? " (x2)" : ""}:',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Text(question.question, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Text('Answer:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(question.answer, style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _onCorrectPressed() {
    if (_selectedCategoryIndex == null || _selectedButtonIndex == null) return;
    final cat = _selectedCategoryIndex!;
    final btn = _selectedButtonIndex!;
    int points = _pointValues[btn];
    final wasDoubled = _isCardDoubled(cat, btn);
    if (wasDoubled) points *= 2;

    setState(() {
      if (_activeTeam == 1) {
        _team1Score += points;
      } else {
        _team2Score += points;
      }
      _usedCards.add(_cardKey(cat, btn));

      if (wasDoubled) {
        _doubledCards.remove(_cardKey(cat, btn));
        _isDoubleUsed = false;
      }
      _selectedCategoryIndex = null;
      _selectedButtonIndex = null;
    });
  }

  void _onWrongPressed() {
    if (_selectedCategoryIndex == null || _selectedButtonIndex == null) return;
    final cat = _selectedCategoryIndex!;
    final btn = _selectedButtonIndex!;
    final wasDoubled = _isCardDoubled(cat, btn);

    setState(() {
      _usedCards.add(_cardKey(cat, btn));

      if (wasDoubled) {
        _doubledCards.remove(_cardKey(cat, btn));
        _isDoubleUsed = false;
      }

      _selectedCategoryIndex = null;
      _selectedButtonIndex = null;
    });
  }

  // التايمر المحدّث بنفس تصميم GuessRightScreen
  Widget _buildTimerControlBar(BuildContext context) {
    final timerNotifier = ref.read(riskTimerProvider.notifier);
    final seconds = ref.watch(riskTimerProvider);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gameOnGreen.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              timerNotifier.formattedTime,
              style: TextStyle(
                color: seconds <= 10 ? AppColors.red : AppColors.brightGold,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 12),

            // أزرار التايمر
            Wrap(
              spacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _timerButton(
                  icon: timerNotifier.isRunning ? Icons.pause : Icons.play_arrow,
                  onTap: () {
                    if (timerNotifier.isRunning) {
                      timerNotifier.pauseTimer();
                    } else {
                      timerNotifier.resumeTimer();
                    }
                    setState(() {}); // ← تحديث فوراً
                  },
                  color: AppColors.brightGold,
                ),
                _timerButton(
                  icon: Icons.refresh,
                  onTap: () {
                    timerNotifier.resetTimer();
                    timerNotifier.startTimer(); // ← إضافة startTimer بعد reset
                    setState(() {});
                  },
                  color: AppColors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // زرار التايمر المتحرك - نفس التصميم بالظبط
  Widget _timerButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildScoreInputFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTeamScoreField(context, 'Team 1', _team1Score, 1),
        ),
        SizedBox(width: Responsive.getSpacing(context)),
        Expanded(
          child: _buildTeamScoreField(context, 'Team 2', _team2Score, 2),
        ),
      ],
    );
  }

  Widget _buildTeamScoreField(BuildContext context, String teamName, int score, int teamNumber) {
    final isActive = _activeTeam == teamNumber;
    return GestureDetector(
      onTap: () {
        setState(() => _activeTeam = teamNumber);
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.getSpacing(context)),
        decoration: BoxDecoration(
          color: teamNumber == 1 ? const Color(0xFF1A1A1A) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? (teamNumber == 1 ? AppColors.gameOnGreen : AppColors.brightGold)
                : AppColors.grey.withOpacity(0.3),
            width: isActive ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              teamName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: teamNumber == 1 ? AppColors.gameOnGreen : AppColors.brightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.getSpacing(context) * 0.5),
            Text(
              '$score',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: teamNumber == 1 ? AppColors.gameOnGreen : AppColors.brightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            if (isActive)
              Text('Active', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categoryNames = ref.watch(randomFourCategoriesProvider);

    if (categoryNames.isEmpty) {
      return const Center(
        child: Text(
          'Loading categories...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: Responsive.getSpacing(context),
        mainAxisSpacing: Responsive.getSpacing(context),
      ),
      itemCount: categoryNames.length,
      itemBuilder: (context, categoryIndex) {
        final categoryName = categoryNames[categoryIndex];
        return _CategoryCard(
          key: ValueKey('$categoryName-$categoryIndex'),
          categoryIndex: categoryIndex,
          categoryName: categoryName,
          onCardTap: _onCardTap,
          isCardDoubled: _isCardDoubled,
          isCardUsed: _isCardUsed,
          toggleDoubleCard: _toggleDoubleCard,
          pointValues: _pointValues,
        );
      },
    );
  }

  Widget _buildAnswerControlsAndSummary(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _onCorrectPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: const Text('إجابة صحيحة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _onWrongPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: const Text('إجابة غلط', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brightGold.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Text('Team 1: $_team1Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gameOnGreen, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Team 2: $_team2Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.brightGold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Active Team: $_activeTeam', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('Risk Challenge'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.read(randomFourCategoriesProvider.notifier).refreshAll();
            },
            tooltip: 'Refresh All Categories',
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: Responsive.getSpacing(context)),
                _buildTimerControlBar(context),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildScoreInputFields(context),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildCategoriesGrid(context),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildAnswerControlsAndSummary(context),
                SizedBox(height: Responsive.getSpacing(context) * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget منفصل لكل كاتيجوري
class _CategoryCard extends ConsumerWidget {
  final int categoryIndex;
  final String categoryName;
  final Function(int, int, String, List<RiskQuestion>) onCardTap;
  final bool Function(int, int) isCardDoubled;
  final bool Function(int, int) isCardUsed;
  final Function(int, int) toggleDoubleCard;
  final List<int> pointValues;

  const _CategoryCard({
    super.key,
    required this.categoryIndex,
    required this.categoryName,
    required this.onCardTap,
    required this.isCardDoubled,
    required this.isCardUsed,
    required this.toggleDoubleCard,
    required this.pointValues,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(categoryQuestionsProvider(categoryName));

    return Container(
      padding: EdgeInsets.all(Responsive.getSpacing(context)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  categoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  ref.read(randomFourCategoriesProvider.notifier).refreshCategory(categoryIndex);
                  ref.invalidate(categoryQuestionsProvider(categoryName));
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brightGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brightGold.withOpacity(0.5), width: 1),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: AppColors.brightGold,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getSpacing(context) * 0.5),
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildCardButton(context, 0, questions)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCardButton(context, 1, questions)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildCardButton(context, 2, questions)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCardButton(context, 3, questions)),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppColors.gameOnGreen,
                  strokeWidth: 2,
                ),
              ),
              error: (error, stack) => Center(
                child: Icon(Icons.error_outline, color: AppColors.red, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton(BuildContext context, int buttonIndex, List<RiskQuestion> questions) {
    final points = pointValues[buttonIndex];
    final doubled = isCardDoubled(categoryIndex, buttonIndex);
    final isUsed = isCardUsed(categoryIndex, buttonIndex);

    return GestureDetector(
      onTap: () => onCardTap(categoryIndex, buttonIndex, categoryName, questions),
      onLongPress: isUsed ? null : () => toggleDoubleCard(categoryIndex, buttonIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUsed
              ? AppColors.grey.withOpacity(0.3)
              : (doubled ? AppColors.gameOnGreen : const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUsed
                ? AppColors.grey.withOpacity(0.2)
                : (doubled ? AppColors.gameOnGreen : AppColors.grey.withOpacity(0.3)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUsed
                  ? Colors.transparent
                  : (doubled ? AppColors.gameOnGreen.withOpacity(0.25) : Colors.transparent),
              blurRadius: 4,
              offset: const Offset(0,2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${doubled ? points * 2 : points}',
                style: TextStyle(
                  color: isUsed
                      ? AppColors.grey.withOpacity(0.5)
                      : (doubled ? AppColors.black : AppColors.white),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (doubled && !isUsed)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.brightGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'x2',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
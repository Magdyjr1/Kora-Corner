import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/challenge_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/riverpod_timer.dart';
import '../../../widgets/manual_scoring_panel.dart';

class WhoAmIScreen extends ConsumerStatefulWidget {
  const WhoAmIScreen({super.key});

  @override
  ConsumerState<WhoAmIScreen> createState() => _WhoAmIScreenState();
}

class _WhoAmIScreenState extends ConsumerState<WhoAmIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riskTimerProvider.notifier).startTimer();
      // تحميل أسئلة جديدة عند فتح الشاشة
      ref.read(whoAmIProvider.notifier).loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(riskTimerProvider);
    final timerNotifier = ref.read(riskTimerProvider.notifier);
    final state = ref.watch(whoAmIProvider);
    final notifier = ref.read(whoAmIProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('Who Am I'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.brightGold),
            onPressed: () {
              ref.read(whoAmIProvider.notifier).refreshQuestions();
            },
            tooltip: 'Refresh Questions',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.brightGold),
      )
          : state.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            const Text('Error loading questions',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(state.error!,
                  style: const TextStyle(color: AppColors.grey),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => notifier.loadQuestions(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gameOnGreen,
                  foregroundColor: AppColors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : ResponsiveContainer(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: Responsive.getSpacing(context)),
                _buildTimerControlBar(
                    context, timerState, timerNotifier),
                SizedBox(height: Responsive.getSpacing(context)),
                const ManualScoringPanel(),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildPlayerCards(context, state, notifier),
                SizedBox(height: Responsive.getSpacing(context) * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerControlBar(BuildContext context, int timerSeconds,
      RiskTimerNotifier timerNotifier) =>
      Consumer(
        builder: (context, ref, _) {
          final notifier = ref.read(riskTimerProvider.notifier);
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
                    notifier.formattedTime,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: seconds <= 10
                          ? AppColors.red
                          : AppColors.brightGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _buildTimerButton(
                        icon: notifier.isRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                        onPressed: () {
                          if (notifier.isRunning) {
                            notifier.pauseTimer();
                          } else {
                            notifier.resumeTimer();
                          }
                          setState(() {});
                        },
                        color: AppColors.brightGold,
                      ),
                      _buildTimerButton(
                        icon: Icons.refresh,
                        onPressed: () {
                          notifier.resetTimer();
                          notifier.startTimer();
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
        },
      );

  Widget _buildTimerButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.black, size: 26),
        ),
      );

  Widget _buildPlayerCards(
      BuildContext context, WhoAmIState state, WhoAmINotifier notifier) {
    if (state.questions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No questions available',
            style: TextStyle(color: AppColors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(state.questions.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: Responsive.getSpacing(context)),
          child: _buildPlayerCard(context, index, state, notifier),
        );
      }),
    );
  }

  Widget _buildPlayerCard(BuildContext context, int index, WhoAmIState state,
      WhoAmINotifier notifier) {
    final isRevealed = state.playerRevealed[index];
    final question = state.questions[index];
    final clues = question.clues;
    final playerName = question.answer;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRevealed
              ? AppColors.brightGold
              : AppColors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isRevealed
                ? AppColors.brightGold.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Responsive.getAvatarSize(context) * 0.6,
                height: Responsive.getAvatarSize(context) * 0.6,
                decoration: BoxDecoration(
                  color:
                  isRevealed ? AppColors.brightGold : AppColors.gameOnGreen,
                  borderRadius: BorderRadius.circular(
                      Responsive.getAvatarSize(context) * 0.3),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
              SizedBox(width: Responsive.getSpacing(context)),
              Expanded(
                child: Text(
                  'Player ${index + 1}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          ...clues.asMap().entries.map((entry) {
            final clue = entry.value;
            // لو الـ clue فاضي متعرضوش
            if (clue.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(
                  bottom: Responsive.getSpacing(context) * 0.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: Responsive.getSpacing(context) * 0.75,
                    height: Responsive.getSpacing(context) * 0.75,
                    decoration: BoxDecoration(
                      color: AppColors.gameOnGreen,
                      borderRadius: BorderRadius.circular(
                          Responsive.getSpacing(context) * 0.375),
                    ),
                    child: const Center(
                      child: Text(
                        '•',
                        style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.getSpacing(context) * 0.5),
                  Expanded(
                    child: Text(
                      clue,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: Responsive.getSpacing(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => notifier.togglePlayerReveal(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gameOnGreen,
                foregroundColor: AppColors.black,
                padding: EdgeInsets.symmetric(
                    vertical: Responsive.getSpacing(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isRevealed ? 'Hide Player Name' : 'Reveal Player Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (isRevealed) ...[
            SizedBox(height: Responsive.getSpacing(context)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.getSpacing(context)),
              decoration: BoxDecoration(
                color: AppColors.brightGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brightGold, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events,
                      color: AppColors.brightGold,
                      size: Responsive.getSpacing(context) * 1.25),
                  SizedBox(width: Responsive.getSpacing(context) * 0.5),
                  Text(
                    playerName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.brightGold,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
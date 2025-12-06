import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/guess_right_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/riverpod_timer.dart';
import '../../../widgets/manual_scoring_panel.dart';
import '../../../ads/banner_ad_widget.dart';

class GuessRightScreen extends ConsumerStatefulWidget {
  const GuessRightScreen({super.key});

  @override
  ConsumerState<GuessRightScreen> createState() => _GuessRightScreenState();
}

class _GuessRightScreenState extends ConsumerState<GuessRightScreen> {
  final Set<int> _revealedIds = {}; // الإجابات المفتوحة

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(guessQuestionsProvider);
      ref.read(riskTimerProvider.notifier).startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerNotifier = ref.read(riskTimerProvider.notifier);
    final seconds = ref.watch(riskTimerProvider);
    final questionsAsync = ref.watch(guessQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/categories'),
        ),
        title: const Text(
          'اهبد صح',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
            // التايمر
            Center(
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
                        color: seconds <= 10
                            ? AppColors.red
                            : AppColors.brightGold,
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
                          icon: timerNotifier.isRunning
                              ? Icons.pause
                              : Icons.play_arrow,
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
            ),

            const SizedBox(height: 20),
            const ManualScoringPanel(),
            const SizedBox(height: 20),

            // الأسئلة من Supabase
            questionsAsync.when(
              data: (questions) => Column(
                children: questions
                    .asMap()
                    .entries
                    .map((e) => _buildQuestionCard(e.value, e.key + 1))
                    .toList(),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gameOnGreen),
              ),
              error: (err, _) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 60),
                    const SizedBox(height: 10),
                    const Text('فشل تحميل الأسئلة',
                        style: TextStyle(color: Colors.white)),
                    Text('$err', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => ref.refresh(guessQuestionsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  // زرار التايمر المتحرك
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

  // كارت السؤال
  Widget _buildQuestionCard(GuessQuestion q, int number) {
    final isRevealed = _revealedIds.contains(q.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            radius: 18,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            q.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              setState(() {
                isRevealed
                    ? _revealedIds.remove(q.id)
                    : _revealedIds.add(q.id);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gameOnGreen,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isRevealed ? 'إخفاء الإجابة' : 'إظهار الإجابة',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (isRevealed) ...[
            const SizedBox(height: 12),
            Text(
              q.answer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.brightGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
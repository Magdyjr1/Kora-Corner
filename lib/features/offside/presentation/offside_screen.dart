import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/riverpod_timer.dart';
import '../../../widgets/manual_scoring_panel.dart';
import '../../../core/providers/offside_provider.dart';

class OffsideChallengeScreen extends ConsumerStatefulWidget {
  const OffsideChallengeScreen({super.key});

  @override
  ConsumerState<OffsideChallengeScreen> createState() =>
      _OffsideChallengeScreenState();
}

class _OffsideChallengeScreenState
    extends ConsumerState<OffsideChallengeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(offsideProvider);
      ref.read(riskTimerProvider.notifier).startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerNotifier = ref.read(riskTimerProvider.notifier);
    final seconds = ref.watch(riskTimerProvider);
    final questionsAsync = ref.watch(offsideProvider);

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
          'أوفسايد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTimer(context, timerNotifier, seconds),

            const SizedBox(height: 20),
            const ManualScoringPanel(),
            const SizedBox(height: 20),

            // زر تحديث الأسئلة
            ElevatedButton.icon(
              onPressed: () => ref.refresh(offsideProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gameOnGreen,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.shuffle, color: Colors.black),
              label: const Text(
                'أسألة جديدة',
                style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // تحميل الأسئلة
            questionsAsync.when(
              data: (questions) => Column(
                children: questions
                    .asMap()
                    .entries
                    .map((e) => _buildQuestionCard(e.value.question, e.key + 1))
                    .toList(),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: CircularProgressIndicator(
                    color: AppColors.gameOnGreen,
                    strokeWidth: 5,
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 60),
                    const SizedBox(height: 10),
                    const Text(
                      'فشل تحميل الأسئلة',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '$err',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => ref.refresh(offsideProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTimer(
      BuildContext context, RiskTimerNotifier notifier, int seconds) {
    return Container(
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
            style: TextStyle(
              color:
              seconds <= 10 ? AppColors.red : AppColors.brightGold,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            children: [
              _timerBtn(
                icon:
                notifier.isRunning ? Icons.pause : Icons.play_arrow,
                color: AppColors.brightGold,
                onTap: () {
                  notifier.isRunning
                      ? notifier.pauseTimer()
                      : notifier.resumeTimer();
                  setState(() {});
                },
              ),
              _timerBtn(
                icon: Icons.refresh,
                color: AppColors.red,
                onTap: () {
                  notifier.resetTimer();
                  notifier.startTimer();
                  setState(() {});
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _timerBtn(
      {required IconData icon,
        required Color color,
        required VoidCallback onTap}) {
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
        child: Icon(icon, size: 28, color: Colors.black),
      ),
    );
  }

  // ---------------------------------------------------------
  // كارت السؤال
  Widget _buildQuestionCard(String question, int number) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 130),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            radius: 18,
            child: Text(
              '$number',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

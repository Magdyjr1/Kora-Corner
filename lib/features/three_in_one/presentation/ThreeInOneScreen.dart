import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/three_in_one_provider.dart';
import '../../../ads/banner_ad_widget.dart';
import '../../../ads/ads_manager.dart';

class ThreeInOneScreen extends ConsumerStatefulWidget {
  final List<String> playerNames;

  const ThreeInOneScreen({super.key, required this.playerNames});

  @override
  ConsumerState<ThreeInOneScreen> createState() => _ThreeInOneScreenState();
}

class _ThreeInOneScreenState extends ConsumerState<ThreeInOneScreen> with SingleTickerProviderStateMixin {
  late int player1Score;
  late int player2Score;
  late int player3Score;

  int currentQuestionIndex = 0;
  bool showAnswer = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    player1Score = 0;
    player2Score = 0;
    player3Score = 0;

    _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void incrementScore(int player) {
    setState(() {
      if (player == 1) player1Score++;
      if (player == 2) player2Score++;
      if (player == 3) player3Score++;
    });
  }

  void decrementScore(int player) {
    setState(() {
      if (player == 1) player1Score--;
      if (player == 2) player2Score--;
      if (player == 3) player3Score--;
    });
  }

  void nextQuestion(int totalQuestions) {
    setState(() {
      if (currentQuestionIndex < totalQuestions - 1) {
        currentQuestionIndex++;
        showAnswer = false;
        _controller.reset();
        
        // Track question completed for interstitial ad (shows after every 10 questions)
        AdsManager.instance.trackQuestionCompleted();
      }
    });
  }

  void toggleAnswer() {
    setState(() {
      showAnswer = !showAnswer;
      if (showAnswer) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.playerNames;
    final questionAsyncValue = ref.watch(threeInOneProvider);

    return Scaffold(
    backgroundColor: const Color(0xFF121212),
    appBar: AppBar(
    backgroundColor: Colors.black,
    centerTitle: true,
    title: const Text(
    '3 في 1',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: questionAsyncValue.when(
    data: (questions) {
    if (questions.isEmpty) {
    return const Center(
    child: Text('لا توجد أسئلة', style: TextStyle(color: Colors.white)),
    );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Column(
    children: [
    // Scores Row
    Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    buildPlayerScore(names[0], player1Score, 1),
    buildPlayerScore(names[1], player2Score, 2),
    buildPlayerScore(names[2], player3Score, 3),
    ],
    ),
    ),

    // Question Container with centered content and shadow
    Expanded(
    child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
    color: const Color(0xFF1F1F1F),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 10,
    offset: const Offset(0, 5),
    ),
    ],
    ),
    child: Center(
    child: SingleChildScrollView(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(
    currentQuestion.question,
    textAlign: TextAlign.center,
    style: const TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: 'Cairo',
    ),
    ),
    const SizedBox(height: 20),
    FadeTransition(
    opacity: _fadeAnimation,
    child: showAnswer
    ? Text(
    currentQuestion.answer,
    textAlign: TextAlign.center,
    style: const TextStyle(
    color: Color(0xFFFFC700),
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Cairo',
    ),
    )
        : const SizedBox.shrink(),
    ),
    ],
    ),
    ),
    ),
    ),
    ),

    // Bottom Buttons fixed
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    color: Colors.transparent,
    child: Column(
    children: [
    SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF00FF87),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    ),
    onPressed: () => nextQuestion(questions.length),
    child: const Text(
    'التالي',
    style: TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Cairo',
    ),
    ),
    ),
    ),
    const SizedBox(height: 12),
    SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF404040),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    ),
    onPressed: toggleAnswer,
    child: const Text(
    'إظهار الإجابة',
    style: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Cairo',
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, _) => Center(
    child: Text('حدث خطأ: $err', style: const TextStyle(color: Colors.white)),
    ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    ),
    );

  }

  Widget buildPlayerScore(String name, int score, int playerNumber) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: const TextStyle(
                color: Color(0xFFFFC700),
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildCircleButton('-', const Color(0xFFFF3030), () {
                  decrementScore(playerNumber);
                }),
                const SizedBox(width: 12),
                buildCircleButton('+', const Color(0xFF00FF87), () {
                  incrementScore(playerNumber);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCircleButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
    );
  }
}

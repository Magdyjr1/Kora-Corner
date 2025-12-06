import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/manual_scoring_panel.dart';

class XOChallengeScreen extends StatefulWidget {
  const XOChallengeScreen({super.key});

  @override
  State<XOChallengeScreen> createState() => _XOChallengeScreenState();
}

class _XOChallengeScreenState extends State<XOChallengeScreen>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String winner = '';
  Timer? _timer;
  int _remainingTime = 30;
  int? lastMove;
  List<int> winningIndices = [];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<String> colLogos = [
    'assets/images/barca.png',
    'assets/images/madrid.png',
    'assets/images/left_foot.png',
  ];

  final List<String> rowLogos = [
    'assets/images/premier_league.png',
    'assets/images/south_america.png',
    'assets/images/uefa.png',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();

    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.0, end: 15.0).animate(_glowController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingTime = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTap(int index) {
    if (board[index] == '' && winner == '') {
      setState(() {
        board[index] = currentPlayer;
        lastMove = index;
        _checkWinner();
        if (winner == '') {
          // بدل اللاعب وجدّد التايمر
          currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
          _startTimer();
        } else {
          _glowController.forward(from: 0);
        }
      });
    }
  }

  void _checkWinner() {
    const winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      String a = board[pattern[0]];
      if (a != '' && pattern.every((index) => board[index] == a)) {
        winner = a;
        winningIndices = pattern;
        return;
      }
    }
  }

  void _undoMove() {
    if (lastMove != null && winner == '') {
      setState(() {
        board[lastMove!] = '';
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
        lastMove = null;
        _startTimer(); // رجّع التايمر مع كل Undo
      });
    }
  }

  void _skipTurn() {
    if (winner == '') {
      setState(() {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
        _startTimer(); // جدّد التايمر بعد كل Skip
      });
    }
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      winner = '';
      winningIndices = [];
      lastMove = null;
      _startTimer();
    });
  }

  Color _getSymbolColor(String symbol) {
    if (symbol == 'X') return const Color(0xFF00FF87); // GameOn Green
    if (symbol == 'O') return const Color(0xFFFFC700); // Bright Gold
    return Colors.white;
  }

  Widget _buildCircularLogo(String path) {
    return ClipOval(
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'X O X O',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/categories'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // المؤقت (بتصميم أنيق)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFC700),
                    const Color(0xFFFFE87A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC700).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    '$_remainingTime s',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Manual Scoring Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const ManualScoringPanel(),
          ),
          const SizedBox(height: 16),

          // الشبكة
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Table(
                  border: TableBorder.all(color: Colors.white24),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildCircularLogo('assets/images/logo.jpeg'),
                        ),
                        for (var colLogo in colLogos)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildCircularLogo(colLogo),
                          ),
                      ],
                    ),
                    for (int row = 0; row < 3; row++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildCircularLogo(rowLogos[row]),
                          ),
                          for (int col = 0; col < 3; col++)
                            GestureDetector(
                              onTap: () => _handleTap(row * 3 + col),
                              child: AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  final isWinningCell =
                                  winningIndices.contains(row * 3 + col);
                                  return Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: isWinningCell
                                          ? const Color(0xFFFFC700)
                                          .withOpacity(0.2)
                                          : Colors.grey[900],
                                      border: Border.all(
                                          color: isWinningCell
                                              ? const Color(0xFFFFC700)
                                              : Colors.white24,
                                          width: isWinningCell ? 3 : 1),
                                      boxShadow: isWinningCell
                                          ? [
                                        BoxShadow(
                                          color:
                                          const Color(0xFFFFC700)
                                              .withOpacity(0.6),
                                          blurRadius:
                                          _glowAnimation.value,
                                          spreadRadius: 2,
                                        )
                                      ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        board[row * 3 + col],
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: _getSymbolColor(
                                              board[row * 3 + col]),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // اللاعب الحالي
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              winner == ''
                  ? 'CURRENT PLAYER: $currentPlayer'
                  : 'WINNER: $winner 🏆',
              style: TextStyle(
                fontSize: 18,
                color: _getSymbolColor(
                    winner == '' ? currentPlayer : winner),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3030),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Reset Game',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _undoMove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF404040),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Undo Move',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _skipTurn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Skip Turn',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bankProvider = StateNotifierProvider<BankNotifier, List<dynamic>>((ref) {
  return BankNotifier();
});

class BankNotifier extends StateNotifier<List<dynamic>> {
  BankNotifier() : super([]);

  /// Load 6 rounds × 12 random questions = 72 total
  void loadRandomQuestions(List<dynamic> sourceQuestions) {
    final random = Random();

    // Shuffle the source questions
    final shuffled = List<dynamic>.from(sourceQuestions)..shuffle(random);

    // Take first 72 questions only
    final needed = shuffled.take(72).toList();

    state = needed;
  }

  /// Get one question by round + index
  dynamic getQuestion(int round, int indexInRound) {
    final globalIndex = (round * 12) + indexInRound;
    if (globalIndex >= state.length) return null;
    return state[globalIndex];
  }
}

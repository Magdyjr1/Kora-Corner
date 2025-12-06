import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhoAmIQuestion {
  final int id;
  final List<String> clues;
  final String answer;

  WhoAmIQuestion({
    required this.id,
    required this.clues,
    required this.answer,
  });

  factory WhoAmIQuestion.fromJson(Map<String, dynamic> json) {
    // التعامل مع questions سواء كانت List أو String
    List<String> cluesList;
    if (json['questions'] is List) {
      cluesList = List<String>.from(json['questions'] as List);
    } else if (json['questions'] is String) {
      // لو كانت string، نفصلها بالـ comma أو newline
      cluesList = (json['questions'] as String)
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      cluesList = [];
    }

    return WhoAmIQuestion(
      id: json['id'] as int,
      clues: cluesList,
      answer: json['answers'] as String? ?? '',
    );
  }
}

class WhoAmIState {
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isTimerPaused;
  final List<bool> playerRevealed;
  final List<WhoAmIQuestion> questions;
  final bool isLoading;
  final String? error;

  const WhoAmIState({
    this.timerSeconds = 60,
    this.isTimerRunning = false,
    this.isTimerPaused = false,
    this.playerRevealed = const [],
    this.questions = const [],
    this.isLoading = true,
    this.error,
  });

  WhoAmIState copyWith({
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isTimerPaused,
    List<bool>? playerRevealed,
    List<WhoAmIQuestion>? questions,
    bool? isLoading,
    String? error,
  }) {
    return WhoAmIState(
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      playerRevealed: playerRevealed ?? this.playerRevealed,
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WhoAmINotifier extends StateNotifier<WhoAmIState> {
  final SupabaseClient _supabase;
  Timer? _timer;

  WhoAmINotifier(this._supabase) : super(const WhoAmIState()) {
    loadQuestions();
  }

  // تحميل الأسئلة من Supabase (3 أسئلة عشوائية)
  Future<void> loadQuestions() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // جلب 3 أسئلة عشوائية من Supabase
      final response = await _supabase
          .from('who_i_am')
          .select()
          .order('id', ascending: true);

      final allQuestions = (response as List)
          .map((json) => WhoAmIQuestion.fromJson(json))
          .toList();

      // اختيار 3 أسئلة عشوائية
      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(3).toList();

      state = state.copyWith(
        questions: selectedQuestions,
        playerRevealed: List.generate(selectedQuestions.length, (_) => false),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // تجديد الأسئلة
  Future<void> refreshQuestions() async {
    await loadQuestions();
  }

  // Timer functions
  void startTimer() {
    _timer?.cancel();

    state = state.copyWith(
      isTimerRunning: true,
      isTimerPaused: false,
      timerSeconds: 60,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 0) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isTimerRunning: false);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isTimerRunning: false, isTimerPaused: true);
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      timerSeconds: 60,
      isTimerRunning: false,
      isTimerPaused: false,
    );
  }

  // Player reveal functions
  void togglePlayerReveal(int index) {
    final newRevealed = List<bool>.from(state.playerRevealed);
    newRevealed[index] = !newRevealed[index];
    state = state.copyWith(playerRevealed: newRevealed);
  }

  void resetAllReveals() {
    state = state.copyWith(
      playerRevealed: List.generate(state.questions.length, (_) => false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final whoAmIProvider =
StateNotifierProvider<WhoAmINotifier, WhoAmIState>((ref) {
  return WhoAmINotifier(Supabase.instance.client);
});
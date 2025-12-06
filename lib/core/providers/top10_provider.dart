import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// TOP 10 SECTION - WITH SUPABASE
// ============================================================================

class Top10State {
  final List<String> players;
  final String currentQuestion;
  final List<bool> selectedPlayers;
  final List<int?> selectedByTeam;
  final int activeTeam;
  final int team1Score;
  final int team2Score;
  final bool isLoading;
  final String? error;

  const Top10State({
    this.players = const [
      'Lionel Messi',
      'Cristiano Ronaldo',
      'Kylian Mbappé',
      'Robert Lewandowski',
      'Mohamed Salah',
      'Erling Haaland',
      'Kevin De Bruyne',
      'Virgil van Dijk',
      'Luka Modrić',
      'Neymar Jr',
    ],
    this.currentQuestion = 'Loading question...',
    this.selectedPlayers = const [false, false, false, false, false, false, false, false, false, false],
    this.selectedByTeam = const [null, null, null, null, null, null, null, null, null, null],
    this.activeTeam = 1,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isLoading = true,
    this.error,
  });

  Top10State copyWith({
    List<String>? players,
    String? currentQuestion,
    List<bool>? selectedPlayers,
    List<int?>? selectedByTeam,
    int? activeTeam,
    int? team1Score,
    int? team2Score,
    bool? isLoading,
    String? error,
  }) {
    return Top10State(
      players: players ?? this.players,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      selectedPlayers: selectedPlayers ?? this.selectedPlayers,
      selectedByTeam: selectedByTeam ?? this.selectedByTeam,
      activeTeam: activeTeam ?? this.activeTeam,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class Top10Notifier extends StateNotifier<Top10State> {
  final SupabaseClient _supabase;

  Top10Notifier(this._supabase) : super(const Top10State()) {
    loadTop10Question();
  }

  // تحميل سؤال عشوائي من Supabase
  Future<void> loadTop10Question() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // جلب كل الأسئلة
      final response = await _supabase
          .from('top10')
          .select();

      if (response == null || (response as List).isEmpty) {
        throw Exception('No questions found');
      }

      // اختيار سؤال عشوائي
      final allQuestions = response as List;
      allQuestions.shuffle();
      final randomQuestion = allQuestions.first;

      final question = randomQuestion['questions'] as String;

      // تحويل النص لـ List (مفصول بسطر جديد أو comma)
      final playersText = randomQuestion['players'] as String;
      final playersList = playersText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      state = state.copyWith(
        currentQuestion: question,
        players: playersList,
        selectedPlayers: List.filled(playersList.length, false),
        selectedByTeam: List.filled(playersList.length, null),
        isLoading: false,
        team1Score: 0,
        team2Score: 0,
        activeTeam: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('Error loading Top10: $e');
    }
  }

  void switchTeam() {
    state = state.copyWith(activeTeam: state.activeTeam == 1 ? 2 : 1);
  }

  void togglePlayer(int index) {
    // لو اللاعب متختار خلاص، ما نعملش حاجة
    if (state.selectedPlayers[index]) return;

    final newSelectedPlayers = List<bool>.from(state.selectedPlayers);
    final newSelectedByTeam = List<int?>.from(state.selectedByTeam);

    newSelectedPlayers[index] = true;
    newSelectedByTeam[index] = state.activeTeam;

    // النقاط = الترتيب (index + 1)
    final points = index + 1;

    int newTeam1Score = state.team1Score;
    int newTeam2Score = state.team2Score;

    if (state.activeTeam == 1) {
      newTeam1Score += points;
    } else {
      newTeam2Score += points;
    }

    state = state.copyWith(
      selectedPlayers: newSelectedPlayers,
      selectedByTeam: newSelectedByTeam,
      team1Score: newTeam1Score,
      team2Score: newTeam2Score,
    );
  }

  void resetSelection() {
    state = state.copyWith(
      selectedPlayers: List.filled(state.players.length, false),
      selectedByTeam: List.filled(state.players.length, null),
      team1Score: 0,
      team2Score: 0,
      activeTeam: 1,
    );
  }

  // تجديد السؤال
  Future<void> refreshQuestion() async {
    await loadTop10Question();
  }
}

final top10Provider =
StateNotifierProvider.autoDispose<Top10Notifier, Top10State>((ref) {
  return Top10Notifier(Supabase.instance.client);
});


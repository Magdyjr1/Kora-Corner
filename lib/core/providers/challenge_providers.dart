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


// ============================================================================
// PICTURE CHALLENGE SECTION
// ============================================================================

// ============================================================================
// PICTURE CHALLENGE SECTION - WITH SUPABASE
// ============================================================================

class PlayerPicture {
  final int id;
  final String url;
  final String playerName;
  final String category;

  PlayerPicture({
    required this.id,
    required this.url,
    required this.playerName,
    required this.category,
  });

  factory PlayerPicture.fromJson(Map<String, dynamic> json) {
    return PlayerPicture(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      playerName: json['player_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class PictureChallengeState {
  final bool namesRevealed;
  final List<PlayerPicture> players;
  final int currentIndex;
  final String selectedCategory;
  final bool isLoading;
  final String? error;
  final bool categorySelected;

  const PictureChallengeState({
    this.namesRevealed = false,
    this.players = const [],
    this.currentIndex = 0,
    this.selectedCategory = '',
    this.isLoading = false,
    this.error,
    this.categorySelected = false,
  });

  PictureChallengeState copyWith({
    bool? namesRevealed,
    List<PlayerPicture>? players,
    int? currentIndex,
    String? selectedCategory,
    bool? isLoading,
    String? error,
    bool? categorySelected,
  }) {
    return PictureChallengeState(
      namesRevealed: namesRevealed ?? this.namesRevealed,
      players: players ?? this.players,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categorySelected: categorySelected ?? this.categorySelected,
    );
  }

  PlayerPicture? get currentPlayer {
    if (players.isEmpty || currentIndex >= players.length) return null;
    return players[currentIndex];
  }

  bool get hasNext => currentIndex < players.length - 1;
  bool get isLastPlayer => currentIndex == players.length - 1;
}

class PictureChallengeNotifier extends StateNotifier<PictureChallengeState> {
  final SupabaseClient _supabase;

  PictureChallengeNotifier(this._supabase) : super(const PictureChallengeState());

  // اختيار الفئة وتحميل اللاعبين
  Future<void> selectCategory(String category) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        selectedCategory: category,
      );

      // جلب اللاعبين حسب الفئة
      final response = await _supabase
          .from('pics_app')
          .select()
          .eq('category', category);

      if (response == null || (response as List).isEmpty) {
        throw Exception('لا توجد لاعبين في هذه الفئة');
      }

      final allPlayers = (response as List)
          .map((json) => PlayerPicture.fromJson(json))
          .toList();

      // خلط اللاعبين واختيار 11 لاعب
      allPlayers.shuffle();
      final selectedPlayers = allPlayers.take(11).toList();

      state = state.copyWith(
        players: selectedPlayers,
        currentIndex: 0,
        isLoading: false,
        categorySelected: true,
        namesRevealed: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('Error loading players: $e');
    }
  }

  void toggleNamesReveal() {
    state = state.copyWith(namesRevealed: !state.namesRevealed);
  }

  void nextPlayer() {
    if (state.hasNext) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        namesRevealed: false,
      );
      
      // Track image viewed for interstitial ad (shows after every 11 images)
      // Import: import '../../../ads/ads_manager.dart';
      // AdsManager.instance.trackImageViewed();
    }
  }

  void previousPlayer() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        namesRevealed: false,
      );
    }
  }

  // إعادة تعيين التحدي بالكامل
  void resetChallenge() {
    state = const PictureChallengeState();
  }

  // تجديد اللاعبين بنفس الفئة
  Future<void> refreshPlayers() async {
    if (state.selectedCategory.isNotEmpty) {
      await selectCategory(state.selectedCategory);
    }
  }
}

final pictureChallengeProvider =
StateNotifierProvider<PictureChallengeNotifier, PictureChallengeState>(
      (ref) {
    return PictureChallengeNotifier(Supabase.instance.client);
  },
);

// ============================================================================
// WHO AM I SECTION - WITH SUPABASE
// ============================================================================

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
    List<String> cluesList;
    if (json['questions'] is List) {
      cluesList = List<String>.from(json['questions'] as List);
    } else if (json['questions'] is String) {
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

  Future<void> loadQuestions() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('who_i_am')
          .select()
          .order('id', ascending: true);

      final allQuestions = (response as List)
          .map((json) => WhoAmIQuestion.fromJson(json))
          .toList();

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

  Future<void> refreshQuestions() async {
    await loadQuestions();
  }

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

// ============================================================================
// RISK CHALLENGE SECTION
// ============================================================================

class RiskChallengeState {
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isTimerPaused;
  final int team1Score;
  final int team2Score;
  final List<List<bool>> buttonStates;

  const RiskChallengeState({
    this.timerSeconds = 120,
    this.isTimerRunning = false,
    this.isTimerPaused = false,
    this.team1Score = 0,
    this.team2Score = 0,
    this.buttonStates = const [
      [false, false, false, false],
      [false, false, false, false],
      [false, false, false, false],
      [false, false, false, false],
    ],
  });

  RiskChallengeState copyWith({
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isTimerPaused,
    int? team1Score,
    int? team2Score,
    List<List<bool>>? buttonStates,
  }) {
    return RiskChallengeState(
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      buttonStates: buttonStates ?? this.buttonStates,
    );
  }
}

class RiskChallengeNotifier extends StateNotifier<RiskChallengeState> {
  RiskChallengeNotifier() : super(const RiskChallengeState());

  Timer? _timer;

  void startTimer() {
    _timer?.cancel();

    state = state.copyWith(isTimerRunning: true, isTimerPaused: false);

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
      timerSeconds: 120,
      isTimerRunning: false,
      isTimerPaused: false,
    );
  }

  void addScore(int team, int points) {
    if (team == 1) {
      state = state.copyWith(team1Score: state.team1Score + points);
    } else {
      state = state.copyWith(team2Score: state.team2Score + points);
    }
  }

  void toggleButton(int categoryIndex, int buttonIndex) {
    final newButtonStates =
    state.buttonStates.map((c) => List<bool>.from(c)).toList();
    newButtonStates[categoryIndex][buttonIndex] =
    !newButtonStates[categoryIndex][buttonIndex];
    state = state.copyWith(buttonStates: newButtonStates);
  }

  void resetScores() {
    _timer?.cancel();
    state = state.copyWith(
      team1Score: 0,
      team2Score: 0,
      timerSeconds: 120,
      buttonStates: List.generate(4, (_) => [false, false, false, false]),
    );
  }
}

final riskChallengeProvider =
StateNotifierProvider<RiskChallengeNotifier, RiskChallengeState>((ref) {
  return RiskChallengeNotifier();
});
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
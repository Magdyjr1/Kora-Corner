import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

final supabase = Supabase.instance.client;

////////////////////////////////////////////////////////////////////////////////
//                        MODEL
////////////////////////////////////////////////////////////////////////////////

class RiskQuestion {
  final int id;
  final String question;
  final String answer;
  final String category;
  final int score;

  RiskQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.score,
  });

  factory RiskQuestion.fromJson(Map<String, dynamic> json) {
    return RiskQuestion(
      id: json['id'] as int,
      question: (json['questions'] as String?)?.trim() ?? 'No Question',
      answer: (json['answers'] as String?)?.trim() ?? 'No Answer',
      category: (json['categories'] as String?)?.trim() ?? 'General',
      score: json['score'] as int? ?? 0,
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
//                        GET ALL CATEGORIES
////////////////////////////////////////////////////////////////////////////////

final allRiskCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final result = await supabase.from('risk').select('categories');
  final set = <String>{};

  for (final row in result) {
    if (row['categories'] != null) {
      set.add(row['categories']);
    }
  }

  return set.toList();
});

////////////////////////////////////////////////////////////////////////////////
//                        RANDOM 4 CATEGORIES
////////////////////////////////////////////////////////////////////////////////

final randomFourCategoriesProvider =
StateNotifierProvider<RandomFourCategoriesNotifier, List<String>>(
      (ref) => RandomFourCategoriesNotifier(ref),
);

class RandomFourCategoriesNotifier extends StateNotifier<List<String>> {
  final Ref ref;
  RandomFourCategoriesNotifier(this.ref) : super([]) {
    _pickFour();
  }

  Future<void> _pickFour() async {
    final all = await ref.read(allRiskCategoriesProvider.future);
    final random = Random();
    final picked = <String>{};

    while (picked.length < 4 && picked.length < all.length) {
      picked.add(all[random.nextInt(all.length)]);
    }

    state = picked.toList();
  }

  Future<void> refreshCategory(int index) async {
    final all = await ref.read(allRiskCategoriesProvider.future);
    final current = state[index];

    final available =
    all.where((c) => !state.contains(c) || c == current).toList();

    if (available.isEmpty) return;

    final random = Random();
    final newCat = available[random.nextInt(available.length)];

    final newState = [...state];
    newState[index] = newCat;
    state = newState;
  }

  void refreshAll() => _pickFour();
}

////////////////////////////////////////////////////////////////////////////////
//             GET QUESTIONS BY (CATEGORY + SCORE)
////////////////////////////////////////////////////////////////////////////////

final categoryQuestionsByScoreProvider =
FutureProvider.family<List<RiskQuestion>, Map<String, dynamic>>(
      (ref, params) async {
    final String category = params['category'];
    final int score = params['score'];

    final response = await supabase
        .from('risk')
        .select('id, questions, answers, categories, score')
        .eq('categories', category)
        .eq('score', score);

    final list = (response as List)
        .map((data) => RiskQuestion.fromJson(data))
        .toList();

    list.shuffle();
    return list;
  },
);

////////////////////////////////////////////////////////////////////////////////
//    GET 4 RANDOM QUESTIONS FOR A SPECIFIC CATEGORY (للـ Screen)
////////////////////////////////////////////////////////////////////////////////

/// Provider that fetches 4 questions (one for each score: 5, 10, 20, 40)
/// for a given category name
final categoryQuestionsProvider =
FutureProvider.family<List<RiskQuestion>, String>((ref, categoryName) async {
  // الـ 4 scores اللي محتاجينهم
  final scores = [5, 10, 20, 40];
  final List<RiskQuestion> allQuestions = [];

  // نجيب سؤال واحد عشوائي لكل score
  for (final score in scores) {
    try {
      final response = await supabase
          .from('risk')
          .select('id, questions, answers, categories, score')
          .eq('categories', categoryName)
          .eq('score', score);

      if (response != null && response is List && response.isNotEmpty) {
        final list = response
            .map((data) => RiskQuestion.fromJson(data))
            .toList();

        // نختار سؤال واحد عشوائي
        list.shuffle();
        if (list.isNotEmpty) {
          allQuestions.add(list.first);
        }
      }
    } catch (e) {
      print('Error fetching questions for $categoryName with score $score: $e');
    }
  }

  // لو ماجبناش 4 أسئلة، نعمل padding بأسئلة فارغة
  while (allQuestions.length < 4) {
    allQuestions.add(RiskQuestion(
      id: 0,
      question: 'No question available',
      answer: 'N/A',
      category: categoryName,
      score: scores[allQuestions.length],
    ));
  }

  return allQuestions;
});

////////////////////////////////////////////////////////////////////////////////
//       LOAD THE 4 CATEGORIES WITH THEIR QUESTIONS
////////////////////////////////////////////////////////////////////////////////

class RiskCategoryQuestions {
  final String categoryName;
  final List<RiskQuestion> questions;

  RiskCategoryQuestions({
    required this.categoryName,
    required this.questions,
  });
}

final riskQuestionsProvider =
FutureProvider.autoDispose<List<RiskCategoryQuestions>>((ref) async {
  final categories = ref.watch(randomFourCategoriesProvider);
  final List<RiskCategoryQuestions> result = [];

  for (final cat in categories) {
    try {
      final questions = await ref.watch(categoryQuestionsProvider(cat).future);
      result.add(RiskCategoryQuestions(
        categoryName: cat,
        questions: questions,
      ));
    } catch (e) {
      print('Error loading questions for category $cat: $e');
      result.add(RiskCategoryQuestions(
        categoryName: cat,
        questions: [],
      ));
    }
  }

  return result;
});
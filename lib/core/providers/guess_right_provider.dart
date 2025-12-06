import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// موديل السؤال
class GuessQuestion {
  final int id;
  final String question;
  final String answer;

  GuessQuestion({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory GuessQuestion.fromJson(Map<String, dynamic> json) {
    return GuessQuestion(
      id: json['id'] as int,
      question: (json['questions'] as String?)?.trim() ?? 'لا يوجد سؤال',
      answer: (json['answers'] as String?)?.trim() ?? 'لا توجد إجابة',
    );
  }
}

// Provider لجلب الأسئلة بشكل Random داخل Flutter
final guessQuestionsProvider = FutureProvider.autoDispose<List<GuessQuestion>>((ref) async {
  try {
    final response = await supabase
        .from('ehbd_sah')
        .select('id, questions, answers');

    if (response.isEmpty) {
      throw Exception('Error');
    }

    final list = (response as List)
        .map((data) => GuessQuestion.fromJson(data as Map<String, dynamic>))
        .toList();

    list.shuffle();

    return list.take(8).toList();

  } catch (e) {
    print('خطأ في جلب الأسئلة: $e');
    rethrow;
  }
});

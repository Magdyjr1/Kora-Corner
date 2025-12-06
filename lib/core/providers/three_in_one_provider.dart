import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// موديل السؤال
class ThreeInOneQuestion {
  final int id;
  final String question;
  final String answer;

  ThreeInOneQuestion({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory ThreeInOneQuestion.fromJson(Map<String, dynamic> json) {
    return ThreeInOneQuestion(
      id: json['id'] as int,
      question: (json['questions'] as String?)?.trim() ?? 'لا يوجد سؤال',
      answer: (json['answers'] as String?)?.trim() ?? 'لا توجد إجابة',
    );
  }
}

// Provider لجلب الأسئلة بشكل Random داخل Flutter
final threeInOneProvider =
FutureProvider.autoDispose<List<ThreeInOneQuestion>>((ref) async {
  try {
    final response = await supabase
        .from('3X1')
        .select('id, questions, answers')
        .limit(80); // الحد الأقصى 80 سؤال لتحسين الأداء

  if (response.isEmpty) {
  throw Exception('لا توجد أسئلة في الجدول.');
  }

  final list = (response as List)
      .map((data) => ThreeInOneQuestion.fromJson(data as Map<String, dynamic>))
      .toList();

  list.shuffle(); // خلط الأسئلة عشوائياً

  return list;


  } catch (e) {
  print('خطأ في جلب الأسئلة: $e');
  rethrow;
  }
});

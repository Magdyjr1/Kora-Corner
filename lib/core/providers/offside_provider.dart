import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// موديل سؤال الأوفسايد
class OffsideQuestion {
  final int id;
  final String question;

  OffsideQuestion({
    required this.id,
    required this.question,
  });

  factory OffsideQuestion.fromJson(Map<String, dynamic> json) {
    return OffsideQuestion(
      id: json['id'] as int,
      question: (json['questions'] as String?)?.trim() ?? 'لا يوجد سؤال',
    );
  }
}

/// Provider لجلب 10 أسئلة عشوائية كل مرة
final offsideProvider =
FutureProvider.autoDispose<List<OffsideQuestion>>((ref) async {
  try {
    final response = await supabase
        .from('offside')
        .select('id, questions');

    if (response.isEmpty) {
      throw Exception('لا توجد أسئلة');
    }

    final list = (response as List)
        .map((data) => OffsideQuestion.fromJson(data as Map<String, dynamic>))
        .toList();

    // Shuffle الأسئلة
    list.shuffle();

    // نرجّع 10 فقط
    return list.take(10).toList();
  } catch (e) {
    print("❌ خطأ في تحميل أسئلة Offside: $e");
    rethrow;
  }
});

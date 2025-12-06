import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Player {
  final int id;
  final String name;

  Player({required this.id, required this.name});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      name: (json['players'] as String?)?.trim() ?? 'لاعب مجهول',
    );
  }
}

final passwordProvider = FutureProvider.autoDispose<List<Player>>((ref) async {
  try {
    final response = await supabase
        .from('password')
        .select('id, players');

    if (response.isEmpty) return [];

    final list = (response as List)
        .map((data) => Player.fromJson(data as Map<String, dynamic>))
        .toList();

    list.shuffle();
    return list.take(8).toList();
  } catch (e) {
    print('خطأ في جلب اللاعبين: $e');
    rethrow;
  }
});

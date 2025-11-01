import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cbjkcitcniavlqjjnkfy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiamtjaXRjbmlhdmxxampua2Z5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MjY2MTcsImV4cCI6MjA3NzMwMjYxN30.K2todRSmyr9HM3plF-ZGtYRpvcrHIzHex2RHSGO__Uc',
  );

  runApp(
    const ProviderScope(
      child: KoraCornerApp(),
    ),
  );
}

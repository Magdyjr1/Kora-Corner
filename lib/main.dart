import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'services/ad_service.dart';
import 'widgets/app_lifecycle_wrapper.dart';

/// ============================================================================
/// MAIN ENTRY POINT
/// ============================================================================
/// 
/// This is the app's entry point. It initializes:
/// 1. Flutter binding (required for async initialization)
/// 2. Supabase (backend service)
/// 3. Google Mobile Ads SDK (AdMob)
/// 4. AdService (our ad management singleton)
/// 
/// App Lifecycle Wrapper:
/// - Wraps the app to handle App Open ads on launch/resume
/// - Listens to app lifecycle events (background/foreground)
/// 
/// ============================================================================

Future<void> main() async {
  // Ensure Flutter binding is initialized (required for async operations)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend service
  await Supabase.initialize(
    url: 'https://cbjkcitcniavlqjjnkfy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiamtjaXRjbmlhdmxxampua2Z5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MjY2MTcsImV4cCI6MjA3NzMwMjYxN30.K2todRSmyr9HM3plF-ZGtYRpvcrHIzHex2RHSGO__Uc',
  );

  // Initialize Google Mobile Ads SDK
  // This must be called before using any ad features
  await MobileAds.instance.initialize();

  // Initialize AdService (our centralized ad management system)
  // This will load initial ads (banner, interstitial, app open)
  await AdService.instance.initialize();

  // Run the app wrapped in AppLifecycleWrapper for App Open ads
  runApp(
    const ProviderScope(
      child: AppLifecycleWrapper(
        child: KoraCornerApp(),
      ),
    ),
  );
}

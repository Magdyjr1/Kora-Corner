import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/ad_service.dart';

/// ============================================================================
/// APP LIFECYCLE WRAPPER - Handles App Open Ads
/// ============================================================================
/// 
/// This widget wraps your app and listens to app lifecycle events to show
/// App Open ads when the app is launched or resumed from background.
/// 
/// HOW IT WORKS:
/// =============
/// - On app launch (cold start): Shows App Open ad if available
/// - On app resume (from background): Shows App Open ad if available
/// - Does NOT block app startup - ads load asynchronously
/// - Continues app normally if ad fails to load
/// 
/// USAGE:
/// ======
/// Wrap your app's MaterialApp.router in main.dart:
/// 
/// ```dart
/// runApp(
///   const ProviderScope(
///     child: AppLifecycleWrapper(
///       child: KoraCornerApp(),
///     ),
///   ),
/// );
/// ```
/// 
/// ============================================================================

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Show App Open ad on initial app launch (after a brief delay)
    // This ensures the app UI is ready before showing the ad
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          AdService.instance.showAppOpenAdIfReady();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed from background - show App Open ad if available
        if (_wasInBackground) {
          // Small delay to ensure UI is ready
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              AdService.instance.showAppOpenAdIfReady();
            }
          });
        }
        _wasInBackground = false;
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background
        _wasInBackground = true;
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


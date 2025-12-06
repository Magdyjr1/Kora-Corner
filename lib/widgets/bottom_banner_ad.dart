import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ad_service.dart';

/// ============================================================================
/// BOTTOM BANNER AD WIDGET - Persistent Banner Ad Component
/// ============================================================================
/// 
/// A persistent banner ad widget that displays at the bottom of screens.
/// 
/// FEATURES:
/// - Automatically excludes auth screens (/login, /signup, /auth, etc.)
/// - Respects SafeArea (won't overlap system UI)
/// - Loads asynchronously (doesn't block UI)
/// - Automatically reloads every 60 seconds via AdService
/// - Handles errors gracefully (no crashes if ad fails)
/// 
/// USAGE:
/// ======
/// Simply add this widget to any non-auth screen:
/// 
/// Scaffold(
///   body: SafeArea(
///     child: Column(
///       children: [
///         Expanded(child: YourContent()),
///         const BottomBannerAd(), // Add this line
///       ],
///     ),
///   ),
/// )
/// 
/// The widget will automatically:
/// - Hide on auth screens (login, signup, etc.)
/// - Load the ad when ready
/// - Retry if AdService isn't initialized yet
/// - Show nothing if ad fails to load (no crashes)
/// 
/// AUTH SCREEN EXCLUSION:
/// ======================
/// The banner automatically hides on routes containing:
/// - /auth
/// - /login
/// - /signup
/// - Auth
/// - Login
/// - SignUp
/// 
/// ============================================================================

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  Widget? _adWidget;
  bool _shouldShowAd = true;

  @override
  void initState() {
    super.initState();
    _checkIfAuthScreen();
    _loadBanner();
  }

  /// Check if current route is an auth screen and hide banner if so
  void _checkIfAuthScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      String? route;
      try {
        route = GoRouterState.of(context).uri.path;
      } catch (e) {
        // If we can't get route, default to showing ad
        route = '';
      }
      
      // List of auth-related route patterns
      final authPatterns = [
        '/auth',
        '/login',
        '/signup',
        '/forgot-password',
        '/password-reset-otp',
        '/update-password',
        '/otp',
        '/forgot',
      ];
      
      // Check if current route contains any auth pattern
      final isAuthScreen = route != null && authPatterns.any((pattern) => route!.contains(pattern));
      
      if (mounted) {
        setState(() {
          _shouldShowAd = !isAuthScreen;
        });
        
        // If not auth screen, load banner
        if (_shouldShowAd) {
          _loadBanner();
        }
      }
    });
  }

  /// Load banner ad from AdService
  void _loadBanner() {
    // Don't load if auth screen
    if (!_shouldShowAd) {
      return;
    }

    // Check if AdService is initialized
    if (!AdService.instance.isInitialized) {
      // Retry after a delay if not initialized yet
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _shouldShowAd) {
          _loadBanner();
        }
      });
      return;
    }

    // Get banner widget from AdService
    final bannerWidget = AdService.instance.getBannerWidget();
    if (bannerWidget != null && mounted && _shouldShowAd) {
      setState(() {
        _adWidget = bannerWidget;
      });
    }
  }

  @override
  void dispose() {
    // Note: We don't dispose the banner here because AdService manages it
    // Disposing here would break the 60-second reload timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show banner on auth screens
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    // Don't show if ad widget is not loaded
    if (_adWidget == null) {
      return const SizedBox.shrink();
    }

    // Show banner ad with SafeArea protection
    return SafeArea(
      top: false, // Only protect bottom
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50, // Standard banner height
        color: Colors.transparent,
        child: _adWidget,
      ),
    );
  }
}


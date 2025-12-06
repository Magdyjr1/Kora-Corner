import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_manager.dart';

/// ============================================================================
/// BANNER AD WIDGET - Reusable Banner Ad Component
/// ============================================================================
/// 
/// A persistent banner ad widget that displays at the bottom of screens.
/// 
/// FEATURES:
/// - Respects SafeArea (won't overlap system UI)
/// - Loads asynchronously (doesn't block UI)
/// - Responsive design
/// - Handles errors gracefully
/// 
/// USAGE:
/// ======
/// Simply add this widget to any screen:
/// 
/// Scaffold(
///   body: SafeArea(
///     child: Column(
///       children: [
///         Expanded(child: YourContent()),
///         const BannerAdWidget(), // Add this line
///       ],
///     ),
///   ),
/// )
/// 
/// The widget will automatically:
/// - Load the ad when ready
/// - Retry if AdsManager isn't initialized yet
/// - Show nothing if ad fails to load (no crashes)
/// 
/// ============================================================================

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  Widget? _adWidget;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdsManager.instance.isInitialized) {
      // Retry after a delay if not initialized yet
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _loadBanner();
      });
      return;
    }

    final bannerWidget = AdsManager.instance.getBannerWidget();
    if (bannerWidget != null && mounted) {
      setState(() {
        _adWidget = bannerWidget;
      });
    }
  }

  @override
  void dispose() {
    AdsManager.instance.disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adWidget == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
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


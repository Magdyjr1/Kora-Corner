import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/services/logs_service.dart';

/// Handles interstitial ads with cooldown management
/// 
/// Features:
/// - Global 180-second cooldown between interstitials
/// - Automatic pre-loading of next ad after one is shown
/// - Graceful error handling (app won't crash if ad fails)
/// 
/// This is managed internally by AdsManager - you typically don't
/// need to interact with this class directly.
class InterstitialAdHandler {
  final String _adUnitId;
  
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  DateTime? _lastShownTime;
  
  // Cooldown duration: 3 minutes (180 seconds) as required
  static const Duration _cooldownDuration = Duration(seconds: 180);

  InterstitialAdHandler(this._adUnitId);

  /// Load an interstitial ad
  /// 
  /// Automatically called by AdsManager. Preloads ad for faster display.
  void load() {
    // Don't load if already loading or already loaded
    if (_isLoading || _interstitialAd != null) return;
    
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _setupAdListeners();
          LogsService.logInfo('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          LogsService.logError('Interstitial ad failed to load', error: error);
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _setupAdListeners() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastShownTime = DateTime.now();
        // Pre-load next ad
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        LogsService.logError('Interstitial ad failed to show', error: error);
        ad.dispose();
        _interstitialAd = null;
        _isLoading = false;
      },
      onAdShowedFullScreenContent: (_) {
        LogsService.logInfo('Interstitial ad showed');
      },
    );
  }

  /// Show interstitial if available and cooldown has passed
  /// 
  /// Checks:
  /// 1. Global cooldown (180 seconds) - must have passed
  /// 2. Ad is loaded and ready
  /// 
  /// Returns early if conditions aren't met (no error thrown).
  Future<void> showIfAvailable() async {
    // Check global cooldown
    if (_lastShownTime != null) {
      final timeSinceLastShow = DateTime.now().difference(_lastShownTime!);
      if (timeSinceLastShow < _cooldownDuration) {
        final remainingSeconds = (_cooldownDuration - timeSinceLastShow).inSeconds;
        LogsService.logInfo('Interstitial cooldown active. Remaining: ${remainingSeconds}s');
        return; // Cooldown not over yet
      }
    }

    // Check if ad is loaded
    if (_interstitialAd == null) {
      // Try to load if not already loading
      if (!_isLoading) {
        load();
      }
      LogsService.logInfo('Interstitial ad not ready yet, loading...');
      return; // Ad not ready
    }

    // Show the ad
    try {
      await _interstitialAd?.show();
      LogsService.logInfo('Interstitial ad shown successfully');
    } catch (e, stackTrace) {
      LogsService.logError('Error showing interstitial', error: e, stackTrace: stackTrace);
      // Clean up failed ad
      _interstitialAd?.dispose();
      _interstitialAd = null;
      // Try to load next ad
      load();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}


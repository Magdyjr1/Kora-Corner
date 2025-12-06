import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/services/logs_service.dart';

/// ============================================================================
/// AD SERVICE - Centralized Google AdMob Ad Management System
/// ============================================================================
/// 
/// This singleton manages all ad types:
/// - Banner Ads: Bottom banner that reloads every 60 seconds
/// - Interstitial Ads: Full-screen ads shown every 180 seconds (3 minutes)
/// - App Open Ads: Shown on app launch and resume from background
/// 
/// CONFIGURATION:
/// ==============
/// To adjust timing intervals, modify these constants:
/// - INTERSTITIAL_COOLDOWN_SECONDS: Time between interstitial ads (default: 180)
/// - BANNER_RELOAD_SECONDS: Time between banner reloads (default: 60)
/// 
/// DISABLE APP OPEN ADS:
/// =====================
/// Set enableAppOpenAds = false at the top of this class to disable App Open ads.
/// 
/// HOW TO USE:
/// ===========
/// 1. Initialize in main.dart:
///    await AdService.instance.initialize();
/// 
/// 2. Show interstitial on screen navigation:
///    AdService.instance.showInterstitialIfAllowed();
/// 
/// 3. Add banner to screens (except auth):
///    const BottomBannerAd()
/// 
/// ============================================================================

class AdService {
  // Singleton pattern
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  // ==========================================================================
  // AD UNIT IDs - REAL PRODUCTION IDs
  // ==========================================================================
  // These are your actual AdMob Ad Unit IDs from your AdMob console
  static const String _bannerAdUnitId = 'ca-app-pub-5362626390266412/8931364574';
  static const String _interstitialAdUnitId = 'ca-app-pub-5362626390266412/6464983337';
  static const String _appOpenAdUnitId = 'ca-app-pub-5362626390266412/6011904808';

  // ==========================================================================
  // CONFIGURATION CONSTANTS - Easy to adjust timing
  // ==========================================================================
  /// Cooldown between interstitial ads in seconds (default: 180 = 3 minutes)
  static const int INTERSTITIAL_COOLDOWN_SECONDS = 180;
  
  /// Banner reload interval in seconds (default: 60 = 1 minute)
  static const int BANNER_RELOAD_SECONDS = 60;
  
  /// Maximum retry attempts for failed ad loads (default: 3)
  static const int MAX_RETRY_ATTEMPTS = 3;

  // ==========================================================================
  // FEATURE TOGGLES - Easy to disable features
  // ==========================================================================
  /// Set to false to disable App Open ads completely
  bool enableAppOpenAds = true;

  // ==========================================================================
  // STATE VARIABLES
  // ==========================================================================
  bool _isInitialized = false;
  DateTime? _lastInterstitialShown;
  
  // Banner ad management
  BannerAd? _bannerAd;
  int _bannerRetryCount = 0;
  Timer? _bannerReloadTimer;
  
  // Interstitial ad management
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialRetryCount = 0;
  Timer? _interstitialCooldownTimer;
  
  // App Open ad management
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  int _appOpenRetryCount = 0;
  bool _isAppOpenAdReady = false;
  DateTime? _appOpenLastShownTime;

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  
  /// Initialize the Ad Service and load initial ads
  /// Call this in main.dart after WidgetsFlutterBinding.ensureInitialized()
  Future<void> initialize() async {
    if (_isInitialized) {
      LogsService.logInfo('AdService already initialized');
      return;
    }

    try {
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      LogsService.logInfo('AdService: MobileAds SDK initialized successfully');
      
      // Load initial ads
      _loadInterstitial();
      _loadAppOpenAd();
      
      _isInitialized = true;
      LogsService.logInfo('AdService initialized successfully');
    } catch (e, stackTrace) {
      LogsService.logError('AdService: Failed to initialize', error: e, stackTrace: stackTrace);
      // Continue without crashing - ads will simply not show
      _isInitialized = false;
    }
  }

  // ==========================================================================
  // BANNER AD METHODS
  // ==========================================================================
  
  /// Create and load a banner ad widget
  /// This is called by BottomBannerAd widget
  Widget? getBannerWidget() {
    if (!_isInitialized) {
      LogsService.logWarning('AdService: Cannot create banner - not initialized');
      return null;
    }

    try {
      // Dispose existing banner if any
      _bannerAd?.dispose();

      // Create new banner ad
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            LogsService.logInfo('AdService: Banner ad loaded successfully');
            _bannerRetryCount = 0; // Reset retry count on success
            // Start timer to reload banner after 60 seconds
            _startBannerReloadTimer();
          },
          onAdFailedToLoad: (ad, error) {
            LogsService.logError('AdService: Banner ad failed to load', error: error);
            ad.dispose();
            _bannerRetryCount++;
            
            // Only retry if under max attempts
            if (_bannerRetryCount < MAX_RETRY_ATTEMPTS) {
              LogsService.logInfo('AdService: Retrying banner load (attempt $_bannerRetryCount/$MAX_RETRY_ATTEMPTS)');
              Future.delayed(const Duration(seconds: 5), () {
                if (_isInitialized) getBannerWidget();
              });
            } else {
              LogsService.logWarning('AdService: Banner ad failed after $MAX_RETRY_ATTEMPTS attempts. Pausing retries.');
            }
          },
          onAdOpened: (_) {
            LogsService.logInfo('AdService: Banner ad opened');
          },
          onAdClosed: (_) {
            LogsService.logInfo('AdService: Banner ad closed');
          },
        ),
      );

      _bannerAd?.load();
      return _bannerAd != null ? AdWidget(ad: _bannerAd!) : null;
    } catch (e, stackTrace) {
      LogsService.logError('AdService: Error creating banner widget', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Start timer to reload banner ad every 60 seconds
  void _startBannerReloadTimer() {
    _bannerReloadTimer?.cancel();
    _bannerReloadTimer = Timer.periodic(
      const Duration(seconds: BANNER_RELOAD_SECONDS),
      (timer) {
        if (_isInitialized && _bannerAd != null) {
          LogsService.logInfo('AdService: Reloading banner ad (60s interval)');
          getBannerWidget(); // Reload banner
        }
      },
    );
  }

  /// Dispose banner ad
  void disposeBanner() {
    _bannerReloadTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ==========================================================================
  // INTERSTITIAL AD METHODS
  // ==========================================================================
  
  /// Load an interstitial ad in advance
  void _loadInterstitial() {
    // Don't load if already loading or already loaded
    if (_isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    // Don't load if exceeded max retry attempts
    if (_interstitialRetryCount >= MAX_RETRY_ATTEMPTS) {
      LogsService.logWarning('AdService: Interstitial retry limit reached. Pausing.');
      return;
    }

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryCount = 0; // Reset retry count on success
          _setupInterstitialListeners();
          LogsService.logInfo('AdService: Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          LogsService.logError('AdService: Interstitial ad failed to load', error: error);
          _isInterstitialLoading = false;
          _interstitialAd = null;
          _interstitialRetryCount++;
          
          // Retry after delay if under max attempts
          if (_interstitialRetryCount < MAX_RETRY_ATTEMPTS) {
            LogsService.logInfo('AdService: Retrying interstitial load (attempt $_interstitialRetryCount/$MAX_RETRY_ATTEMPTS)');
            Future.delayed(const Duration(seconds: 10), () {
              if (_isInitialized) _loadInterstitial();
            });
          } else {
            LogsService.logWarning('AdService: Interstitial failed after $MAX_RETRY_ATTEMPTS attempts. Pausing retries.');
          }
        },
      ),
    );
  }

  /// Set up listeners for interstitial ad events
  void _setupInterstitialListeners() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialShown = DateTime.now();
        LogsService.logInfo('AdService: Interstitial ad dismissed. Cooldown started (${INTERSTITIAL_COOLDOWN_SECONDS}s)');
        
        // Start cooldown timer
        _startInterstitialCooldownTimer();
        
        // Pre-load next ad after cooldown
        Future.delayed(
          const Duration(seconds: INTERSTITIAL_COOLDOWN_SECONDS),
          () {
            if (_isInitialized) {
              LogsService.logInfo('AdService: Cooldown over. Loading next interstitial.');
              _loadInterstitial();
            }
          },
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        LogsService.logError('AdService: Interstitial ad failed to show', error: error);
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoading = false;
        // Try to load next ad
        Future.delayed(const Duration(seconds: 5), () {
          if (_isInitialized) _loadInterstitial();
        });
      },
      onAdShowedFullScreenContent: (_) {
        LogsService.logInfo('AdService: Interstitial ad showed successfully');
      },
    );
  }

  /// Start cooldown timer for interstitial ads
  void _startInterstitialCooldownTimer() {
    _interstitialCooldownTimer?.cancel();
    _interstitialCooldownTimer = Timer(
      const Duration(seconds: INTERSTITIAL_COOLDOWN_SECONDS),
      () {
        LogsService.logInfo('AdService: Interstitial cooldown expired. Ad can be shown again.');
      },
    );
  }

  /// Show interstitial ad if allowed (checks cooldown)
  /// 
  /// This method checks:
  /// 1. If cooldown (180 seconds) has passed since last show
  /// 2. If ad is loaded and ready
  /// 
  /// Usage example:
  /// ```dart
  /// // In a screen's initState or navigation callback:
  /// AdService.instance.showInterstitialIfAllowed();
  /// ```
  Future<void> showInterstitialIfAllowed() async {
    if (!_isInitialized) {
      LogsService.logWarning('AdService: Cannot show interstitial - not initialized');
      return;
    }

    // Check cooldown period (180 seconds)
    if (_lastInterstitialShown != null) {
      final timeSinceLastShow = DateTime.now().difference(_lastInterstitialShown!);
      if (timeSinceLastShow.inSeconds < INTERSTITIAL_COOLDOWN_SECONDS) {
        final remainingSeconds = INTERSTITIAL_COOLDOWN_SECONDS - timeSinceLastShow.inSeconds;
        LogsService.logInfo('AdService: Interstitial cooldown active. Remaining: ${remainingSeconds}s');
        return; // Cooldown not over yet
      }
    }

    // Check if ad is loaded
    if (_interstitialAd == null) {
      LogsService.logInfo('AdService: Interstitial ad not ready yet');
      // Try to load if not already loading
      if (!_isInterstitialLoading) {
        _loadInterstitial();
      }
      return;
    }

    // Show the ad
    try {
      await _interstitialAd?.show();
      LogsService.logInfo('AdService: Interstitial ad shown successfully');
    } catch (e, stackTrace) {
      LogsService.logError('AdService: Error showing interstitial', error: e, stackTrace: stackTrace);
      // Clean up failed ad
      _interstitialAd?.dispose();
      _interstitialAd = null;
      // Try to load next ad
      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized) _loadInterstitial();
      });
    }
  }

  // ==========================================================================
  // APP OPEN AD METHODS
  // ==========================================================================
  
  /// Load an App Open ad
  void _loadAppOpenAd() {
    // Don't load if disabled
    if (!enableAppOpenAds) {
      LogsService.logInfo('AdService: App Open ads are disabled');
      return;
    }

    // Don't load if already loading or already loaded
    if (_isAppOpenLoading || _appOpenAd != null) {
      return;
    }

    // Don't load if exceeded max retry attempts
    if (_appOpenRetryCount >= MAX_RETRY_ATTEMPTS) {
      LogsService.logWarning('AdService: App Open retry limit reached. Pausing.');
      return;
    }

    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _appOpenRetryCount = 0; // Reset retry count on success
          _isAppOpenAdReady = true;
          _setupAppOpenListeners();
          LogsService.logInfo('AdService: App Open ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          LogsService.logError('AdService: App Open ad failed to load', error: error);
          _isAppOpenLoading = false;
          _appOpenAd = null;
          _isAppOpenAdReady = false;
          _appOpenRetryCount++;
          
          // Retry after delay if under max attempts
          if (_appOpenRetryCount < MAX_RETRY_ATTEMPTS) {
            LogsService.logInfo('AdService: Retrying App Open load (attempt $_appOpenRetryCount/$MAX_RETRY_ATTEMPTS)');
            Future.delayed(const Duration(seconds: 10), () {
              if (_isInitialized && enableAppOpenAds) _loadAppOpenAd();
            });
          } else {
            LogsService.logWarning('AdService: App Open failed after $MAX_RETRY_ATTEMPTS attempts. Pausing retries.');
          }
        },
      ),
    );
  }

  /// Set up listeners for App Open ad events
  void _setupAppOpenListeners() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isAppOpenAdReady = false;
        _appOpenLastShownTime = DateTime.now();
        LogsService.logInfo('AdService: App Open ad dismissed');
        
        // Pre-load next App Open ad
        Future.delayed(const Duration(seconds: 2), () {
          if (_isInitialized && enableAppOpenAds) {
            _loadAppOpenAd();
          }
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        LogsService.logError('AdService: App Open ad failed to show', error: error);
        ad.dispose();
        _appOpenAd = null;
        _isAppOpenAdReady = false;
        _isAppOpenLoading = false;
        // Try to load next ad
        Future.delayed(const Duration(seconds: 5), () {
          if (_isInitialized && enableAppOpenAds) {
            _loadAppOpenAd();
          }
        });
      },
      onAdShowedFullScreenContent: (_) {
        LogsService.logInfo('AdService: App Open ad showed successfully');
      },
    );
  }

  /// Show App Open ad if available
  /// Called when app is launched or resumed from background
  Future<void> showAppOpenAdIfReady() async {
    if (!enableAppOpenAds) {
      return;
    }

    if (!_isInitialized) {
      LogsService.logWarning('AdService: Cannot show App Open - not initialized');
      return;
    }

    if (!_isAppOpenAdReady || _appOpenAd == null) {
      LogsService.logInfo('AdService: App Open ad not ready yet');
      // Try to load if not already loading
      if (!_isAppOpenLoading) {
        _loadAppOpenAd();
      }
      return;
    }

    // Show the ad
    try {
      await _appOpenAd?.show();
      LogsService.logInfo('AdService: App Open ad shown successfully');
    } catch (e, stackTrace) {
      LogsService.logError('AdService: Error showing App Open ad', error: e, stackTrace: stackTrace);
      // Clean up failed ad
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _isAppOpenAdReady = false;
      // Try to load next ad
      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized && enableAppOpenAds) {
          _loadAppOpenAd();
        }
      });
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================
  
  /// Check if AdService is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get time remaining until next interstitial can be shown (in seconds)
  int get interstitialCooldownRemaining {
    if (_lastInterstitialShown == null) return 0;
    final timeSinceLastShow = DateTime.now().difference(_lastInterstitialShown!);
    final remaining = INTERSTITIAL_COOLDOWN_SECONDS - timeSinceLastShow.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Dispose all ads and timers
  void dispose() {
    _bannerReloadTimer?.cancel();
    _interstitialCooldownTimer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
    _isInitialized = false;
  }
}


import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/services/logs_service.dart';
import 'interstitial_ad_handler.dart';
import 'rewarded_ad_handler.dart';

/// ============================================================================
/// ADS MANAGER - Centralized Ad Management System
/// ============================================================================
/// 
/// This singleton manages all ad types in the app:
/// - Banner Ads: Shown at the bottom of every screen
/// - Interstitial Ads: Full-screen ads with global cooldown and screen-specific rules
/// - Rewarded Ads: Optional premium actions
/// 
/// CONFIGURATION:
/// ==============
/// 1. Replace test ad unit IDs below with your production AdMob IDs
/// 2. For production, set kDebugMode to false or use separate production IDs
/// 
/// HOW TO ADD BANNER ADS TO A SCREEN:
/// ===================================
/// 1. Import: import 'package:your_app/ads/banner_ad_widget.dart';
/// 2. In your Scaffold body, wrap content with SafeArea and Column:
///    body: SafeArea(
///      child: Column(
///        children: [
///          Expanded(child: YourContentWidget()),
///          const BannerAdWidget(), // Add this line
///        ],
///      ),
///    ),
/// 
/// HOW TO ADD INTERSTITIAL ADS:
/// ============================
/// 1. For general screens: 
///    AdsManager.instance.showInterstitialIfAvailable();
/// 
/// 2. For "Who Is In The Picture" screen (after every 11 images):
///    AdsManager.instance.trackImageViewed();
/// 
/// 3. For "Three In One" screen (after every 10 questions):
///    AdsManager.instance.trackQuestionCompleted();
/// 
/// ============================================================================

class AdsManager {
  static AdsManager? _instance;
  static AdsManager get instance => _instance ??= AdsManager._();
  AdsManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ==========================================================================
  // AD UNIT IDS CONFIGURATION
  // ==========================================================================
  // Replace these with your actual AdMob Ad Unit IDs from AdMob Console
  // Test IDs are provided for development (they show test ads)
  // Production IDs should be obtained from: https://apps.admob.com
  
  static const bool _useTestAds = kDebugMode; // Set to false for production
  
  static String get _bannerAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Test Android Banner
          : 'ca-app-pub-3940256099942544/2934735716'; // Test iOS Banner
    }
    // TODO: Replace with your production banner ad unit IDs
    return Platform.isAndroid
        ? 'YOUR_PRODUCTION_ANDROID_BANNER_AD_UNIT_ID'
        : 'YOUR_PRODUCTION_IOS_BANNER_AD_UNIT_ID';
  }

  static String get _nativeAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110' // Test Android Native
          : 'ca-app-pub-3940256099942544/3986624511'; // Test iOS Native
    }
    // TODO: Replace with your production native ad unit IDs
    return Platform.isAndroid
        ? 'YOUR_PRODUCTION_ANDROID_NATIVE_AD_UNIT_ID'
        : 'YOUR_PRODUCTION_IOS_NATIVE_AD_UNIT_ID';
  }

  static String get _interstitialAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Test Android Interstitial
          : 'ca-app-pub-3940256099942544/4411468910'; // Test iOS Interstitial
    }
    // TODO: Replace with your production interstitial ad unit IDs
    return Platform.isAndroid
        ? 'YOUR_PRODUCTION_ANDROID_INTERSTITIAL_AD_UNIT_ID'
        : 'YOUR_PRODUCTION_IOS_INTERSTITIAL_AD_UNIT_ID';
  }

  static String get _rewardedAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test Android Rewarded
          : 'ca-app-pub-3940256099942544/1712485313'; // Test iOS Rewarded
    }
    // TODO: Replace with your production rewarded ad unit IDs
    return Platform.isAndroid
        ? 'YOUR_PRODUCTION_ANDROID_REWARDED_AD_UNIT_ID'
        : 'YOUR_PRODUCTION_IOS_REWARDED_AD_UNIT_ID';
  }

  // ==========================================================================
  // AD INSTANCES
  // ==========================================================================
  BannerAd? _bannerAd;
  InterstitialAdHandler? _interstitialHandler;
  RewardedAdHandler? _rewardedHandler;

  // ==========================================================================
  // SCREEN-SPECIFIC COUNTERS FOR INTERSTITIAL ADS
  // ==========================================================================
  // Track counters for screen-specific interstitial rules
  int _whoIsInPictureImageCount = 0; // Show ad after every 11 images
  static const int _whoIsInPictureThreshold = 11;

  int _threeInOneQuestionCount = 0; // Show ad after every 10 questions
  static const int _threeInOneThreshold = 10;

  /// Initialize AdMob SDK and mediation
  Future<void> initialize() async {
    if (_isInitialized) {
      LogsService.logInfo('AdsManager already initialized');
      return;
    }

    try {
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Request configuration for mediation
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: kDebugMode 
              ? ['TEST-DEVICE-ID'] // Add your test device ID for testing
              : [],
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );

      // Initialize handlers with ad unit IDs
      _interstitialHandler = InterstitialAdHandler(_interstitialAdUnitId);
      _rewardedHandler = RewardedAdHandler(_rewardedAdUnitId);

      // Pre-load interstitial ad for better user experience
      loadInterstitial();

      _isInitialized = true;
      LogsService.logInfo('AdsManager initialized successfully');
    } catch (e, stackTrace) {
      LogsService.logError('Failed to initialize AdsManager', error: e, stackTrace: stackTrace);
      // Continue without crashing - ads will simply not show
      _isInitialized = false;
    }
  }

  // ==========================================================================
  // BANNER AD METHODS
  // ==========================================================================

  /// Get Banner Ad Widget - loads and returns a widget
  /// 
  /// Usage in screens:
  /// const BannerAdWidget() // This widget handles loading automatically
  /// 
  /// This method is called internally by BannerAdWidget, you typically
  /// don't need to call it directly.
  Widget? getBannerWidget() {
    if (!_isInitialized) return null;
    
    try {
      // Dispose existing banner if any
      _bannerAd?.dispose();
      
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            LogsService.logInfo('Banner ad loaded');
          },
          onAdFailedToLoad: (ad, error) {
            LogsService.logError('Banner ad failed to load', error: error);
            ad.dispose();
          },
          onAdOpened: (_) {
            LogsService.logInfo('Banner ad opened');
          },
          onAdClosed: (_) {
            LogsService.logInfo('Banner ad closed');
          },
        ),
      );

      _bannerAd?.load();
      return _bannerAd != null ? AdWidget(ad: _bannerAd!) : null;
    } catch (e, stackTrace) {
      LogsService.logError('Error creating banner widget', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Dispose banner ad
  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ==========================================================================
  // INTERSTITIAL AD METHODS
  // ==========================================================================

  /// Show interstitial ad if available (respects global 180-second cooldown)
  /// 
  /// Usage:
  /// - Call this when navigating to heavy screens or after user actions
  /// - Example: AdsManager.instance.showInterstitialIfAvailable();
  /// 
  /// Note: Ad will only show if:
  /// 1. Ad is loaded and ready
  /// 2. Global cooldown (180 seconds) has passed since last interstitial
  Future<void> showInterstitialIfAvailable() async {
    if (!_isInitialized) return;
    await _interstitialHandler?.showIfAvailable();
  }

  /// Load interstitial ad in advance
  /// 
  /// This is called automatically during initialization.
  /// You can call this manually to preload the next ad after showing one.
  void loadInterstitial() {
    if (!_isInitialized) return;
    _interstitialHandler?.load();
  }

  /// Track image viewed in "Who Is In The Picture" screen
  /// 
  /// Shows interstitial ad after every 11 images viewed.
  /// 
  /// Usage in WhoIsInPictureScreen:
  /// - Call this when user views/reveals an image
  /// - Example: AdsManager.instance.trackImageViewed();
  Future<void> trackImageViewed() async {
    if (!_isInitialized) return;
    
    _whoIsInPictureImageCount++;
    LogsService.logInfo('Image viewed. Count: $_whoIsInPictureImageCount/$_whoIsInPictureThreshold');
    
    // Show ad when threshold is reached
    if (_whoIsInPictureImageCount >= _whoIsInPictureThreshold) {
      _whoIsInPictureImageCount = 0; // Reset counter
      await showInterstitialIfAvailable();
    }
  }

  /// Track question completed in "Three In One" screen
  /// 
  /// Shows interstitial ad after every 10 questions completed.
  /// 
  /// Usage in ThreeInOneScreen:
  /// - Call this when user completes/advances to next question
  /// - Example: AdsManager.instance.trackQuestionCompleted();
  Future<void> trackQuestionCompleted() async {
    if (!_isInitialized) return;
    
    _threeInOneQuestionCount++;
    LogsService.logInfo('Question completed. Count: $_threeInOneQuestionCount/$_threeInOneThreshold');
    
    // Show ad when threshold is reached
    if (_threeInOneQuestionCount >= _threeInOneThreshold) {
      _threeInOneQuestionCount = 0; // Reset counter
      await showInterstitialIfAvailable();
    }
  }

  /// Show rewarded ad if available
  Future<bool> showRewardedIfAvailable(Function() onRewardEarned) async {
    if (!_isInitialized) return false;
    return await _rewardedHandler?.showIfAvailable(onRewardEarned) ?? false;
  }

  /// Load rewarded ad in advance
  void loadRewarded() {
    if (!_isInitialized) return;
    _rewardedHandler?.load();
  }

  /// Get Native Ad Unit ID (for use in NativeAdWidget)
  String get nativeAdUnitId => _nativeAdUnitId;

  /// Get Interstitial Ad Unit ID
  String get interstitialAdUnitId => _interstitialAdUnitId;

  /// Get Rewarded Ad Unit ID
  String get rewardedAdUnitId => _rewardedAdUnitId;

  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialHandler?.dispose();
    _rewardedHandler?.dispose();
  }
}


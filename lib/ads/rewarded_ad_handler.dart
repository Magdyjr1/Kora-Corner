import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/services/logs_service.dart';

/// Handles rewarded ads
/// 
/// This is managed internally by AdsManager - you typically don't
/// need to interact with this class directly.
class RewardedAdHandler {
  final String _adUnitId;
  
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  RewardedAdHandler(this._adUnitId);

  /// Load a rewarded ad
  void load() {
    // Don't load if already loading or already loaded
    if (_isLoading || _rewardedAd != null) return;
    
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          _setupAdListeners();
          LogsService.logInfo('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          LogsService.logError('Rewarded ad failed to load', error: error);
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void _setupAdListeners() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Pre-load next ad
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        LogsService.logError('Rewarded ad failed to show', error: error);
        ad.dispose();
        _rewardedAd = null;
        _isLoading = false;
      },
      onAdShowedFullScreenContent: (_) {
        LogsService.logInfo('Rewarded ad showed');
      },
    );
  }

  /// Show rewarded ad if available
  /// Returns true if ad was shown, false otherwise
  /// onRewardEarned is called ONLY when user earns the reward
  Future<bool> showIfAvailable(Function() onRewardEarned) async {
    // Check if ad is loaded
    if (_rewardedAd == null) {
      // Try to load if not loading
      if (!_isLoading) {
        load();
      }
      return false;
    }

    try {
      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          LogsService.logInfo('User earned reward: ${reward.type} - ${reward.amount}');
          // Only call the callback when reward is actually earned
          onRewardEarned();
        },
      );
      return true;
    } catch (e, stackTrace) {
      LogsService.logError('Error showing rewarded ad', error: e, stackTrace: stackTrace);
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return false;
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}


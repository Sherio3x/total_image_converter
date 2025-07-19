import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String interstitialAdUnitId = 'ca-app-pub-5920925172530143/5617060626';
  static const String rewardedAdUnitId = 'ca-app-pub-5920925172530143/4659202174';

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static bool _isInterstitialAdLoaded = false;
  static bool _isRewardedAdLoaded = false;

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // Load Interstitial Ad
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // Load Rewarded Ad
  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  // Show Interstitial Ad
  static void showInterstitialAd() {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdLoaded = false;
      // Load a new ad for next time
      loadInterstitialAd();
    }
  }

  // Show Rewarded Ad
  static Future<bool> showRewardedAd() async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      return false;
    }

    bool rewardEarned = false;

    _rewardedAd!.setImmersiveMode(true);
    
    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
      },
    );

    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    // Load a new ad for next time
    loadRewardedAd();

    return rewardEarned;
  }

  // Check if rewarded ad is ready
  static bool isRewardedAdReady() {
    return _isRewardedAdLoaded && _rewardedAd != null;
  }

  // Dispose ads
  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}


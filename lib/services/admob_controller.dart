import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// Centralized controller for managing AdMob ads, Tracking permissions and Easter Egg state
class AdmobController extends ChangeNotifier {
  static final AdmobController instance = AdmobController._internal();
  
  AdmobController._internal();

  bool _initialized = false;
  bool _adsDisabled = false;
  int _actionCount = 0;
  int _easterEggTaps = 0;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  bool get adsDisabled => _adsDisabled;
  bool get isInitialized => _initialized;

  // Initialize the Mobile Ads SDK and tracking permission
  Future<void> init() async {
    if (_initialized) return;

    // 1. Request Tracking Authorization (only on iOS)
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // Safe fallback if tracking package throws or not iOS
    }

    // 2. Initialize Mobile Ads SDK
    await MobileAds.instance.initialize();
    _initialized = true;

    // 3. Preload first interstitial ad
    _loadInterstitialAd();
  }

  // Easter Egg tap tracking
  void incrementEasterEggTaps(BuildContext context, VoidCallback onAdsDisabled) {
    if (_adsDisabled) return;
    _easterEggTaps++;
    if (_easterEggTaps >= 15) {
      _adsDisabled = true;
      notifyListeners();
      onAdsDisabled();

      // Clean up loaded interstitial ad
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  // Track action count to trigger Interstitial Ads
  void trackAction(BuildContext context) {
    if (_adsDisabled) return;
    _actionCount++;
    if (_actionCount % 4 == 0) {
      _showInterstitialAd();
    }
  }

  // Preload an interstitial ad in the background
  void _loadInterstitialAd() {
    if (_adsDisabled || _isInterstitialAdLoading || _interstitialAd != null) return;
    _isInterstitialAdLoading = true;

    final adUnitId = kDebugMode
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712' // Android Test Interstitial
            : 'ca-app-pub-3940256099942544/4411468910') // iOS Test Interstitial
        : (Platform.isAndroid
            ? 'ca-app-pub-4671549534107534/1372293589' // Android Prod Interstitial
            : 'ca-app-pub-4671549534107534/1954747514'); // iOS Prod Interstitial

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Preload next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Preload next one
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  // Display the preloaded Interstitial Ad
  void _showInterstitialAd() {
    if (_adsDisabled || _interstitialAd == null) {
      // If not loaded, reload in the background
      if (_interstitialAd == null) {
        _loadInterstitialAd();
      }
      return;
    }
    _interstitialAd!.show();
  }
}

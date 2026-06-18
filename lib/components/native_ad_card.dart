import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_controller.dart';
import '../theme/app_theme.dart';

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    
    // Listen to changes in AdmobController (e.g. if ads get disabled via Easter Egg)
    AdmobController.instance.addListener(_handleAdmobStateChange);
  }

  void _handleAdmobStateChange() {
    if (AdmobController.instance.adsDisabled) {
      if (mounted) {
        setState(() {
          _nativeAd?.dispose();
          _nativeAd = null;
          _isAdLoaded = false;
        });
      }
    } else {
      if (mounted && _nativeAd == null && !_isAdLoaded) {
        _loadAd();
      }
    }
  }

  void _loadAd() {
    if (AdmobController.instance.adsDisabled) return;

    final adUnitId = kDebugMode
        ? (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/2247696110' // Android Test Native Ad
            : 'ca-app-pub-3940256099942544/3986694507') // iOS Test Native Ad
        : (Platform.isAndroid
            ? 'ca-app-pub-4671549534107534/8469174656' // Android Prod Native Ad
            : 'ca-app-pub-4671549534107534/3481102084'); // iOS Prod Native Ad

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 16.0,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textMuted,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textMuted,
          size: 12.0,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          backgroundColor: AppColors.primary,
          textColor: AppColors.textLight,
          size: 14.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdmobController.instance.removeListener(_handleAdmobStateChange);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdmobController.instance.adsDisabled || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

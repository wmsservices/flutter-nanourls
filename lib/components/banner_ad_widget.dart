import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_controller.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
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
          _bannerAd?.dispose();
          _bannerAd = null;
          _isAdLoaded = false;
        });
      }
    }
  }

  void _loadAd() {
    if (AdmobController.instance.adsDisabled) return;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111' // Android Test Banner ID
        : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner ID

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
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
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdmobController.instance.adsDisabled || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

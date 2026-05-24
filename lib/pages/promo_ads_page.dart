import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';

class PromoAdsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const PromoAdsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<PromoAdsPage> createState() => _PromoAdsPageState();
}

class _PromoAdsPageState extends State<PromoAdsPage> {
  gma.BannerAd? _bannerAd1;
  gma.BannerAd? _bannerAd2;
  bool _isAdLoaded1 = false;
  bool _isAdLoaded2 = false;
  bool _adsSupported = false;

  @override
  void initState() {
    super.initState();
    _adsSupported =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        kIsWeb;
    if (_adsSupported) {
      _initializeBannerAds();
    }
  }

  void _initializeBannerAds() {
    // Test Banner Ad 1
    _bannerAd1 = gma.BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: gma.AdSize.banner,
      request: const gma.AdRequest(),
      listener: gma.BannerAdListener(
        onAdLoaded: (gma.Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded1 = true;
            });
          }
        },
        onAdFailedToLoad: (gma.Ad ad, gma.LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd1!.load();

    // Test Banner Ad 2 (Medium Rectangle)
    _bannerAd2 = gma.BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: gma.AdSize.mediumRectangle,
      request: const gma.AdRequest(),
      listener: gma.BannerAdListener(
        onAdLoaded: (gma.Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded2 = true;
            });
          }
        },
        onAdFailedToLoad: (gma.Ad ad, gma.LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd2!.load();
  }

  @override
  void dispose() {
    _bannerAd1?.dispose();
    _bannerAd2?.dispose();
    super.dispose();
  }

  Widget _buildAdsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Test Mobile Ads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Standard Banner Ad (320x50)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_isAdLoaded1)
          SizedBox(width: 320, height: 50, child: gma.AdWidget(ad: _bannerAd1!))
        else
          Container(
            width: 320, height: 50,
            color: Colors.grey.shade200,
            child: const Center(child: Text('Banner Ad Loading...')),
          ),
        const SizedBox(height: 24),
        const Text('Medium Rectangle Ad (300x250)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_isAdLoaded2)
          SizedBox(width: 300, height: 250, child: gma.AdWidget(ad: _bannerAd2!))
        else
          Container(
            width: 300, height: 250,
            color: Colors.grey.shade200,
            child: const Center(child: Text('Medium Rectangle Ad Loading...')),
          ),
        const SizedBox(height: 24),
        Card(
          color: Colors.amber[50],
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Using Google Test Ad Units', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                SizedBox(height: 8),
                Text(
                  'These are Google-provided test ad units for development and testing. '
                  'Replace with your actual Ad Unit IDs before publishing.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 48, color: const Color(0xFFB08B1E)),
        const SizedBox(height: 16),
        const Text('Mobile Ads Not Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Google Mobile Ads are only available on iOS, Android, and Web platforms. '
          'Test this feature on a mobile device or emulator.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: widget.appState,
        onAppStateChanged: widget.onAppStateChanged,
      ),
      appBar: const TournaQAppBar(title: 'Promo & Updates'),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: _adsSupported ? _buildAdsContent() : _buildUnsupportedContent(),
      ),
    );
  }
}

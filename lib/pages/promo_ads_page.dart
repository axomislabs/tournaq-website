import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import '../config/ad_config.dart';
import '../config/contact_links.dart';
import '../services/consent_service.dart';
import '../services/rating_service.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import 'coming_soon_page.dart';

const _kGold = Color(0xFFA97800);
const _kGoldLight = Color(0xFFFFF8E1);
const _kOlive = Color(0xFF556B2F);
const _kOliveLight = Color(0xFFEEF2E6);

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
  gma.BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _adsSupported = false;

  static const _adRequest = gma.AdRequest(nonPersonalizedAds: true);

  @override
  void initState() {
    super.initState();
    _adsSupported =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        kIsWeb;
    if (_adsSupported) {
      if (ConsentService.mobileAdsReady) {
        _loadBannerAd();
      } else {
        // Consent flow still in progress — wait for it then load.
        ConsentService.initialize().then((_) {
          if (mounted && !_isAdLoaded) _loadBannerAd();
        });
      }
    }
  }

  void _loadBannerAd() {
    _bannerAd = gma.BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: gma.AdSize.banner,
      request: _adRequest,
      listener: gma.BannerAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _isAdLoaded = true); },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _openComingSoon(String title, String description) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonPage(title: title, shortDescription: description),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: widget.appState,
        onAppStateChanged: widget.onAppStateChanged,
      ),
      appBar: const TournaQAppBar(title: 'Sponsoring & Promo'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/tournaq_background.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: _buildIntroCard(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader('Sponsoring', Icons.campaign_rounded),
                      const SizedBox(height: 10),
                      _buildAdSection(),
                      const SizedBox(height: 8),
                      _buildInstagramCard(),
                      const SizedBox(height: 8),
                      _buildRatingCard(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Opportunities', Icons.handshake_rounded),
                      const SizedBox(height: 10),
                      _buildComingSoonCard(
                        icon: Icons.stars_rounded,
                        title: 'Partner Spotlight',
                        subtitle: 'Future partners, clubs and organizations may be featured here.',
                      ),
                      const SizedBox(height: 8),
                      _buildComingSoonCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Tournament Partnerships',
                        subtitle: 'Support for tournament organizers and event partnerships.',
                      ),
                      const SizedBox(height: 8),
                      _buildComingSoonCard(
                        icon: Icons.celebration_rounded,
                        title: 'Promote Your Event',
                        subtitle: 'Future opportunities to showcase tournaments, leagues and events.',
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Get Involved', Icons.chat_rounded),
                      const SizedBox(height: 10),
                      _buildFeedbackCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kOlive),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kOlive,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _kGoldLight, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: _kGold, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support TournaQ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kOlive,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Advertising and sponsorship help support the continued development of TournaQ.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            if (_adsSupported)
              _isAdLoaded
                  ? Center(
                      child: SizedBox(
                        width: 320,
                        height: 50,
                        child: gma.AdWidget(ad: _bannerAd!),
                      ),
                    )
                  : Container(
                      width: 320,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'Advertisement',
                          style: TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                      ),
                    )
            else
              Container(
                width: 320,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Ads available on iOS & Android',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for supporting TournaQ.',
              style: TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: _kOliveLight, shape: BoxShape.circle),
          child: Icon(icon, color: _kOlive, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB0BA78)),
          ),
          child: const Text(
            'Coming Soon',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6E7640)),
          ),
        ),
        onTap: () => _openComingSoon(title, subtitle),
      ),
    );
  }

  Widget _buildInstagramCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: _kOliveLight, shape: BoxShape.circle),
          child: const Icon(Icons.camera_alt_rounded, color: _kOlive, size: 20),
        ),
        title: const Text(
          'Follow the Journey',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: const Text(
          'Share events and games where TournaQ supported you — tag us on Instagram.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 22),
        onTap: () => openExternalUrl(context, ContactLinks.instagram),
      ),
    );
  }

  Widget _buildRatingCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: _kGoldLight, shape: BoxShape.circle),
          child: const Icon(Icons.star_rounded, color: _kGold, size: 20),
        ),
        title: const Text(
          'Enjoying TournaQ?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: const Text(
          'Ratings help us reach more players and organizers.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 22),
        onTap: () => RatingService.showRatingDialog(context),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: _kGold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Help Shape TournaQ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kOlive),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'We welcome suggestions and ideas for future features and partnerships.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => openExternalUrl(context, ContactLinks.feedbackForm),
              icon: const Icon(Icons.feedback_rounded, size: 17),
              label: const Text('Give Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openEmail(context, ContactLinks.contactEmail),
              icon: const Icon(Icons.email_rounded, size: 17),
              label: const Text('Email Us'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kOlive,
                side: BorderSide(color: _kOlive.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import '../config/ad_config.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../app/app_assets.dart';
import '../l10n/app_localizations.dart';
import '../services/consent_service.dart';
import '../services/rating_service.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import 'coming_soon_page.dart';

const _kGold = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

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
        onAdLoaded: (_) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ComingSoonPage(title: title, shortDescription: description),
      ),
    );
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
              AppAssets.background,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.06),
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: _buildIntroCard(l10n),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(l10n.sectionSponsoring, Icons.campaign_rounded),
                const SizedBox(height: 10),
                _buildAdSection(l10n),
                const SizedBox(height: 8),
                _buildInstagramCard(l10n),
                const SizedBox(height: 8),
                _buildRatingCard(l10n),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.sectionOpportunities, Icons.handshake_rounded),
                const SizedBox(height: 10),
                _buildComingSoonCard(
                  icon: Icons.stars_rounded,
                  title: l10n.promoPartnerSpotlight,
                  subtitle: l10n.promoPartnerSpotlightSub,
                ),
                const SizedBox(height: 8),
                _buildComingSoonCard(
                  icon: Icons.emoji_events_rounded,
                  title: l10n.promoTournamentPartnerships,
                  subtitle: l10n.promoTournamentPartnershipsSub,
                ),
                const SizedBox(height: 8),
                _buildComingSoonCard(
                  icon: Icons.celebration_rounded,
                  title: l10n.promoPromoteEvent,
                  subtitle: l10n.promoPromoteEventSub,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.sectionGetInvolved, Icons.chat_rounded),
                const SizedBox(height: 10),
                _buildFeedbackCard(l10n),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildIntroCard(AppLocalizations l10n) {
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
              decoration: const BoxDecoration(
                color: _kGoldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: _kGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.promoSupportTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kOlive,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.promoSupportSubtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSection(AppLocalizations l10n) {
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
                      child: Center(
                        child: Text(
                          l10n.promoAdPlaceholder,
                          style: const TextStyle(fontSize: 12, color: Colors.black38),
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
                child: Center(
                  child: Text(
                    l10n.promoAdNotSupported,
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.promoAdThankYou,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
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
    final l10n = AppLocalizations.of(context)!;
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
            color: AppColors.goldCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.comingSoonBorder),
          ),
          child: Text(
            l10n.comingSoon,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.oliveMedium,
            ),
          ),
        ),
        onTap: () => _openComingSoon(title, subtitle),
      ),
    );
  }

  Widget _buildInstagramCard(AppLocalizations l10n) {
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
        title: Text(l10n.promoFollowTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(l10n.promoFollowSubtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 22),
        onTap: () => openExternalUrl(context, AppLinks.instagram),
      ),
    );
  }

  Widget _buildRatingCard(AppLocalizations l10n) {
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
        title: Text(l10n.promoRateTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(l10n.promoRateSubtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 22),
        onTap: () => RatingService.showRatingDialog(context),
      ),
    );
  }

  Widget _buildFeedbackCard(AppLocalizations l10n) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: _kGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.promoHelpTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kOlive),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.promoHelpSubtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => openExternalUrl(context, AppLinks.feedbackForm),
              icon: const Icon(Icons.feedback_rounded, size: 17),
              label: Text(l10n.btnGiveFeedback),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openEmail(context, AppLinks.contactEmail),
              icon: const Icon(Icons.email_rounded, size: 17),
              label: Text(l10n.btnEmailUs),
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

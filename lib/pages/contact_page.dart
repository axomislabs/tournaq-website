import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

class ContactPage extends StatefulWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const ContactPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _launchInstagram(BuildContext context) =>
      openExternalUrl(context, AppLinks.instagram);

  Future<void> _launchEmail(BuildContext context) =>
      openEmail(context, AppLinks.contactEmail);

  Future<void> _launchFeedback(BuildContext context) =>
      openExternalUrl(context, AppLinks.feedbackForm);

  Future<void> _launchWebsite(BuildContext context) =>
      openExternalUrl(context, AppLinks.website);

  Future<void> _launchUserGuide(BuildContext context) =>
      openExternalUrl(context, AppLinks.userGuide);

  Future<void> _launchPrivacyPolicy(BuildContext context) =>
      openExternalUrl(context, AppLinks.privacyPolicy);

  Future<void> _launchTermsOfUse(BuildContext context) =>
      openExternalUrl(context, AppLinks.termsOfUse);

  Future<void> _launchLegalNotice(BuildContext context) =>
      openExternalUrl(context, AppLinks.legalNotice);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppDrawer(
        appState: widget.appState,
        onAppStateChanged: widget.onAppStateChanged,
      ),
      appBar: TournaQAppBar(title: l10n.navContact),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(l10n.contactSectionSocial, Icons.people_alt_rounded, [
              _buildClickableCard(
                context,
                icon: Icons.camera_alt_rounded,
                iconBg: AppColors.instagramPink,
                iconColor: Colors.white,
                title: l10n.contactInstagram,
                subtitle: l10n.contactInstagramHandle,
                onTap: () => _launchInstagram(context),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSection(
              l10n.contactSectionSupport,
              Icons.support_agent_rounded,
              [
                _buildClickableCard(
                  context,
                  icon: Icons.email_rounded,
                  iconBg: _kGoldLight,
                  iconColor: _kGold,
                  title: l10n.contactEmailLabel,
                  subtitle: AppLinks.contactEmail,
                  onTap: () => _launchEmail(context),
                ),
                _buildClickableCard(
                  context,
                  icon: Icons.feedback_rounded,
                  iconBg: _kGoldLight,
                  iconColor: _kGold,
                  title: l10n.contactFeedbackForm,
                  subtitle: l10n.contactFeedbackSubtitle,
                  onTap: () => _launchFeedback(context),
                ),
                _buildClickableCard(
                  context,
                  icon: Icons.language_rounded,
                  iconBg: _kOliveLight,
                  iconColor: _kOlive,
                  title: l10n.contactWebsite,
                  subtitle: l10n.contactWebsiteSubtitle,
                  onTap: () => _launchWebsite(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              l10n.contactSectionResources,
              Icons.library_books_rounded,
              [
                _buildClickableCard(
                  context,
                  icon: Icons.menu_book_rounded,
                  iconBg: _kGoldLight,
                  iconColor: _kGold,
                  title: l10n.contactUserGuide,
                  subtitle: l10n.contactUserGuideSub,
                  onTap: () => _launchUserGuide(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(l10n.contactSectionLegal, Icons.shield_rounded, [
              _buildClickableCard(
                context,
                icon: Icons.privacy_tip_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                title: l10n.contactPrivacyPolicy,
                subtitle: l10n.contactPrivacyPolicySub,
                onTap: () => _launchPrivacyPolicy(context),
              ),
              _buildClickableCard(
                context,
                icon: Icons.description_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                title: l10n.contactTermsOfUse,
                subtitle: l10n.contactTermsOfUseSub,
                onTap: () => _launchTermsOfUse(context),
              ),
              _buildClickableCard(
                context,
                icon: Icons.account_balance_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                title: l10n.contactLegalNotice,
                subtitle: l10n.contactLegalNoticeSub,
                onTap: () => _launchLegalNotice(context),
              ),
            ]),
            const SizedBox(height: 32),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 10),
        ...cards,
      ],
    );
  }

  Widget _buildClickableCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData trailing = Icons.open_in_new_rounded,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Icon(trailing, size: 18, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFooter() {
    final versionLabel = _version != null ? 'TournaQ v$_version' : 'TournaQ';
    return Column(
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Text(
          versionLabel,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

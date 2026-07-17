import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../utils/url_utils.dart';
import '../widgets/clickable_card.dart';
import '../widgets/qr_export_sheet.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

/// "Become a Tester" hub, reached from the More page. Built around the
/// coach-hands-someone-a-phone workflow: a QR code lets a bystander install
/// or sign up immediately, without typing a link. iOS can install directly
/// via TestFlight; Android has no direct install link, since testers must be
/// added to the program by hand, so the sign-up form is mandatory there
/// (recommended, not mandatory, for iOS).
class BecomeTestUserPage extends StatelessWidget {
  const BecomeTestUserPage({super.key});

  Future<void> _showTestFlightQr(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showQrExportSheet(
      context,
      title: l10n.testerIOSDownloadTitle,
      subtitle: l10n.testerIOSDownloadSubtitle,
      data: AppLinks.testFlightJoin,
    );
  }

  Future<void> _showSignupQr(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showQrExportSheet(
      context,
      title: l10n.testerSignupQRTitle,
      subtitle: l10n.testerSignupQRSubtitle,
      data: AppLinks.betaSignupForm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(title: l10n.navBecomeTester),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.testerIntro,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            _buildSection(l10n.testerSectionIOS, Icons.phone_iphone_rounded, [
              ClickableCard(
                icon: Icons.qr_code_2_rounded,
                iconBg: _kGoldLight,
                iconColor: _kGold,
                title: l10n.testerIOSDownloadTitle,
                subtitle: l10n.testerIOSDownloadSubtitle,
                trailing: Icons.qr_code_rounded,
                onTap: () => _showTestFlightQr(context),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              l10n.testerNoteIOS,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 22),
            _buildSection(l10n.testerSectionSignup, Icons.how_to_reg_rounded, [
              ClickableCard(
                icon: Icons.qr_code_2_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                title: l10n.testerSignupQRTitle,
                subtitle: l10n.testerSignupQRSubtitle,
                trailing: Icons.qr_code_rounded,
                onTap: () => _showSignupQr(context),
              ),
              ClickableCard(
                icon: Icons.open_in_new_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                title: l10n.testerSignupLinkTitle,
                subtitle: l10n.testerSignupLinkSubtitle,
                onTap: () => openExternalUrl(context, AppLinks.betaSignupForm),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              l10n.testerNoteAndroid,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 28),
            _buildContactCallout(context, l10n),
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

  Widget _buildContactCallout(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGoldLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.testerContactTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.testerContactBody,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => openEmail(context, AppLinks.contactEmail),
              icon: const Icon(Icons.email_rounded, size: 18),
              label: Text(
                l10n.testerContactButton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

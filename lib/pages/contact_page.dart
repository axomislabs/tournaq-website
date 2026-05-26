import 'package:flutter/material.dart';
import '../config/contact_links.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'privacy_policy_page.dart';
import 'terms_of_use_page.dart';

const _kGold = Color(0xFFA97800);
const _kGoldLight = Color(0xFFFFF8E1);
const _kOlive = Color(0xFF556B2F);
const _kOliveLight = Color(0xFFEEF2E6);

class ContactPage extends StatelessWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const ContactPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  Future<void> _launchInstagram(BuildContext context) =>
      openExternalUrl(context, ContactLinks.instagram);

  Future<void> _launchEmail(BuildContext context) =>
      openEmail(context, ContactLinks.contactEmail);

  Future<void> _launchFeedback(BuildContext context) =>
      openExternalUrl(context, ContactLinks.feedbackForm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: appState, onAppStateChanged: onAppStateChanged),
      appBar: const TournaQAppBar(title: 'Contact & About'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _buildBranding(),
          const SizedBox(height: 28),
          _buildSection('Social', Icons.people_alt_rounded, [
            _buildClickableCard(
              context,
              icon: Icons.camera_alt_rounded,
              iconBg: const Color(0xFFE1306C),
              iconColor: Colors.white,
              title: 'Instagram',
              subtitle: '@tournaq',
              onTap: () => _launchInstagram(context),
            ),
            _buildClickableCard(
              context,
              icon: Icons.email_rounded,
              iconBg: _kGoldLight,
              iconColor: _kGold,
              title: 'Email',
              subtitle: ContactLinks.contactEmail,
              onTap: () => _launchEmail(context),
            ),
            _buildDisabledCard(
              icon: Icons.language_rounded,
              iconBg: _kOliveLight,
              iconColor: _kOlive,
              title: 'Website',
              subtitle: 'Coming Soon',
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Support', Icons.support_agent_rounded, [
            _buildClickableCard(
              context,
              icon: Icons.feedback_rounded,
              iconBg: _kGoldLight,
              iconColor: _kGold,
              title: 'Send Feedback',
              subtitle: 'Share your thoughts',
              onTap: () => _launchFeedback(context),
            ),
            _buildClickableCard(
              context,
              icon: Icons.bug_report_rounded,
              iconBg: const Color(0xFFFFEBEE),
              iconColor: Colors.red.shade400,
              title: 'Report Issue',
              subtitle: 'Let us know what went wrong',
              onTap: () => _launchFeedback(context),
            ),
            _buildClickableCard(
              context,
              icon: Icons.lightbulb_rounded,
              iconBg: _kOliveLight,
              iconColor: _kOlive,
              title: 'Feature Request',
              subtitle: 'Suggest something new',
              onTap: () => _launchFeedback(context),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Legal', Icons.gavel_rounded, [
            _buildClickableCard(
              context,
              icon: Icons.shield_rounded,
              iconBg: _kOliveLight,
              iconColor: _kOlive,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              trailing: Icons.chevron_right_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
            _buildClickableCard(
              context,
              icon: Icons.description_rounded,
              iconBg: _kGoldLight,
              iconColor: _kGold,
              title: 'Terms of Use',
              subtitle: 'Rules for using TournaQ',
              trailing: Icons.chevron_right_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
              ),
            ),
          ]),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Image.asset(
          'assets/tournaq_icon.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 12),
        const Text(
          'TournaQ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kOlive,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Scoring, Games and Tournament Management',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: Icon(trailing, size: 18, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDisabledCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.grey.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor.withValues(alpha: 0.5), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black45),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black38),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        const Text(
          'Version: MVP v0.1.0',
          style: TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Built with TournaQ',
          style: TextStyle(fontSize: 11, color: Colors.black26),
        ),
      ],
    );
  }
}

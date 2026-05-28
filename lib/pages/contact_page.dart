import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
      openExternalUrl(context, ContactLinks.instagram);

  Future<void> _launchEmail(BuildContext context) =>
      openEmail(context, ContactLinks.contactEmail);

  Future<void> _launchFeedback(BuildContext context) =>
      openExternalUrl(context, ContactLinks.feedbackForm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: widget.appState, onAppStateChanged: widget.onAppStateChanged),
      appBar: const TournaQAppBar(title: 'Contact & About'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Contact & Support', Icons.support_agent_rounded, [
                    _buildClickableCard(
                      context,
                      icon: Icons.email_rounded,
                      iconBg: _kGoldLight,
                      iconColor: _kGold,
                      title: 'Email',
                      subtitle: ContactLinks.contactEmail,
                      onTap: () => _launchEmail(context),
                    ),
                    _buildClickableCard(
                      context,
                      icon: Icons.feedback_rounded,
                      iconBg: _kGoldLight,
                      iconColor: _kGold,
                      title: 'Feedback Form',
                      subtitle: 'Feedback, bugs and feature requests',
                      onTap: () => _launchFeedback(context),
                    ),
                    _buildDisabledCard(
                      icon: Icons.language_rounded,
                      iconBg: const Color(0xFFF5F5F5),
                      iconColor: Colors.black26,
                      title: 'Website',
                      subtitle: 'Coming soon',
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
      color: const Color(0xFFF9F9F9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black38)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black26)),
        trailing: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black26),
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


  Widget _buildFooter() {
    final versionLabel = _version != null ? 'TournaQ v$_version' : 'TournaQ';
    return Column(
      children: [
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        Text(
          versionLabel,
          style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

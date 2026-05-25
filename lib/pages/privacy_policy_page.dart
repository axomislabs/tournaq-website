import 'package:flutter/material.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

const _kOlive = Color(0xFF556B2F);

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(title: 'Privacy Policy'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateBadge('Last updated: May 2026'),
            const SizedBox(height: 20),
            _buildSection(
              Icons.info_outline_rounded,
              'Overview',
              'TournaQ ("we", "us", or "the app") is committed to protecting your privacy. '
              'This Privacy Policy explains how TournaQ handles information when you use the app.\n\n'
              'TournaQ is designed to operate entirely on your device. We do not require an account, '
              'and no personal data is transmitted to external servers.',
            ),
            _buildSection(
              Icons.storage_rounded,
              'Information We Collect',
              'TournaQ stores the following data locally on your device only:\n\n'
              '• Game scores and match results\n'
              '• Team names you enter\n'
              '• Player names you enter\n\n'
              'This data never leaves your device and is not accessible to us or any third party.',
            ),
            _buildSection(
              Icons.phone_android_rounded,
              'Local Storage',
              'All data is stored on your device using local on-device storage (Hive). '
              'This data remains on your device until you delete it through the app settings '
              'or uninstall the app. We have no access to this data.',
            ),
            _buildSection(
              Icons.campaign_rounded,
              'Advertising',
              'TournaQ may display advertisements provided by Google AdMob. '
              'Google may collect certain device information and use cookies to serve '
              'relevant advertisements in accordance with Google\'s Privacy Policy and '
              'Terms of Service. We encourage you to review Google\'s privacy practices at '
              'policies.google.com.',
            ),
            _buildSection(
              Icons.link_rounded,
              'Third-Party Links',
              'The app may contain links to external platforms such as Instagram. '
              'These external services are governed by their own privacy policies and terms of use, '
              'which we encourage you to review. We are not responsible for the content or '
              'privacy practices of third-party sites.',
            ),
            _buildSection(
              Icons.child_care_rounded,
              'Children\'s Privacy',
              'TournaQ is not directed at children under the age of 13. '
              'We do not knowingly collect any personal information from children. '
              'If you believe a child has provided information through the app, '
              'please contact us so we can address it appropriately.',
            ),
            _buildSection(
              Icons.update_rounded,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time as the app evolves. '
              'We will indicate the effective date of any changes at the top of this page. '
              'Your continued use of TournaQ after any changes constitutes your acceptance '
              'of the updated Privacy Policy.',
            ),
            _buildSection(
              Icons.contact_support_rounded,
              'Contact',
              'If you have any questions or concerns about this Privacy Policy, '
              'please reach out to us on Instagram at @tournaq.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kOlive.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _kOlive,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _kOlive),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kOlive,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

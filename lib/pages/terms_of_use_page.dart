import 'package:flutter/material.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

const _kOlive = Color(0xFF556B2F);

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(title: 'Terms of Use'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateBadge('Effective: May 2026'),
            const SizedBox(height: 20),
            _buildSection(
              Icons.handshake_rounded,
              'Acceptance of Terms',
              'By downloading, installing, or using TournaQ, you agree to be bound by these '
              'Terms of Use. If you do not agree to these terms, please do not use the app.',
            ),
            _buildSection(
              Icons.app_shortcut_rounded,
              'License to Use',
              'TournaQ grants you a limited, non-exclusive, non-transferable, revocable license '
              'to use the app for personal, non-commercial purposes. This license does not include '
              'the right to sublicense, sell, resell, transfer, assign, or otherwise exploit '
              'the app or its content.',
            ),
            _buildSection(
              Icons.person_rounded,
              'Your Data and Content',
              'All game data, match scores, team names, and player information you enter into '
              'TournaQ is stored locally on your device. You retain full ownership of this data. '
              'We do not access, store, transmit, or use any of the content you create.\n\n'
              'You are solely responsible for the accuracy of the data you enter and for '
              'keeping your device secure.',
            ),
            _buildSection(
              Icons.block_rounded,
              'Prohibited Uses',
              'You agree not to:\n\n'
              '• Reverse engineer, decompile, or modify the app\n'
              '• Use the app for any unlawful or fraudulent purpose\n'
              '• Attempt to gain unauthorized access to any systems related to the app\n'
              '• Distribute, reproduce, or create derivative works without our permission\n'
              '• Use the app in any way that could damage, disable, or impair its functionality',
            ),
            _buildSection(
              Icons.campaign_rounded,
              'Advertising',
              'TournaQ may display advertisements through Google AdMob. '
              'These ads are subject to Google\'s own terms and policies. '
              'We are not responsible for the content of third-party advertisements.',
            ),
            _buildSection(
              Icons.warning_amber_rounded,
              'Disclaimer of Warranties',
              'TournaQ is provided "as is" and "as available" without warranties of any kind, '
              'either express or implied. We make no guarantees regarding the app\'s availability, '
              'accuracy, reliability, or fitness for a particular purpose.\n\n'
              'We reserve the right to modify, suspend, or discontinue the app at any time '
              'without notice.',
            ),
            _buildSection(
              Icons.shield_outlined,
              'Limitation of Liability',
              'To the fullest extent permitted by applicable law, TournaQ and its developers '
              'shall not be liable for any indirect, incidental, special, consequential, or '
              'punitive damages arising out of or in connection with your use of the app, '
              'even if we have been advised of the possibility of such damages.\n\n'
              'Our total liability to you for any claims arising under these terms shall not '
              'exceed the amount you paid for the app.',
            ),
            _buildSection(
              Icons.update_rounded,
              'Changes to Terms',
              'We may update these Terms of Use from time to time. We will indicate the '
              'effective date of any changes at the top of this page. Your continued use of '
              'TournaQ after any changes constitutes your acceptance of the updated terms.',
            ),
            _buildSection(
              Icons.contact_support_rounded,
              'Contact',
              'If you have any questions about these Terms of Use, please reach out to us '
              'on Instagram at @tournaq.',
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

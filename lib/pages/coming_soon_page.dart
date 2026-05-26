import 'package:flutter/material.dart';
import '../config/contact_links.dart';
import '../utils/url_utils.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = Color(0xFFA97800);
const _kGoldLight = Color(0xFFFFF8E1);
const _kOlive = Color(0xFF556B2F);
const _kOliveLight = Color(0xFFEEF2E6);

class ComingSoonPage extends StatelessWidget {
  final String title;
  final String shortDescription;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.shortDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TournaQAppBar(title: title),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: _kGoldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 44,
                color: _kGold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _kOliveLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _kOlive.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kOlive,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            const Divider(color: Color(0xFFEEEEEE)),
            const SizedBox(height: 28),
            const Text(
              'Your feedback can help shape this feature before it launches.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    openExternalUrl(context, ContactLinks.feedbackForm),
                icon: const Icon(Icons.feedback_rounded, size: 18),
                label: const Text('Give Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openEmail(
                  context,
                  ContactLinks.contactEmail,
                  subject: 'TournaQ Feature Feedback',
                ),
                icon: const Icon(Icons.email_rounded, size: 18),
                label: const Text('Email Us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kOlive,
                  side: BorderSide(color: _kOlive.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

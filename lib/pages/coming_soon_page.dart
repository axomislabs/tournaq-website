import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../utils/url_utils.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
                color: AppColors.goldCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.construction_rounded, size: 44, color: AppColors.goldDark),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.oliveLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.olive.withValues(alpha: 0.3)),
              ),
              child: Text(
                l10n.comingSoonLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
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
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 28),
            Text(
              l10n.comingSoonBody,
              style: const TextStyle(
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
                onPressed: () => openExternalUrl(context, AppLinks.feedbackForm),
                icon: const Icon(Icons.feedback_rounded, size: 18),
                label: Text(l10n.btnGiveFeedback),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openEmail(context, AppLinks.contactEmail, subject: 'TournaQ Feature Feedback'),
                icon: const Icon(Icons.email_rounded, size: 18),
                label: Text(l10n.btnEmailUs),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.olive,
                  side: BorderSide(color: AppColors.olive.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

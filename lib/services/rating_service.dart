import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'local_storage_service.dart';
import '../config/contact_links.dart';
import '../utils/url_utils.dart';

class RatingService {
  RatingService._();

  static const _countKey = 'rating_games_count';
  static const _shownKey = 'rating_prompt_shown';
  static const _triggerCount = 10;
  // Fill in after App Store submission:
  static const _appStoreId = '';

  static Future<void> onGameCreated(BuildContext context) async {
    final raw = LocalStorageService.getPref(_countKey);
    final count = (raw != null ? int.tryParse(raw) : null) ?? 0;
    final newCount = count + 1;
    await LocalStorageService.setPref(_countKey, '$newCount');

    final alreadyShown = LocalStorageService.getPref(_shownKey) == 'true';
    if (!alreadyShown && newCount >= _triggerCount) {
      await LocalStorageService.setPref(_shownKey, 'true');
      if (context.mounted) await showRatingDialog(context);
    }
  }

  static Future<void> requestReview(BuildContext context) async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
      if (_appStoreId.isNotEmpty) {
        await review.openStoreListing(appStoreId: _appStoreId);
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the store — please search for TournaQ manually.'),
        ),
      );
    }
  }

  static Future<void> showRatingDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFA97800), size: 22),
            SizedBox(width: 8),
            Text(
              'Enjoying TournaQ?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'A quick rating helps us reach more players and tournament organizers.',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openExternalUrl(ctx, ContactLinks.feedbackForm);
            },
            child: const Text('Give Feedback'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await requestReview(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF556B2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rate TournaQ'),
          ),
        ],
      ),
    );
  }
}

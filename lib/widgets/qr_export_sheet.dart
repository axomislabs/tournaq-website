import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Shows a bottom sheet with a QR code encoding [data] for another device to
/// scan. [title] names the action (e.g. "Export scorecard") and [subtitle]
/// gives context (e.g. "Court 1 · Ann & Bo vs Cy & Di").
Future<void> showQrExportSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _QrExportSheet(title: title, subtitle: subtitle, data: data),
  );
}

class _QrExportSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String data;

  const _QrExportSheet({
    required this.title,
    required this.subtitle,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Builder(builder: (context) {
              // Render as large as the sheet allows (capped) so QR modules stay
              // big enough to scan reliably — Android's decoder in particular
              // needs generous module size. Constrain by height too so the code
              // doesn't push the Done button off-screen in landscape (where the
              // sheet is short); the surrounding SingleChildScrollView absorbs
              // any remaining overflow.
              final media = MediaQuery.of(context).size;
              final qrSize = math
                  .min(math.min(media.width - 112, media.height * 0.5), 320.0)
                  .clamp(160.0, 320.0)
                  .toDouble();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: data,
                  size: qrSize,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  errorStateBuilder: (ctx, err) => SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: Center(
                      child: Text(
                        l10n.scrambleQrTooLarge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              l10n.scrambleQrScanHint,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.btnDone,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

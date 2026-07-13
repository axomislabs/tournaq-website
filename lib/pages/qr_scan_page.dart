import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../widgets/tournaq_app_bar.dart';

/// Full-screen QR scanner. Pops the first decoded raw string back to the
/// caller, which is responsible for decoding/interpreting it.
class QrScanPage extends StatefulWidget {
  final String hint;

  const QrScanPage({super.key, required this.hint});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TournaQAppBar(title: l10n.scrambleScanTitle),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, error) => _ErrorView(error: error),
          ),
          // Scan window cutout.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              widget.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final MobileScannerException error;
  const _ErrorView({required this.error});

  Future<void> _openSettings() async {
    try {
      await launchUrl(Uri.parse('app-settings:'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // No universal app-settings scheme on this platform; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_rounded,
              color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            denied
                ? l10n.scrambleScanCameraDenied
                : (error.errorDetails?.message ?? l10n.scrambleScanCameraDenied),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (denied) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _openSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: Text(l10n.scrambleOpenSettings),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;

/// Handles the Google UMP consent flow and MobileAds initialization.
///
/// Call [initialize] once after the first frame (e.g. from MyApp.initState via
/// addPostFrameCallback). Ads must not be loaded before [mobileAdsReady] is true.
class ConsentService {
  ConsentService._();

  static bool _initialized = false;
  static bool _mobileAdsReady = false;

  /// True once MobileAds.initialize() has completed successfully.
  static bool get mobileAdsReady => _mobileAdsReady;

  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      kIsWeb;

  /// True on platforms where the UMP consent UI can be presented.
  static bool get supported => _supported;

  /// Runs the UMP consent flow then initializes MobileAds.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Ads are never gated: if consent fails or is rejected, MobileAds is still
  /// initialized so non-personalized ads can serve.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_supported) return;

    await _runConsentFlow();
    await _startMobileAds();
  }

  static Future<void> _runConsentFlow() async {
    final completer = Completer<void>();

    gma.ConsentInformation.instance.requestConsentInfoUpdate(
      gma.ConsentRequestParameters(),
      () {
        // Success — show the form if the UMP SDK decides it is required.
        gma.ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (_) {
        // Network or config error — proceed; non-personalized ads will still serve.
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  static Future<void> _startMobileAds() async {
    if (_mobileAdsReady) return;
    await gma.MobileAds.instance.initialize();
    _mobileAdsReady = true;
  }

  /// Shows the UMP privacy options form so users can update their choices.
  ///
  /// Does a fresh [requestConsentInfoUpdate] first so the form is always
  /// loaded and the status reflects the current session.
  static Future<void> showPrivacyOptions({void Function()? onDismissed}) async {
    if (!_supported) return;

    // Refresh consent info and log any request error.
    final refreshed = Completer<void>();
    gma.ConsentInformation.instance.requestConsentInfoUpdate(
      gma.ConsentRequestParameters(),
      () => refreshed.complete(),
      (error) {
        debugPrint('ConsentService: requestConsentInfoUpdate error: ${error.message}');
        refreshed.complete();
      },
    );
    await refreshed.future;

    var status = await gma.ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();

    // Unknown means the initial consent flow was never completed (e.g. the
    // startup request failed). Try loading and showing the consent form now
    // so the status advances to required/notRequired.
    if (status == gma.PrivacyOptionsRequirementStatus.unknown) {
      debugPrint('ConsentService: status unknown — running consent flow');
      final flowDone = Completer<void>();
      gma.ConsentForm.loadAndShowConsentFormIfRequired((_) => flowDone.complete());
      await flowDone.future;
      status = await gma.ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
    }

    if (status != gma.PrivacyOptionsRequirementStatus.required) {
      debugPrint('ConsentService: privacy options not required (status: $status)');
      return;
    }

    gma.ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint('ConsentService: showPrivacyOptionsForm error: ${error.message}');
      }
      onDismissed?.call();
    });
  }

  /// Whether the privacy options entry point should be displayed.
  ///
  /// This is async because the UMP SDK reads it from its internal cache.
  /// For EU/EEA-targeted apps this will almost always resolve to true.
  static Future<bool> privacyOptionsRequired() async {
    if (!_supported || !_initialized) return false;
    try {
      final status = await gma.ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == gma.PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }
}

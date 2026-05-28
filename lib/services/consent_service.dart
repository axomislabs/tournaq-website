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
  /// Only call when [privacyOptionsRequired] resolves to true, or show the
  /// entry point unconditionally for EU-targeted apps (simpler).
  static void showPrivacyOptions({void Function()? onDismissed}) {
    if (!_supported) return;
    gma.ConsentForm.showPrivacyOptionsForm(
      (_) => onDismissed?.call(),
    );
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

import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  static const _iosBannerTest     = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerProd     = 'ca-app-pub-6880259912811554/9409823441';
  static const _androidBannerProd = 'ca-app-pub-6880259912811554/5743561084';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS ? _iosBannerTest : _androidBannerTest;
    }
    return Platform.isIOS ? _iosBannerProd : _androidBannerProd;
  }
}

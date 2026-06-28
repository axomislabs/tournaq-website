import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

// Runs before every test in this directory.
// loadAppFonts() loads the fonts declared in pubspec.yaml so that text
// and Material icons render correctly in golden screenshots.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}

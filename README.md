# TournaQ

A local-first Flutter app for running social court-sport sessions and competitions — quick scored matches, rotating socials, and knockout tournaments — with everything stored on-device and no account required.

TournaQ ("Tournament Queue") lets you set up players and teams, run a session in one of several formats, keep score live, and share results between devices via QR codes or spreadsheet export.

## Features

- **Multiple game formats** — from a one-tap quick match to full knockout brackets (see below).
- **Live scoring** — real-time scoreboards, standings, and rotation queues per format.
- **Local-first** — all game data is stored on-device with [Hive](https://pub.dev/packages/hive). No user accounts, no backend, nothing transmitted to us.
- **QR import/export** — hand off a scorecard, bracket, or session to another device by scanning a QR code (`mobile_scanner` to read, `qr_flutter` to generate).
- **Spreadsheet import/export** — import and export tournament/scorecard data as Excel files via the system file picker and share sheet.
- **Localized** — English, German, and Spanish.
- **Ad-supported** — non-personalized Google AdMob ads with a UMP consent flow.

## Game modes

| Category | Mode | Description |
|---|---|---|
| Quick Games | **Quick Game** | A scored match on the spot — pick two teams and go. |
| Single Competitions & Socials | **Scramble** | Social format where players rotate partners across rounds and rank individually. |
| | **Scramble King** | King-of-the-Court scramble variant — winners hold the court while challengers rotate in. |
| | **King of the Court** | Classic king-of-the-court rotation session. |
| | **Doghouse** | Social relegation/promotion format across courts. |
| Team Competitions | **KO Bracket** | Single-elimination knockout tournament for pre-formed teams. |

## Tech stack

- **Flutter** 3.44.6 (stable) · **Dart** SDK `^3.11.5`
- **State/storage:** [Hive](https://pub.dev/packages/hive) + `hive_flutter` (on-device persistence)
- **QR:** `mobile_scanner` (scan) · `qr_flutter` (generate)
- **Data transfer:** `excel`, `file_picker`, `share_plus`
- **Monetization:** `google_mobile_ads` (AdMob + UMP consent)
- **Misc:** `url_launcher`, `in_app_review`, `intl` / `flutter_localizations`

## Getting started

### Prerequisites

- Flutter **3.44.6** stable and Xcode / Android SDK per `flutter doctor`.
- This project builds with **CocoaPods** (Swift Package Manager is intentionally disabled — see [iOS notes](#ios) below).

### Run

```bash
flutter pub get
flutter run
```

## Building release artifacts

The app version and build number live in `pubspec.yaml` (`version: <name>+<buildNumber>`); bump the build number before each store upload.

### Android (Play Store)

Release signing is configured in `android/app/build.gradle.kts` and reads credentials from `android/key.properties` (not committed) pointing at the release keystore.

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to the Play Console.

### iOS

Swift Package Manager is disabled for this project (`flutter config --no-enable-swift-package-manager`) because a transitive dependency chain (`excel → archive 3.x` vs. `flutter_native_splash → archive 4.x`) pins an older `flutter_native_splash` whose SPM manifest is broken. Builds use CocoaPods.

App Store release requires an **Apple Distribution** certificate and App Store provisioning profile. With those in place:

```bash
flutter build ipa --release
# → build/ios/ipa/*.ipa
```

Then upload via Transporter or **Xcode → Organizer** (Organizer can also manage distribution signing under your Apple ID).

## Localization

Strings live in `lib/l10n/app_en.arb` (template), `app_de.arb`, and `app_es.arb`. Regenerate the Dart localizations after editing:

```bash
flutter gen-l10n
```

Keep German and Spanish translations within the English character budget to avoid UI overflow.

## Project structure

```
lib/
├── pages/       # Screens, grouped by mode (scramble_*, ko_bracket_*, doghouse_*, king_of_the_court_*, …)
├── models/      # Domain models (Player, Team, Game, *Tournament, imported_* payloads)
├── services/    # Storage (Hive), transfer (QR/Excel), consent, locale, rating
├── scoring/     # Scoring adapters + live scoring screen
├── widgets/     # Shared UI components
└── l10n/        # ARB source + generated localizations
docs/            # Static legal site (privacy policy, terms, legal notice)
```

## Privacy & legal

TournaQ is local-first: game data never leaves the device, and the camera (QR) and file (spreadsheet) permissions are used only on-device. See [`docs/privacy-policy.html`](docs/privacy-policy.html), [`docs/terms-of-use.html`](docs/terms-of-use.html), and [`docs/legal-notice.html`](docs/legal-notice.html).

---

© 2026 Martin Adam · TournaQ

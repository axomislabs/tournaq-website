// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TournaQ';

  @override
  String get appTagline => 'Scoring, Games and Tournament Management';

  @override
  String get navHome => 'Home';

  @override
  String get navQuickStart => 'Quick Start Game';

  @override
  String get navSponsoring => 'Sponsoring & Promo';

  @override
  String get navContact => 'Contact & About';

  @override
  String get btnStartGame => 'Start Game';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnCreate => 'Create';

  @override
  String get btnRemove => 'Remove';

  @override
  String get btnSave => 'Save';

  @override
  String get btnOk => 'OK';

  @override
  String get btnGiveFeedback => 'Give Feedback';

  @override
  String get btnEmailUs => 'Email Us';

  @override
  String get btnRateTournaQ => 'Rate TournaQ';

  @override
  String get btnNotNow => 'Not Now';

  @override
  String get btnSaveAndReturn => 'Save & Return to Games';

  @override
  String get quickStartTitle => 'Quick Start a Game';

  @override
  String get quickStartFormatQuestion => 'How long is the match?';

  @override
  String get quickStartTeamQuestion =>
      'How would you like to choose your teams?';

  @override
  String get formatOneSet => 'One Set';

  @override
  String get formatOneSetSubtitle => 'Single set to decide the winner';

  @override
  String get formatBestOfThree => 'Best of Three Sets';

  @override
  String get formatBestOfThreeSubtitle =>
      'First to win two sets wins the match';

  @override
  String get teamMethodExisting => 'Select Existing Teams';

  @override
  String get teamMethodNew => 'Create New Teams';

  @override
  String get teamMethodRandom => 'Generate Random Teams';

  @override
  String get sideChangeTitle => 'Side Change';

  @override
  String get sideChangeBody => 'Teams must switch sides now.';

  @override
  String get sideChangeContinue => 'Sides Switched — Continue';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get comingSoonBody =>
      'Your feedback can help shape this feature before it launches.';

  @override
  String get promoSupportTitle => 'Support TournaQ';

  @override
  String get promoSupportSubtitle =>
      'Advertising and sponsorship help support the continued development of TournaQ.';

  @override
  String get promoFollowTitle => 'Follow the Journey';

  @override
  String get promoFollowSubtitle =>
      'Share events and games where TournaQ supported you — tag us on Instagram.';

  @override
  String get promoRateTitle => 'Enjoying TournaQ?';

  @override
  String get promoRateSubtitle =>
      'Ratings help us reach more players and organizers.';

  @override
  String get promoHelpTitle => 'Help Shape TournaQ';

  @override
  String get promoHelpSubtitle =>
      'We welcome suggestions and ideas for future features and partnerships.';

  @override
  String get ratingDialogBody =>
      'A quick rating helps us reach more players and tournament organizers.';

  @override
  String get deleteHistoryTitle => 'Delete All Match History?';

  @override
  String get deleteHistoryBody =>
      'This will permanently delete all local game records. This cannot be undone.';

  @override
  String get noGamesYet => 'No scoring history yet';

  @override
  String get noGamesYetSubtitle => 'Start scoring to track gameplay.';

  @override
  String get noTeamsYet => 'No teams yet.';

  @override
  String get noTournamentsYet => 'No tournaments yet.';

  @override
  String get noClubsYet => 'No clubs yet.';

  @override
  String get errorLinkNotAvailable => 'Link not available yet';

  @override
  String get errorCouldNotOpenLink => 'Could not open link';

  @override
  String get errorCouldNotOpenEmail => 'Could not open email app';

  @override
  String get errorStoreNotAvailable =>
      'Could not open the store — please search for TournaQ manually.';
}

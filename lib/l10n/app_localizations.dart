import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'TournaQ'**
  String get appName;

  /// Subtitle shown on splash and drawer
  ///
  /// In en, this message translates to:
  /// **'Scoring, Games and Tournament Management'**
  String get appTagline;

  /// Navigation drawer item
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation drawer item
  ///
  /// In en, this message translates to:
  /// **'Quick Start Game'**
  String get navQuickStart;

  /// Navigation drawer item
  ///
  /// In en, this message translates to:
  /// **'Sponsoring & Promo'**
  String get navSponsoring;

  /// Navigation drawer item
  ///
  /// In en, this message translates to:
  /// **'Contact & About'**
  String get navContact;

  /// No description provided for @btnStartGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get btnStartGame;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get btnCreate;

  /// No description provided for @btnRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get btnRemove;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @btnGiveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get btnGiveFeedback;

  /// No description provided for @btnEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get btnEmailUs;

  /// No description provided for @btnRateTournaQ.
  ///
  /// In en, this message translates to:
  /// **'Rate TournaQ'**
  String get btnRateTournaQ;

  /// No description provided for @btnNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get btnNotNow;

  /// No description provided for @btnSaveAndReturn.
  ///
  /// In en, this message translates to:
  /// **'Save & Return to Games'**
  String get btnSaveAndReturn;

  /// No description provided for @quickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Start a Game'**
  String get quickStartTitle;

  /// No description provided for @quickStartFormatQuestion.
  ///
  /// In en, this message translates to:
  /// **'How long is the match?'**
  String get quickStartFormatQuestion;

  /// No description provided for @quickStartTeamQuestion.
  ///
  /// In en, this message translates to:
  /// **'How would you like to choose your teams?'**
  String get quickStartTeamQuestion;

  /// No description provided for @formatOneSet.
  ///
  /// In en, this message translates to:
  /// **'One Set'**
  String get formatOneSet;

  /// No description provided for @formatOneSetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Single set to decide the winner'**
  String get formatOneSetSubtitle;

  /// No description provided for @formatBestOfThree.
  ///
  /// In en, this message translates to:
  /// **'Best of Three Sets'**
  String get formatBestOfThree;

  /// No description provided for @formatBestOfThreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First to win two sets wins the match'**
  String get formatBestOfThreeSubtitle;

  /// No description provided for @teamMethodExisting.
  ///
  /// In en, this message translates to:
  /// **'Select Existing Teams'**
  String get teamMethodExisting;

  /// No description provided for @teamMethodNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Teams'**
  String get teamMethodNew;

  /// No description provided for @teamMethodRandom.
  ///
  /// In en, this message translates to:
  /// **'Generate Random Teams'**
  String get teamMethodRandom;

  /// No description provided for @sideChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Side Change'**
  String get sideChangeTitle;

  /// No description provided for @sideChangeBody.
  ///
  /// In en, this message translates to:
  /// **'Teams must switch sides now.'**
  String get sideChangeBody;

  /// No description provided for @sideChangeContinue.
  ///
  /// In en, this message translates to:
  /// **'Sides Switched — Continue'**
  String get sideChangeContinue;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback can help shape this feature before it launches.'**
  String get comingSoonBody;

  /// No description provided for @promoSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support TournaQ'**
  String get promoSupportTitle;

  /// No description provided for @promoSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advertising and sponsorship help support the continued development of TournaQ.'**
  String get promoSupportSubtitle;

  /// No description provided for @promoFollowTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow the Journey'**
  String get promoFollowTitle;

  /// No description provided for @promoFollowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share events and games where TournaQ supported you — tag us on Instagram.'**
  String get promoFollowSubtitle;

  /// No description provided for @promoRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying TournaQ?'**
  String get promoRateTitle;

  /// No description provided for @promoRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings help us reach more players and organizers.'**
  String get promoRateSubtitle;

  /// No description provided for @promoHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Shape TournaQ'**
  String get promoHelpTitle;

  /// No description provided for @promoHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We welcome suggestions and ideas for future features and partnerships.'**
  String get promoHelpSubtitle;

  /// No description provided for @ratingDialogBody.
  ///
  /// In en, this message translates to:
  /// **'A quick rating helps us reach more players and tournament organizers.'**
  String get ratingDialogBody;

  /// No description provided for @deleteHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Match History?'**
  String get deleteHistoryTitle;

  /// No description provided for @deleteHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all local game records. This cannot be undone.'**
  String get deleteHistoryBody;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No scoring history yet'**
  String get noGamesYet;

  /// No description provided for @noGamesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start scoring to track gameplay.'**
  String get noGamesYetSubtitle;

  /// No description provided for @noTeamsYet.
  ///
  /// In en, this message translates to:
  /// **'No teams yet.'**
  String get noTeamsYet;

  /// No description provided for @noTournamentsYet.
  ///
  /// In en, this message translates to:
  /// **'No tournaments yet.'**
  String get noTournamentsYet;

  /// No description provided for @noClubsYet.
  ///
  /// In en, this message translates to:
  /// **'No clubs yet.'**
  String get noClubsYet;

  /// No description provided for @errorLinkNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Link not available yet'**
  String get errorLinkNotAvailable;

  /// No description provided for @errorCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get errorCouldNotOpenLink;

  /// No description provided for @errorCouldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get errorCouldNotOpenEmail;

  /// No description provided for @errorStoreNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store — please search for TournaQ manually.'**
  String get errorStoreNotAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

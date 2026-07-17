import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es'),
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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get navQuickStart;

  /// No description provided for @navTournaments.
  ///
  /// In en, this message translates to:
  /// **'TournaQ Arena'**
  String get navTournaments;

  /// No description provided for @navTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navTeams;

  /// No description provided for @navClubs.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navClubs;

  /// No description provided for @navPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get navPlayers;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get navAdmin;

  /// No description provided for @navSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Sponsoring & Promo'**
  String get navSponsoring;

  /// No description provided for @navContact.
  ///
  /// In en, this message translates to:
  /// **'Contact & About'**
  String get navContact;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @pageGames.
  ///
  /// In en, this message translates to:
  /// **'Quick Games'**
  String get pageGames;

  /// No description provided for @pageTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get pageTeams;

  /// No description provided for @pagePlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get pagePlayers;

  /// No description provided for @pageTournaments.
  ///
  /// In en, this message translates to:
  /// **'TournaQ Arena'**
  String get pageTournaments;

  /// No description provided for @pageTournamentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet and compete for the court'**
  String get pageTournamentsSubtitle;

  /// No description provided for @pageClubs.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get pageClubs;

  /// No description provided for @pageGameScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get pageGameScorecard;

  /// No description provided for @pageGameplayHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get pageGameplayHistory;

  /// No description provided for @pageTeamDetails.
  ///
  /// In en, this message translates to:
  /// **'Team Details'**
  String get pageTeamDetails;

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

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get btnAssign;

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

  /// No description provided for @btnCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get btnCreateTeam;

  /// No description provided for @btnCreatePlayer.
  ///
  /// In en, this message translates to:
  /// **'Create Player'**
  String get btnCreatePlayer;

  /// No description provided for @btnCreateTournament.
  ///
  /// In en, this message translates to:
  /// **'Create Tournament'**
  String get btnCreateTournament;

  /// No description provided for @btnCreateClub.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get btnCreateClub;

  /// No description provided for @btnSavePlayers.
  ///
  /// In en, this message translates to:
  /// **'Save Players'**
  String get btnSavePlayers;

  /// No description provided for @btnDeleteHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete History'**
  String get btnDeleteHistory;

  /// No description provided for @btnGenerate10RandomTeams.
  ///
  /// In en, this message translates to:
  /// **'Generate 10 Random Teams'**
  String get btnGenerate10RandomTeams;

  /// No description provided for @btnGenerate10RandomPlayers.
  ///
  /// In en, this message translates to:
  /// **'Generate 10 Random Players'**
  String get btnGenerate10RandomPlayers;

  /// No description provided for @quickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Game'**
  String get quickStartTitle;

  /// No description provided for @quickStartFormatQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many sets?'**
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

  /// No description provided for @quickStartSelectTeam1.
  ///
  /// In en, this message translates to:
  /// **'Select Team 1'**
  String get quickStartSelectTeam1;

  /// No description provided for @quickStartSelectTeam2.
  ///
  /// In en, this message translates to:
  /// **'Select Team 2'**
  String get quickStartSelectTeam2;

  /// No description provided for @quickStartTeam1Name.
  ///
  /// In en, this message translates to:
  /// **'Team 1 Name'**
  String get quickStartTeam1Name;

  /// No description provided for @quickStartTeam2Name.
  ///
  /// In en, this message translates to:
  /// **'Team 2 Name'**
  String get quickStartTeam2Name;

  /// No description provided for @quickStartBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get quickStartBack;

  /// No description provided for @quickStartReRoll.
  ///
  /// In en, this message translates to:
  /// **'Re-roll'**
  String get quickStartReRoll;

  /// No description provided for @sectionMatchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get sectionMatchHistory;

  /// No description provided for @sectionGameplayControls.
  ///
  /// In en, this message translates to:
  /// **'Gameplay Controls'**
  String get sectionGameplayControls;

  /// No description provided for @sectionMatchActions.
  ///
  /// In en, this message translates to:
  /// **'Match Actions'**
  String get sectionMatchActions;

  /// No description provided for @sectionSponsoring.
  ///
  /// In en, this message translates to:
  /// **'Sponsoring'**
  String get sectionSponsoring;

  /// No description provided for @sectionOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get sectionOpportunities;

  /// No description provided for @sectionGetInvolved.
  ///
  /// In en, this message translates to:
  /// **'Get Involved'**
  String get sectionGetInvolved;

  /// No description provided for @sectionTeamsCount.
  ///
  /// In en, this message translates to:
  /// **'Teams ({count})'**
  String sectionTeamsCount(int count);

  /// No description provided for @sectionPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'Players ({count})'**
  String sectionPlayersCount(int count);

  /// No description provided for @sectionTournamentsCount.
  ///
  /// In en, this message translates to:
  /// **'Tournaments ({count})'**
  String sectionTournamentsCount(int count);

  /// No description provided for @sectionClubsCount.
  ///
  /// In en, this message translates to:
  /// **'Groups ({count})'**
  String sectionClubsCount(int count);

  /// No description provided for @hintSearchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams...'**
  String get hintSearchTeams;

  /// No description provided for @hintSearchPlayers.
  ///
  /// In en, this message translates to:
  /// **'Search players...'**
  String get hintSearchPlayers;

  /// No description provided for @hintSearchTournaments.
  ///
  /// In en, this message translates to:
  /// **'Search tournaments...'**
  String get hintSearchTournaments;

  /// No description provided for @hintSearchClubs.
  ///
  /// In en, this message translates to:
  /// **'Search groups...'**
  String get hintSearchClubs;

  /// No description provided for @filterPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get filterPlayer;

  /// No description provided for @filterTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get filterTeam;

  /// No description provided for @filterTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get filterTournament;

  /// No description provided for @filterClub.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get filterClub;

  /// No description provided for @filterMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get filterMode;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get filterSource;

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

  /// No description provided for @sideChangeBodyWithScore.
  ///
  /// In en, this message translates to:
  /// **'Total score is {score}.\n\nTeams must switch sides now.'**
  String sideChangeBodyWithScore(int score);

  /// No description provided for @sideChangeContinue.
  ///
  /// In en, this message translates to:
  /// **'Sides Switched — Continue'**
  String get sideChangeContinue;

  /// No description provided for @targetReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Reached'**
  String get targetReachedTitle;

  /// No description provided for @targetReachedBody.
  ///
  /// In en, this message translates to:
  /// **'{team} reached the target.\n\nSet {set} is won.'**
  String targetReachedBody(String team, int set);

  /// No description provided for @targetReachedKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep Playing'**
  String get targetReachedKeepPlaying;

  /// No description provided for @sideSwapLabel.
  ///
  /// In en, this message translates to:
  /// **'Side swap'**
  String get sideSwapLabel;

  /// No description provided for @sideSwapNone.
  ///
  /// In en, this message translates to:
  /// **'No side swap'**
  String get sideSwapNone;

  /// No description provided for @optionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get optionCustom;

  /// No description provided for @scoreGameOptions.
  ///
  /// In en, this message translates to:
  /// **'Game Options'**
  String get scoreGameOptions;

  /// No description provided for @scoreSwapTeams.
  ///
  /// In en, this message translates to:
  /// **'Swap Teams'**
  String get scoreSwapTeams;

  /// No description provided for @scoreSwapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch left and right sides'**
  String get scoreSwapSubtitle;

  /// No description provided for @scoreChangeService.
  ///
  /// In en, this message translates to:
  /// **'Change Service'**
  String get scoreChangeService;

  /// No description provided for @scoreChangeServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advance to next server'**
  String get scoreChangeServiceSubtitle;

  /// No description provided for @scoreGameplayHistory.
  ///
  /// In en, this message translates to:
  /// **'Gameplay History'**
  String get scoreGameplayHistory;

  /// No description provided for @scoreGameplayHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point-by-point scoring timeline'**
  String get scoreGameplayHistorySubtitle;

  /// No description provided for @scoreHistoryCompact.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get scoreHistoryCompact;

  /// No description provided for @scoreTargetScore.
  ///
  /// In en, this message translates to:
  /// **'Target score:'**
  String get scoreTargetScore;

  /// No description provided for @scoreLockBannerGameComplete.
  ///
  /// In en, this message translates to:
  /// **'Game completed — undo completion to edit scores'**
  String get scoreLockBannerGameComplete;

  /// No description provided for @scoreLockBannerSetComplete.
  ///
  /// In en, this message translates to:
  /// **'Set completed — undo completion to edit scores'**
  String get scoreLockBannerSetComplete;

  /// No description provided for @scoreTooltipDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get scoreTooltipDecrease;

  /// No description provided for @scoreTooltipIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get scoreTooltipIncrease;

  /// No description provided for @gameStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get gameStatusCompleted;

  /// No description provided for @gameStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get gameStatusInProgress;

  /// No description provided for @gameStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get gameStatusPending;

  /// No description provided for @gameMenuScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get gameMenuScorecard;

  /// No description provided for @gameMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Game'**
  String get gameMenuDelete;

  /// No description provided for @gameTileQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get gameTileQuick;

  /// No description provided for @setHeader.
  ///
  /// In en, this message translates to:
  /// **'Set {n}  ·  to {target}'**
  String setHeader(int n, int target);

  /// No description provided for @setFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Final: {s1} – {s2}'**
  String setFinalScore(int s1, int s2);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoonLabel;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback can help shape this feature before it launches.'**
  String get comingSoonBody;

  /// No description provided for @comingSoonLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more on website'**
  String get comingSoonLearnMore;

  /// No description provided for @landingTournamentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage games and tournaments'**
  String get landingTournamentsSubtitle;

  /// No description provided for @landingAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage players, teams & groups'**
  String get landingAdminSubtitle;

  /// No description provided for @landingMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsoring, contact & settings'**
  String get landingMoreSubtitle;

  /// No description provided for @moreSponsoringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsors, ads & promotions'**
  String get moreSponsoringSubtitle;

  /// No description provided for @moreContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch & app info'**
  String get moreContactSubtitle;

  /// No description provided for @moreSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language & preferences'**
  String get moreSettingsSubtitle;

  /// No description provided for @navBecomeTester.
  ///
  /// In en, this message translates to:
  /// **'Become a Tester'**
  String get navBecomeTester;

  /// No description provided for @moreBecomeTesterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try new features early'**
  String get moreBecomeTesterSubtitle;

  /// No description provided for @testerIntro.
  ///
  /// In en, this message translates to:
  /// **'Help shape TournaQ by testing new features before they\'re released — on iOS via TestFlight, or on Android once you\'re added to the program.'**
  String get testerIntro;

  /// No description provided for @testerSectionIOS.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get testerSectionIOS;

  /// No description provided for @testerIOSDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download via TestFlight'**
  String get testerIOSDownloadTitle;

  /// No description provided for @testerIOSDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to install the beta directly'**
  String get testerIOSDownloadSubtitle;

  /// No description provided for @testerSectionSignup.
  ///
  /// In en, this message translates to:
  /// **'iOS & Android'**
  String get testerSectionSignup;

  /// No description provided for @testerSignupQRTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to Sign Up'**
  String get testerSignupQRTitle;

  /// No description provided for @testerSignupQRSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For iOS & Android testers'**
  String get testerSignupQRSubtitle;

  /// No description provided for @testerSignupLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Sign-up Form'**
  String get testerSignupLinkTitle;

  /// No description provided for @testerSignupLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you\'re already on this device'**
  String get testerSignupLinkSubtitle;

  /// No description provided for @testerNoteIOS.
  ///
  /// In en, this message translates to:
  /// **'iOS: signing up is optional — you can install directly via TestFlight — but it helps us stay in touch.'**
  String get testerNoteIOS;

  /// No description provided for @testerNoteAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android: signing up is required. We add testers to the program by hand afterwards, so there may be a short wait.'**
  String get testerNoteAndroid;

  /// No description provided for @testerContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Got a Bigger Idea?'**
  String get testerContactTitle;

  /// No description provided for @testerContactBody.
  ///
  /// In en, this message translates to:
  /// **'Organizing a big tournament, missing a mode or feature, or need support? Let us know — we prioritize tester requests.'**
  String get testerContactBody;

  /// No description provided for @testerContactButton.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get testerContactButton;

  /// No description provided for @btnGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get btnGotIt;

  /// No description provided for @btnLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get btnLearnMore;

  /// No description provided for @tournamentsSectionQuickGames.
  ///
  /// In en, this message translates to:
  /// **'Quick Games'**
  String get tournamentsSectionQuickGames;

  /// No description provided for @tournamentsSectionSingle.
  ///
  /// In en, this message translates to:
  /// **'Single Competitions & Socials'**
  String get tournamentsSectionSingle;

  /// No description provided for @tournamentsSectionTeam.
  ///
  /// In en, this message translates to:
  /// **'Team Competitions'**
  String get tournamentsSectionTeam;

  /// No description provided for @tournamentsSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Tournament History'**
  String get tournamentsSectionHistory;

  /// No description provided for @modeQuickGamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Ad-hoc matches'**
  String get modeQuickGamesDesc;

  /// No description provided for @modeSocialScramblesDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet and compete'**
  String get modeSocialScramblesDesc;

  /// No description provided for @modeKotcDesc.
  ///
  /// In en, this message translates to:
  /// **'Establish you reign'**
  String get modeKotcDesc;

  /// No description provided for @modeDoghouseDesc.
  ///
  /// In en, this message translates to:
  /// **'Get out of the Doghouse'**
  String get modeDoghouseDesc;

  /// No description provided for @modeLeagueDesc.
  ///
  /// In en, this message translates to:
  /// **'Points-based standings'**
  String get modeLeagueDesc;

  /// No description provided for @modeSingleElimDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic knockout bracket'**
  String get modeSingleElimDesc;

  /// No description provided for @modeDoubleElimDesc.
  ///
  /// In en, this message translates to:
  /// **'Two-chance bracket'**
  String get modeDoubleElimDesc;

  /// No description provided for @modeGroupSeDesc.
  ///
  /// In en, this message translates to:
  /// **'Group stage · Single Elimination'**
  String get modeGroupSeDesc;

  /// No description provided for @modeGroupDeDesc.
  ///
  /// In en, this message translates to:
  /// **'Group stage · Double Elimination'**
  String get modeGroupDeDesc;

  /// No description provided for @modeSwissDesc.
  ///
  /// In en, this message translates to:
  /// **'Paired rounds by score'**
  String get modeSwissDesc;

  /// No description provided for @modeLeagueShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Track standings across a full round-robin season with points, wins, and goal difference.'**
  String get modeLeagueShortDesc;

  /// No description provided for @modeDoubleElimShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Winners and losers brackets — you need two losses to be eliminated.'**
  String get modeDoubleElimShortDesc;

  /// No description provided for @modeGroupSeShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Teams advance from a group stage into a single-elimination knockout bracket.'**
  String get modeGroupSeShortDesc;

  /// No description provided for @modeGroupDeShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Teams advance from a group stage into a double-elimination bracket.'**
  String get modeGroupDeShortDesc;

  /// No description provided for @modeSwissShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Players are paired each round based on their current score — no eliminations, full schedule.'**
  String get modeSwissShortDesc;

  /// No description provided for @tournamentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all history?'**
  String get tournamentsDeleteTitle;

  /// No description provided for @tournamentsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} tournaments. This cannot be undone.'**
  String tournamentsDeleteBody(int count);

  /// No description provided for @tournamentsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get tournamentsDeleteAll;

  /// No description provided for @tournamentsAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All Tournaments'**
  String get tournamentsAllLabel;

  /// No description provided for @tournamentsInfoContent.
  ///
  /// In en, this message translates to:
  /// **'Start a match or run a full tournament — all from one place.\n\nQuick Games — Scored matches on the spot. Minimal setup, just pick two teams and go.\n\nSingle Competitions & Socials — Individual formats where players compete and rank as themselves, rotating across the session.\n\nTeam Competitions — Team-based formats where pre-formed teams face off in a bracket or standings table.\n\nTap Info on any tile to learn more before you begin.'**
  String get tournamentsInfoContent;

  /// No description provided for @landingQuickStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Beach Volleyball Match'**
  String get landingQuickStartSubtitle;

  /// No description provided for @landingMatchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get landingMatchHistoryTitle;

  /// No description provided for @landingMatchHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and review past games'**
  String get landingMatchHistorySubtitle;

  /// No description provided for @landingMoreTournamentTitle.
  ///
  /// In en, this message translates to:
  /// **'More Tournament Features'**
  String get landingMoreTournamentTitle;

  /// No description provided for @landingMoreTournamentSub.
  ///
  /// In en, this message translates to:
  /// **'Additional formats, brackets, and competitive structures.'**
  String get landingMoreTournamentSub;

  /// No description provided for @landingDeviceScalabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Device & Screen Scalability'**
  String get landingDeviceScalabilityTitle;

  /// No description provided for @landingDeviceScalabilitySub.
  ///
  /// In en, this message translates to:
  /// **'Optimised layouts for tablets, web, and all screen sizes.'**
  String get landingDeviceScalabilitySub;

  /// No description provided for @landingScorecardSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Scorecard Sharing & Tournament Scaling'**
  String get landingScorecardSharingTitle;

  /// No description provided for @landingScorecardSharingSub.
  ///
  /// In en, this message translates to:
  /// **'Share results and support larger events and groups.'**
  String get landingScorecardSharingSub;

  /// No description provided for @landingLiveTournamentTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Tournament Features'**
  String get landingLiveTournamentTitle;

  /// No description provided for @landingLiveTournamentSub.
  ///
  /// In en, this message translates to:
  /// **'Real-time scoring, standings, and live event updates.'**
  String get landingLiveTournamentSub;

  /// No description provided for @landingAdvancedAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced User Administration'**
  String get landingAdvancedAdminTitle;

  /// No description provided for @landingAdvancedAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Manage players, teams, groups, and organiser roles.'**
  String get landingAdvancedAdminSub;

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
  /// **'Your rating helps us grow and improve TournaQ.'**
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

  /// No description provided for @promoAdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get promoAdPlaceholder;

  /// No description provided for @promoAdNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Ads available on iOS & Android'**
  String get promoAdNotSupported;

  /// No description provided for @promoAdThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting TournaQ.'**
  String get promoAdThankYou;

  /// No description provided for @promoPartnerSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Partner Spotlight'**
  String get promoPartnerSpotlight;

  /// No description provided for @promoPartnerSpotlightSub.
  ///
  /// In en, this message translates to:
  /// **'Future partners, groups and organizations may be featured here.'**
  String get promoPartnerSpotlightSub;

  /// No description provided for @promoTournamentPartnerships.
  ///
  /// In en, this message translates to:
  /// **'Tournament Partnerships'**
  String get promoTournamentPartnerships;

  /// No description provided for @promoTournamentPartnershipsSub.
  ///
  /// In en, this message translates to:
  /// **'Support for tournament organizers and event partnerships.'**
  String get promoTournamentPartnershipsSub;

  /// No description provided for @promoPromoteEvent.
  ///
  /// In en, this message translates to:
  /// **'Promote Your Event'**
  String get promoPromoteEvent;

  /// No description provided for @promoPromoteEventSub.
  ///
  /// In en, this message translates to:
  /// **'Future opportunities to showcase tournaments, leagues and events.'**
  String get promoPromoteEventSub;

  /// No description provided for @contactInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get contactInstagram;

  /// No description provided for @contactInstagramHandle.
  ///
  /// In en, this message translates to:
  /// **'@tournaq'**
  String get contactInstagramHandle;

  /// No description provided for @contactSectionSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get contactSectionSocial;

  /// No description provided for @contactSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get contactSectionSupport;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// No description provided for @contactFeedbackForm.
  ///
  /// In en, this message translates to:
  /// **'Feedback Form'**
  String get contactFeedbackForm;

  /// No description provided for @contactFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback, bugs and feature requests'**
  String get contactFeedbackSubtitle;

  /// No description provided for @contactWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get contactWebsite;

  /// No description provided for @contactWebsiteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visit our website'**
  String get contactWebsiteSubtitle;

  /// No description provided for @contactSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get contactSectionLegal;

  /// No description provided for @contactPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get contactPrivacyPolicy;

  /// No description provided for @contactPrivacyPolicySub.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get contactPrivacyPolicySub;

  /// No description provided for @contactTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get contactTermsOfUse;

  /// No description provided for @contactTermsOfUseSub.
  ///
  /// In en, this message translates to:
  /// **'Rules for using TournaQ'**
  String get contactTermsOfUseSub;

  /// No description provided for @contactLegalNotice.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get contactLegalNotice;

  /// No description provided for @contactLegalNoticeSub.
  ///
  /// In en, this message translates to:
  /// **'Developer & app information (EU)'**
  String get contactLegalNoticeSub;

  /// No description provided for @contactPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Privacy Options'**
  String get contactPrivacyOptions;

  /// No description provided for @contactPrivacyOptionsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your ad consent choices'**
  String get contactPrivacyOptionsSub;

  /// No description provided for @contactSectionResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get contactSectionResources;

  /// No description provided for @contactUserGuide.
  ///
  /// In en, this message translates to:
  /// **'Feature Overview'**
  String get contactUserGuide;

  /// No description provided for @contactUserGuideSub.
  ///
  /// In en, this message translates to:
  /// **'Explore all modes and features on the website'**
  String get contactUserGuideSub;

  /// No description provided for @contactLegalHub.
  ///
  /// In en, this message translates to:
  /// **'Legal Documentation'**
  String get contactLegalHub;

  /// No description provided for @contactLegalHubSub.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy, terms & legal notice'**
  String get contactLegalHubSub;

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

  /// No description provided for @dialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String dialogDeleteTitle(String name);

  /// No description provided for @dialogDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get dialogDeleteBody;

  /// No description provided for @dialogRemovePlayer.
  ///
  /// In en, this message translates to:
  /// **'Remove Player'**
  String get dialogRemovePlayer;

  /// No description provided for @dialogRemovePlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this player from the team?'**
  String get dialogRemovePlayerBody;

  /// No description provided for @dialogRemoveFromTournament.
  ///
  /// In en, this message translates to:
  /// **'Remove from Tournament'**
  String get dialogRemoveFromTournament;

  /// No description provided for @dialogRemoveFromTournamentBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this team from the tournament?'**
  String get dialogRemoveFromTournamentBody;

  /// No description provided for @dialogRemoveFromClub.
  ///
  /// In en, this message translates to:
  /// **'Remove from Group'**
  String get dialogRemoveFromClub;

  /// No description provided for @dialogRemoveFromClubBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this team from the group?'**
  String get dialogRemoveFromClubBody;

  /// No description provided for @menuEditPlayers.
  ///
  /// In en, this message translates to:
  /// **'Edit Players'**
  String get menuEditPlayers;

  /// No description provided for @menuAssignToTournament.
  ///
  /// In en, this message translates to:
  /// **'Assign to Tournament'**
  String get menuAssignToTournament;

  /// No description provided for @menuAssignToClub.
  ///
  /// In en, this message translates to:
  /// **'Assign to Group'**
  String get menuAssignToClub;

  /// No description provided for @menuAssignToTeam.
  ///
  /// In en, this message translates to:
  /// **'Assign to Team'**
  String get menuAssignToTeam;

  /// No description provided for @menuAssignPlayer.
  ///
  /// In en, this message translates to:
  /// **'Assign Player'**
  String get menuAssignPlayer;

  /// No description provided for @menuAssignTeam.
  ///
  /// In en, this message translates to:
  /// **'Assign Team'**
  String get menuAssignTeam;

  /// No description provided for @menuAssignTournament.
  ///
  /// In en, this message translates to:
  /// **'Assign Tournament'**
  String get menuAssignTournament;

  /// No description provided for @menuGenerateGames.
  ///
  /// In en, this message translates to:
  /// **'Generate Games'**
  String get menuGenerateGames;

  /// No description provided for @menuAddToTournament.
  ///
  /// In en, this message translates to:
  /// **'Add to Tournament'**
  String get menuAddToTournament;

  /// No description provided for @menuAddToClub.
  ///
  /// In en, this message translates to:
  /// **'Add to Group'**
  String get menuAddToClub;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get noGamesYet;

  /// No description provided for @noGamesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start scoring to track gameplay.'**
  String get noGamesYetSubtitle;

  /// No description provided for @noGamesYetHint.
  ///
  /// In en, this message translates to:
  /// **'Use Quick Start above or create a tournament.'**
  String get noGamesYetHint;

  /// No description provided for @noGamesFiltered.
  ///
  /// In en, this message translates to:
  /// **'No games match the current filters'**
  String get noGamesFiltered;

  /// No description provided for @noGamesFilteredHint.
  ///
  /// In en, this message translates to:
  /// **'Try clearing some filters.'**
  String get noGamesFilteredHint;

  /// No description provided for @noTeamsYet.
  ///
  /// In en, this message translates to:
  /// **'No teams yet.'**
  String get noTeamsYet;

  /// No description provided for @noTeamsFiltered.
  ///
  /// In en, this message translates to:
  /// **'No teams match the current filters.'**
  String get noTeamsFiltered;

  /// No description provided for @noPlayersYet.
  ///
  /// In en, this message translates to:
  /// **'No players yet.'**
  String get noPlayersYet;

  /// No description provided for @noPlayersFiltered.
  ///
  /// In en, this message translates to:
  /// **'No players match the current filters.'**
  String get noPlayersFiltered;

  /// No description provided for @noTournamentsYet.
  ///
  /// In en, this message translates to:
  /// **'No tournaments yet.'**
  String get noTournamentsYet;

  /// No description provided for @noTournamentsFiltered.
  ///
  /// In en, this message translates to:
  /// **'No tournaments match the current filters.'**
  String get noTournamentsFiltered;

  /// No description provided for @noClubsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet.'**
  String get noClubsYet;

  /// No description provided for @noClubsFiltered.
  ///
  /// In en, this message translates to:
  /// **'No groups match the current filters.'**
  String get noClubsFiltered;

  /// No description provided for @noScoringHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No scoring history yet'**
  String get noScoringHistoryYet;

  /// No description provided for @noPlayersInTeam.
  ///
  /// In en, this message translates to:
  /// **'No players yet.'**
  String get noPlayersInTeam;

  /// No description provided for @noTournamentsInTeam.
  ///
  /// In en, this message translates to:
  /// **'Not in any tournaments yet.'**
  String get noTournamentsInTeam;

  /// No description provided for @noClubsInTeam.
  ///
  /// In en, this message translates to:
  /// **'Not in any groups yet.'**
  String get noClubsInTeam;

  /// No description provided for @teamNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team not found.'**
  String get teamNotFound;

  /// No description provided for @snackbarGeneratedTeams.
  ///
  /// In en, this message translates to:
  /// **'Generated {count} random teams.'**
  String snackbarGeneratedTeams(int count);

  /// No description provided for @snackbarGeneratedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Generated {count} random players.'**
  String snackbarGeneratedPlayers(int count);

  /// No description provided for @snackbarGamesAlreadyGenerated.
  ///
  /// In en, this message translates to:
  /// **'Games already generated for this tournament.'**
  String get snackbarGamesAlreadyGenerated;

  /// No description provided for @snackbarAddTeamsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 teams before generating games.'**
  String get snackbarAddTeamsFirst;

  /// No description provided for @teamScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope: {name}'**
  String teamScopeLabel(String name);

  /// No description provided for @editPlayerNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit player names'**
  String get editPlayerNamesSubtitle;

  /// No description provided for @playerOne.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get playerOne;

  /// No description provided for @playerTwo.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get playerTwo;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @langAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get langAutomatic;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get langGerman;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get langSpanish;

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

  /// No description provided for @gameOptions.
  ///
  /// In en, this message translates to:
  /// **'Game Options'**
  String get gameOptions;

  /// No description provided for @swapTeams.
  ///
  /// In en, this message translates to:
  /// **'Swap Teams'**
  String get swapTeams;

  /// No description provided for @swapTeamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch left and right sides'**
  String get swapTeamsSubtitle;

  /// No description provided for @changeService.
  ///
  /// In en, this message translates to:
  /// **'Change Service'**
  String get changeService;

  /// No description provided for @changeServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advance to next server'**
  String get changeServiceSubtitle;

  /// No description provided for @gameplayHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point-by-point scoring timeline'**
  String get gameplayHistorySubtitle;

  /// No description provided for @historyShort.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyShort;

  /// No description provided for @completeSet.
  ///
  /// In en, this message translates to:
  /// **'Complete Set'**
  String get completeSet;

  /// No description provided for @undoSetCompletion.
  ///
  /// In en, this message translates to:
  /// **'Undo Set Completion'**
  String get undoSetCompletion;

  /// No description provided for @completeGame.
  ///
  /// In en, this message translates to:
  /// **'Complete Game'**
  String get completeGame;

  /// No description provided for @undoGameCompletion.
  ///
  /// In en, this message translates to:
  /// **'Undo Game Completion'**
  String get undoGameCompletion;

  /// No description provided for @targetScore.
  ///
  /// In en, this message translates to:
  /// **'Target score:'**
  String get targetScore;

  /// No description provided for @swapPlayers.
  ///
  /// In en, this message translates to:
  /// **'Swap Players'**
  String get swapPlayers;

  /// No description provided for @lockBannerGame.
  ///
  /// In en, this message translates to:
  /// **'Game completed — undo completion to edit scores'**
  String get lockBannerGame;

  /// No description provided for @lockBannerSet.
  ///
  /// In en, this message translates to:
  /// **'Set completed — undo completion to edit scores'**
  String get lockBannerSet;

  /// No description provided for @gameTileWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String gameTileWinner(String name);

  /// No description provided for @noWinnerDetermined.
  ///
  /// In en, this message translates to:
  /// **'No winner determined'**
  String get noWinnerDetermined;

  /// No description provided for @gameTileMatch.
  ///
  /// In en, this message translates to:
  /// **'Match: {status}'**
  String gameTileMatch(String status);

  /// No description provided for @menuGameScorecard.
  ///
  /// In en, this message translates to:
  /// **'Game Scorecard'**
  String get menuGameScorecard;

  /// No description provided for @btnDeleteGame.
  ///
  /// In en, this message translates to:
  /// **'Delete Game'**
  String get btnDeleteGame;

  /// No description provided for @pagePlayerDetails.
  ///
  /// In en, this message translates to:
  /// **'Player Details'**
  String get pagePlayerDetails;

  /// No description provided for @pageClubDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get pageClubDetails;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player not found.'**
  String get playerNotFound;

  /// No description provided for @clubNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found.'**
  String get clubNotFound;

  /// No description provided for @dialogRemoveFromTeam.
  ///
  /// In en, this message translates to:
  /// **'Remove from Team'**
  String get dialogRemoveFromTeam;

  /// No description provided for @dialogRemoveFromTeamBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this player from the team?'**
  String get dialogRemoveFromTeamBody;

  /// No description provided for @dialogRemovePlayerFromClubBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this player from the group?'**
  String get dialogRemovePlayerFromClubBody;

  /// No description provided for @dialogRemoveTournamentFromClub.
  ///
  /// In en, this message translates to:
  /// **'Remove Tournament'**
  String get dialogRemoveTournamentFromClub;

  /// No description provided for @dialogRemoveTournamentFromClubBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this tournament from the group?'**
  String get dialogRemoveTournamentFromClubBody;

  /// No description provided for @notAssignedToTeams.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any teams.'**
  String get notAssignedToTeams;

  /// No description provided for @notAssignedToClubs.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any groups.'**
  String get notAssignedToClubs;

  /// No description provided for @userEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String userEmailLabel(String email);

  /// No description provided for @userRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String userRoleLabel(String role);

  /// No description provided for @menuAddPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get menuAddPlayer;

  /// No description provided for @menuAddTeam.
  ///
  /// In en, this message translates to:
  /// **'Add Team'**
  String get menuAddTeam;

  /// No description provided for @menuAddTournament.
  ///
  /// In en, this message translates to:
  /// **'Add Tournament'**
  String get menuAddTournament;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// No description provided for @btnSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get btnSuggest;

  /// No description provided for @labelEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get labelEmailOptional;

  /// No description provided for @labelRoleOptional.
  ///
  /// In en, this message translates to:
  /// **'Role (optional)'**
  String get labelRoleOptional;

  /// No description provided for @labelScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get labelScope;

  /// No description provided for @hintClubName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get hintClubName;

  /// No description provided for @labelAssignToTeams.
  ///
  /// In en, this message translates to:
  /// **'Assign to Teams'**
  String get labelAssignToTeams;

  /// No description provided for @labelAssignToClubs.
  ///
  /// In en, this message translates to:
  /// **'Assign to Groups'**
  String get labelAssignToClubs;

  /// No description provided for @labelAssignToTournaments.
  ///
  /// In en, this message translates to:
  /// **'Assign to Tournaments'**
  String get labelAssignToTournaments;

  /// No description provided for @labelAssignPlayers.
  ///
  /// In en, this message translates to:
  /// **'Assign Players'**
  String get labelAssignPlayers;

  /// No description provided for @labelAssignTeams.
  ///
  /// In en, this message translates to:
  /// **'Assign Teams'**
  String get labelAssignTeams;

  /// No description provided for @labelAssignTournaments.
  ///
  /// In en, this message translates to:
  /// **'Assign Tournaments'**
  String get labelAssignTournaments;

  /// No description provided for @scopeTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get scopeTemporary;

  /// No description provided for @scopeTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get scopeTournament;

  /// No description provided for @scopeClub.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get scopeClub;

  /// No description provided for @labelMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get labelMode;

  /// No description provided for @hybridConfigureGroups.
  ///
  /// In en, this message translates to:
  /// **'Configure Hybrid Groups'**
  String get hybridConfigureGroups;

  /// No description provided for @hybridGroupsConfigured.
  ///
  /// In en, this message translates to:
  /// **'{count} groups configured — tap to edit'**
  String hybridGroupsConfigured(int count);

  /// No description provided for @labelAssignExistingTeams.
  ///
  /// In en, this message translates to:
  /// **'Assign Existing Teams'**
  String get labelAssignExistingTeams;

  /// No description provided for @filterAllClubs.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get filterAllClubs;

  /// No description provided for @noTeamsInClub.
  ///
  /// In en, this message translates to:
  /// **'No teams in this group.'**
  String get noTeamsInClub;

  /// No description provided for @noTeamsAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No teams available yet.'**
  String get noTeamsAvailableYet;

  /// No description provided for @labelAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get labelAvailable;

  /// No description provided for @hintDragTeamsHere.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag teams here'**
  String get hintDragTeamsHere;

  /// No description provided for @labelSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count})'**
  String labelSelectedCount(int count);

  /// No description provided for @labelGenerateRandomTeams.
  ///
  /// In en, this message translates to:
  /// **'Generate Random Teams'**
  String get labelGenerateRandomTeams;

  /// No description provided for @labelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelNone;

  /// No description provided for @labelClubForRandomTeams.
  ///
  /// In en, this message translates to:
  /// **'Group for random teams'**
  String get labelClubForRandomTeams;

  /// No description provided for @radioNoClub.
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get radioNoClub;

  /// No description provided for @radioAddToExistingClub.
  ///
  /// In en, this message translates to:
  /// **'Add to existing group'**
  String get radioAddToExistingClub;

  /// No description provided for @hintSelectClub.
  ///
  /// In en, this message translates to:
  /// **'Select a group'**
  String get hintSelectClub;

  /// No description provided for @radioCreateNewClub.
  ///
  /// In en, this message translates to:
  /// **'Create new group'**
  String get radioCreateNewClub;

  /// No description provided for @hintClubNameRandom.
  ///
  /// In en, this message translates to:
  /// **'Group name (leave blank for random)'**
  String get hintClubNameRandom;

  /// No description provided for @tooltipSuggestName.
  ///
  /// In en, this message translates to:
  /// **'Suggest a name'**
  String get tooltipSuggestName;

  /// No description provided for @noTeamsFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'No teams found.'**
  String get noTeamsFoundSearch;

  /// No description provided for @quickStartShort.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStartShort;

  /// No description provided for @formatBestOfThreeShort.
  ///
  /// In en, this message translates to:
  /// **'Best of Three'**
  String get formatBestOfThreeShort;

  /// No description provided for @teamMethodExistingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from your saved teams'**
  String get teamMethodExistingSubtitle;

  /// No description provided for @teamMethodNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name your teams on the fly'**
  String get teamMethodNewSubtitle;

  /// No description provided for @teamMethodRandomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let us pick fun team names'**
  String get teamMethodRandomSubtitle;

  /// No description provided for @quickStartChooseTeams.
  ///
  /// In en, this message translates to:
  /// **'Choose your teams'**
  String get quickStartChooseTeams;

  /// No description provided for @quickStartSelectTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Teams'**
  String get quickStartSelectTeamsTitle;

  /// No description provided for @quickStartNotEnoughTeams.
  ///
  /// In en, this message translates to:
  /// **'Not enough teams'**
  String get quickStartNotEnoughTeams;

  /// No description provided for @quickStartNotEnoughTeamsBody.
  ///
  /// In en, this message translates to:
  /// **'You need at least 2 saved teams.\nTry creating or generating teams instead.'**
  String get quickStartNotEnoughTeamsBody;

  /// No description provided for @teamOne.
  ///
  /// In en, this message translates to:
  /// **'Team 1'**
  String get teamOne;

  /// No description provided for @teamTwo.
  ///
  /// In en, this message translates to:
  /// **'Team 2'**
  String get teamTwo;

  /// No description provided for @quickStartChooseTeam1.
  ///
  /// In en, this message translates to:
  /// **'Choose Team 1'**
  String get quickStartChooseTeam1;

  /// No description provided for @quickStartChooseTeam2.
  ///
  /// In en, this message translates to:
  /// **'Choose Team 2'**
  String get quickStartChooseTeam2;

  /// No description provided for @quickStartCreateTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Teams'**
  String get quickStartCreateTeamsTitle;

  /// No description provided for @hintTeam1Example.
  ///
  /// In en, this message translates to:
  /// **'e.g. Red Eagles'**
  String get hintTeam1Example;

  /// No description provided for @hintTeam2Example.
  ///
  /// In en, this message translates to:
  /// **'e.g. Blue Lions'**
  String get hintTeam2Example;

  /// No description provided for @quickStartRandomTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Random Teams'**
  String get quickStartRandomTeamsTitle;

  /// No description provided for @quickStartReRollTeams.
  ///
  /// In en, this message translates to:
  /// **'Re-roll Teams'**
  String get quickStartReRollTeams;

  /// No description provided for @btnStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get btnStart;

  /// No description provided for @labelVs.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get labelVs;

  /// No description provided for @hybridModeSetup.
  ///
  /// In en, this message translates to:
  /// **'Hybrid Mode Setup'**
  String get hybridModeSetup;

  /// No description provided for @btnDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get btnDone;

  /// No description provided for @hybridAvailableModes.
  ///
  /// In en, this message translates to:
  /// **'Available Modes'**
  String get hybridAvailableModes;

  /// No description provided for @hybridRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String hybridRemaining(int count);

  /// No description provided for @hybridDragHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press to drag into a group, or tap to add to the first group.'**
  String get hybridDragHint;

  /// No description provided for @hybridAllModesAssigned.
  ///
  /// In en, this message translates to:
  /// **'All modes assigned to groups.'**
  String get hybridAllModesAssigned;

  /// No description provided for @hybridModeGroups.
  ///
  /// In en, this message translates to:
  /// **'Mode Groups'**
  String get hybridModeGroups;

  /// No description provided for @hybridAddGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get hybridAddGroup;

  /// No description provided for @hybridAddGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Add a group above, then drag or tap modes into it.'**
  String get hybridAddGroupHint;

  /// No description provided for @hybridGroupN.
  ///
  /// In en, this message translates to:
  /// **'Group {n}'**
  String hybridGroupN(int n);

  /// No description provided for @hybridDragModesHere.
  ///
  /// In en, this message translates to:
  /// **'Drag modes here'**
  String get hybridDragModesHere;

  /// No description provided for @hybridTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Each group defines a round of play. Teams cycle through all mode groups.'**
  String get hybridTip;

  /// No description provided for @pageTournamentDetails.
  ///
  /// In en, this message translates to:
  /// **'Tournament Details'**
  String get pageTournamentDetails;

  /// No description provided for @tournamentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tournament not found.'**
  String get tournamentNotFound;

  /// No description provided for @assignAllTeamsInTournament.
  ///
  /// In en, this message translates to:
  /// **'All teams are already in this tournament.'**
  String get assignAllTeamsInTournament;

  /// No description provided for @assignTournamentAllClubs.
  ///
  /// In en, this message translates to:
  /// **'Tournament is already in all groups.'**
  String get assignTournamentAllClubs;

  /// No description provided for @snackbarAddTeamsFirstCreate.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 teams before creating games.'**
  String get snackbarAddTeamsFirstCreate;

  /// No description provided for @dialogClearAllGames.
  ///
  /// In en, this message translates to:
  /// **'Clear All Games'**
  String get dialogClearAllGames;

  /// No description provided for @dialogClearAllGamesBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all games in this tournament?'**
  String get dialogClearAllGamesBody;

  /// No description provided for @btnClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get btnClear;

  /// No description provided for @btnCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get btnCreateGame;

  /// No description provided for @btnClearGames.
  ///
  /// In en, this message translates to:
  /// **'Clear Games'**
  String get btnClearGames;

  /// No description provided for @tournamentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode: {name}'**
  String tournamentModeLabel(String name);

  /// No description provided for @tournamentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {name}'**
  String tournamentStatusLabel(String name);

  /// No description provided for @tournamentTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Teams: {count}'**
  String tournamentTeamsLabel(int count);

  /// No description provided for @tournamentGamesLabel.
  ///
  /// In en, this message translates to:
  /// **'Games: {count}'**
  String tournamentGamesLabel(int count);

  /// No description provided for @sectionHybridGroups.
  ///
  /// In en, this message translates to:
  /// **'Hybrid Groups'**
  String get sectionHybridGroups;

  /// No description provided for @noHybridGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No hybrid groups configured yet.'**
  String get noHybridGroupsYet;

  /// No description provided for @noTeamsAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No teams assigned yet.'**
  String get noTeamsAssignedYet;

  /// No description provided for @nPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} player(s)'**
  String nPlayersCount(int count);

  /// No description provided for @sectionLeagueStandings.
  ///
  /// In en, this message translates to:
  /// **'League Standings'**
  String get sectionLeagueStandings;

  /// No description provided for @labelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labelUnknown;

  /// No description provided for @sectionGamesCount.
  ///
  /// In en, this message translates to:
  /// **'Games ({count})'**
  String sectionGamesCount(int count);

  /// No description provided for @noGamesCreatedYet.
  ///
  /// In en, this message translates to:
  /// **'No games created yet.'**
  String get noGamesCreatedYet;

  /// No description provided for @notInAnyClubsYet.
  ///
  /// In en, this message translates to:
  /// **'Not in any groups yet.'**
  String get notInAnyClubsYet;

  /// No description provided for @clubPlayersAndTeams.
  ///
  /// In en, this message translates to:
  /// **'{players} player(s) • {teams} team(s)'**
  String clubPlayersAndTeams(int players, int teams);

  /// No description provided for @labelStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get labelStyle;

  /// No description provided for @assignNothingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Nothing available to assign.'**
  String get assignNothingAvailable;

  /// No description provided for @btnDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get btnDeleteAll;

  /// No description provided for @statusSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get statusSetup;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get statusDue;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// No description provided for @labelLate.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get labelLate;

  /// No description provided for @statPts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get statPts;

  /// No description provided for @statEsc.
  ///
  /// In en, this message translates to:
  /// **'Esc'**
  String get statEsc;

  /// No description provided for @statGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get statGames;

  /// No description provided for @statLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get statLost;

  /// No description provided for @doghouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Doghouse'**
  String get doghouseTitle;

  /// No description provided for @doghouseGameHistory.
  ///
  /// In en, this message translates to:
  /// **'Game History'**
  String get doghouseGameHistory;

  /// No description provided for @doghouseEscaped.
  ///
  /// In en, this message translates to:
  /// **'Escaped'**
  String get doghouseEscaped;

  /// No description provided for @doghouseEjected.
  ///
  /// In en, this message translates to:
  /// **'Ejected'**
  String get doghouseEjected;

  /// No description provided for @doghouseNGamesLost.
  ///
  /// In en, this message translates to:
  /// **'{count} lost'**
  String doghouseNGamesLost(int count);

  /// No description provided for @doghouseNoGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet.'**
  String get doghouseNoGamesYet;

  /// No description provided for @doghouseNoGamesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Games will appear here once a team finishes.'**
  String get doghouseNoGamesYetBody;

  /// No description provided for @doghouseNoTournamentsYet.
  ///
  /// In en, this message translates to:
  /// **'No tournaments yet.'**
  String get doghouseNoTournamentsYet;

  /// No description provided for @doghouseNoTournamentsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap New Tournament to get started.'**
  String get doghouseNoTournamentsHint;

  /// No description provided for @doghouseDeleteTournamentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Tournament?'**
  String get doghouseDeleteTournamentTitle;

  /// No description provided for @doghouseDeleteTournamentBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\" and all its data.'**
  String doghouseDeleteTournamentBody(String name);

  /// No description provided for @doghouseDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Tournaments?'**
  String get doghouseDeleteAllTitle;

  /// No description provided for @doghouseDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} tournament(s).'**
  String doghouseDeleteAllBody(int count);

  /// No description provided for @doghouseNewTournament.
  ///
  /// In en, this message translates to:
  /// **'New Tournament'**
  String get doghouseNewTournament;

  /// No description provided for @doghouseTournamentHistory.
  ///
  /// In en, this message translates to:
  /// **'Tournament History ({count})'**
  String doghouseTournamentHistory(int count);

  /// No description provided for @doghouseStatsPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String doghouseStatsPlayers(int count);

  /// No description provided for @doghouseStatsGames.
  ///
  /// In en, this message translates to:
  /// **'{count} games'**
  String doghouseStatsGames(int count);

  /// No description provided for @doghouseStatsEscapes.
  ///
  /// In en, this message translates to:
  /// **'{count} escapes'**
  String doghouseStatsEscapes(int count);

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get btnStop;

  /// No description provided for @btnUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get btnUndo;

  /// No description provided for @labelOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get labelOptions;

  /// No description provided for @labelGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get labelGotIt;

  /// No description provided for @labelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// No description provided for @labelAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get labelAssignment;

  /// No description provided for @labelEscapePoints.
  ///
  /// In en, this message translates to:
  /// **'Escape Points'**
  String get labelEscapePoints;

  /// No description provided for @doghouseEscapePointsHelp.
  ///
  /// In en, this message translates to:
  /// **'Points the doghouse team must score to escape. A point is earned each time the serving (doghouse) team wins a rally. The score resets to zero after each game lost.'**
  String get doghouseEscapePointsHelp;

  /// No description provided for @labelLossLimit.
  ///
  /// In en, this message translates to:
  /// **'Loss Limit'**
  String get labelLossLimit;

  /// No description provided for @doghouseLossLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'How many games the doghouse team can lose before being automatically ejected. Each time the court team wins a rally, one game is lost and the point score resets to zero.'**
  String get doghouseLossLimitHelp;

  /// No description provided for @hintPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get hintPlayerName;

  /// No description provided for @doghouseScoreboard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get doghouseScoreboard;

  /// No description provided for @doghouseTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up'**
  String get doghouseTimeUp;

  /// No description provided for @doghouseTimerEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The session timer has ended. Complete the tournament now?'**
  String get doghouseTimerEndedBody;

  /// No description provided for @doghouseCompleteTournament.
  ///
  /// In en, this message translates to:
  /// **'Complete Tournament'**
  String get doghouseCompleteTournament;

  /// No description provided for @doghouseContinueScoring.
  ///
  /// In en, this message translates to:
  /// **'Continue scoring'**
  String get doghouseContinueScoring;

  /// No description provided for @doghouseSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute {name}'**
  String doghouseSubstitute(String name);

  /// No description provided for @doghouseReturnToQueue.
  ///
  /// In en, this message translates to:
  /// **'{name} will return to the queue.'**
  String doghouseReturnToQueue(String name);

  /// No description provided for @doghouseAddPlayersToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add Players to Queue'**
  String get doghouseAddPlayersToQueue;

  /// No description provided for @doghouseNAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String doghouseNAdded(int count);

  /// No description provided for @doghouseLateTagInfo.
  ///
  /// In en, this message translates to:
  /// **'All players added here will be tagged \"Late\" in stats.'**
  String get doghouseLateTagInfo;

  /// No description provided for @doghouseNoPlayersMatch.
  ///
  /// In en, this message translates to:
  /// **'No players match.'**
  String get doghouseNoPlayersMatch;

  /// No description provided for @doghouseAdd4Random.
  ///
  /// In en, this message translates to:
  /// **'Add 4 random'**
  String get doghouseAdd4Random;

  /// No description provided for @doghouseNoLatePlayersYet.
  ///
  /// In en, this message translates to:
  /// **'No late players added yet.'**
  String get doghouseNoLatePlayersYet;

  /// No description provided for @doghouseEscapedExcl.
  ///
  /// In en, this message translates to:
  /// **'Escaped!'**
  String get doghouseEscapedExcl;

  /// No description provided for @doghouseEscapedScoreMsg.
  ///
  /// In en, this message translates to:
  /// **'{names} scored {points} points!'**
  String doghouseEscapedScoreMsg(String names, int points);

  /// No description provided for @doghouseEscapeDesc.
  ///
  /// In en, this message translates to:
  /// **'They escape the doghouse and return to the queue.'**
  String get doghouseEscapeDesc;

  /// No description provided for @doghouseEscapeBtn.
  ///
  /// In en, this message translates to:
  /// **'Escape!'**
  String get doghouseEscapeBtn;

  /// No description provided for @doghouseEjectedExcl.
  ///
  /// In en, this message translates to:
  /// **'Ejected!'**
  String get doghouseEjectedExcl;

  /// No description provided for @doghouseEjectedScoreMsg.
  ///
  /// In en, this message translates to:
  /// **'{names} lost {count} games!'**
  String doghouseEjectedScoreMsg(String names, int count);

  /// No description provided for @doghouseEjectDesc.
  ///
  /// In en, this message translates to:
  /// **'They are ejected from the doghouse and return to the queue.'**
  String get doghouseEjectDesc;

  /// No description provided for @doghouseEjectTeam.
  ///
  /// In en, this message translates to:
  /// **'Eject Team'**
  String get doghouseEjectTeam;

  /// No description provided for @doghouseLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without ending game?'**
  String get doghouseLeaveTitle;

  /// No description provided for @doghouseLeaveBodyPts.
  ///
  /// In en, this message translates to:
  /// **'The current team has {count} unrecorded point(s). Leaving now will discard them.'**
  String doghouseLeaveBodyPts(int count);

  /// No description provided for @doghouseLeaveBodyEmpty.
  ///
  /// In en, this message translates to:
  /// **'The current team\'s unrecorded data will be lost.'**
  String get doghouseLeaveBodyEmpty;

  /// No description provided for @doghouseLeaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Leave anyway'**
  String get doghouseLeaveAnyway;

  /// No description provided for @doghouseTournamentComplete.
  ///
  /// In en, this message translates to:
  /// **'Tournament Complete'**
  String get doghouseTournamentComplete;

  /// No description provided for @doghouseSummaryStats.
  ///
  /// In en, this message translates to:
  /// **'{games} game(s) · {escapes} escapes'**
  String doghouseSummaryStats(int games, int escapes);

  /// No description provided for @doghouseFinalStandings.
  ///
  /// In en, this message translates to:
  /// **'Final Standings'**
  String get doghouseFinalStandings;

  /// No description provided for @doghousePairStat.
  ///
  /// In en, this message translates to:
  /// **'{escapes} escaped · {losses} lost'**
  String doghousePairStat(int escapes, int losses);

  /// No description provided for @doghousePlayerStats.
  ///
  /// In en, this message translates to:
  /// **'Player Stats'**
  String get doghousePlayerStats;

  /// No description provided for @doghouseSessionTimer.
  ///
  /// In en, this message translates to:
  /// **'SESSION TIMER'**
  String get doghouseSessionTimer;

  /// No description provided for @doghouseGameplayControls.
  ///
  /// In en, this message translates to:
  /// **'Gameplay Controls'**
  String get doghouseGameplayControls;

  /// No description provided for @doghouseInDoghouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Doghouse'**
  String get doghouseInDoghouseLabel;

  /// No description provided for @doghouseMatchControls.
  ///
  /// In en, this message translates to:
  /// **'Match Controls'**
  String get doghouseMatchControls;

  /// No description provided for @doghouseStartRestart.
  ///
  /// In en, this message translates to:
  /// **'Start / Restart'**
  String get doghouseStartRestart;

  /// No description provided for @doghouseTournamentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tournament completed'**
  String get doghouseTournamentCompleted;

  /// No description provided for @doghouseNotEnoughInQueue.
  ///
  /// In en, this message translates to:
  /// **'Not enough players in queue.'**
  String get doghouseNotEnoughInQueue;

  /// No description provided for @doghouseSuggestedTeam.
  ///
  /// In en, this message translates to:
  /// **'Suggested Team'**
  String get doghouseSuggestedTeam;

  /// No description provided for @doghouseSelectPlayers.
  ///
  /// In en, this message translates to:
  /// **'Select {needed} players ({selected} / {needed})'**
  String doghouseSelectPlayers(int needed, int selected);

  /// No description provided for @doghouseQueueTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Queue — tap to add'**
  String get doghouseQueueTapToAdd;

  /// No description provided for @doghouseEnterDoghouse.
  ///
  /// In en, this message translates to:
  /// **'Enter Doghouse'**
  String get doghouseEnterDoghouse;

  /// No description provided for @doghouseViewAllGames.
  ///
  /// In en, this message translates to:
  /// **'View all completed games'**
  String get doghouseViewAllGames;

  /// No description provided for @doghouseEscapePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pt escape'**
  String doghouseEscapePointsLabel(int count);

  /// No description provided for @doghouseLossLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} loss limit'**
  String doghouseLossLimitLabel(int count);

  /// No description provided for @doghouseAddPlayerToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add Player to Queue'**
  String get doghouseAddPlayerToQueue;

  /// No description provided for @doghouseUndoCompletion.
  ///
  /// In en, this message translates to:
  /// **'Undo Completion'**
  String get doghouseUndoCompletion;

  /// No description provided for @doghouseSaveAndReturn.
  ///
  /// In en, this message translates to:
  /// **'Save and Return'**
  String get doghouseSaveAndReturn;

  /// No description provided for @doghouseGameLost.
  ///
  /// In en, this message translates to:
  /// **'Game\nLost'**
  String get doghouseGameLost;

  /// No description provided for @doghouseUndoLoss.
  ///
  /// In en, this message translates to:
  /// **'Undo\nLoss'**
  String get doghouseUndoLoss;

  /// No description provided for @doghouseUndoGame.
  ///
  /// In en, this message translates to:
  /// **'Undo\nGame'**
  String get doghouseUndoGame;

  /// No description provided for @doghouseUndoLastGame.
  ///
  /// In en, this message translates to:
  /// **'Undo Last Game'**
  String get doghouseUndoLastGame;

  /// No description provided for @doghouseTournamentSetup.
  ///
  /// In en, this message translates to:
  /// **'Tournament Setup'**
  String get doghouseTournamentSetup;

  /// No description provided for @doghouseTapToAddPlayers.
  ///
  /// In en, this message translates to:
  /// **'Tap to add players'**
  String get doghouseTapToAddPlayers;

  /// No description provided for @doghouseNPlayersAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} players added'**
  String doghouseNPlayersAdded(int count);

  /// No description provided for @doghouseNeedAtLeastN.
  ///
  /// In en, this message translates to:
  /// **'{count} added · need at least {min}'**
  String doghouseNeedAtLeastN(int count, int min);

  /// No description provided for @doghouseClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get doghouseClearAll;

  /// No description provided for @doghouseFillNRandom.
  ///
  /// In en, this message translates to:
  /// **'Fill {count} random'**
  String doghouseFillNRandom(int count);

  /// No description provided for @doghouseSetupNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'No players added yet.'**
  String get doghouseSetupNoPlayers;

  /// No description provided for @doghouseSourceExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing player'**
  String get doghouseSourceExisting;

  /// No description provided for @doghouseSourceNew.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get doghouseSourceNew;

  /// No description provided for @doghouseSourceRandom.
  ///
  /// In en, this message translates to:
  /// **'Random placeholder'**
  String get doghouseSourceRandom;

  /// No description provided for @doghouseTournamentName.
  ///
  /// In en, this message translates to:
  /// **'Tournament Name'**
  String get doghouseTournamentName;

  /// No description provided for @doghouseSetupGood.
  ///
  /// In en, this message translates to:
  /// **'Setup looks good!'**
  String get doghouseSetupGood;

  /// No description provided for @doghouseSetupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Setup incomplete'**
  String get doghouseSetupIncomplete;

  /// No description provided for @doghouseRemoveAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all players?'**
  String get doghouseRemoveAllTitle;

  /// No description provided for @doghouseRemoveAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all added players from the list.'**
  String get doghouseRemoveAllBody;

  /// No description provided for @doghouseRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get doghouseRemoveAll;

  /// No description provided for @doghouseAssignmentManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get doghouseAssignmentManual;

  /// No description provided for @doghouseAssignmentAutomated.
  ///
  /// In en, this message translates to:
  /// **'Automated'**
  String get doghouseAssignmentAutomated;

  /// No description provided for @doghouseAddedCount.
  ///
  /// In en, this message translates to:
  /// **'Added ({added}/{total})'**
  String doghouseAddedCount(int added, int total);

  /// No description provided for @statsRounds.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String statsRounds(int count);

  /// No description provided for @statsPtsScored.
  ///
  /// In en, this message translates to:
  /// **'{total} pts scored'**
  String statsPtsScored(int total);

  /// No description provided for @statsTeams.
  ///
  /// In en, this message translates to:
  /// **'{count} teams'**
  String statsTeams(int count);

  /// No description provided for @statsCourts.
  ///
  /// In en, this message translates to:
  /// **'{count} courts'**
  String statsCourts(int count);

  /// No description provided for @statsMatchesOf.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} matches'**
  String statsMatchesOf(int completed, int total);

  /// No description provided for @statsGamesOf.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} games'**
  String statsGamesOf(int completed, int total);

  /// No description provided for @setupDuplicateNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Name'**
  String get setupDuplicateNameTitle;

  /// No description provided for @setupDuplicateNameBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already added to this tournament. Add anyway?'**
  String setupDuplicateNameBody(String name);

  /// No description provided for @btnAddAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add Anyway'**
  String get btnAddAnyway;

  /// No description provided for @setupSectionPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get setupSectionPlayers;

  /// No description provided for @setupSectionCreatePlayer.
  ///
  /// In en, this message translates to:
  /// **'Create Player'**
  String get setupSectionCreatePlayer;

  /// No description provided for @setupAddExistingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Add Existing Players ({count})'**
  String setupAddExistingPlayers(int count);

  /// No description provided for @setupSearchPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Search players…'**
  String get setupSearchPlayersHint;

  /// No description provided for @setupPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get setupPlayerNameHint;

  /// No description provided for @setupPlayersOf.
  ///
  /// In en, this message translates to:
  /// **'{count}/{target} players added'**
  String setupPlayersOf(int count, int target);

  /// No description provided for @setupTargetPlayers.
  ///
  /// In en, this message translates to:
  /// **'Target Players'**
  String get setupTargetPlayers;

  /// No description provided for @setupAvailableTime.
  ///
  /// In en, this message translates to:
  /// **'Available Time'**
  String get setupAvailableTime;

  /// No description provided for @setupMatchDuration.
  ///
  /// In en, this message translates to:
  /// **'Match Duration'**
  String get setupMatchDuration;

  /// No description provided for @setupCourts.
  ///
  /// In en, this message translates to:
  /// **'Courts'**
  String get setupCourts;

  /// No description provided for @setupBreakBetweenRounds.
  ///
  /// In en, this message translates to:
  /// **'Break Between Rounds'**
  String get setupBreakBetweenRounds;

  /// No description provided for @setupFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get setupFormat;

  /// No description provided for @setupPlannedStartTime.
  ///
  /// In en, this message translates to:
  /// **'Planned Start Time'**
  String get setupPlannedStartTime;

  /// No description provided for @setupPlannedEndTime.
  ///
  /// In en, this message translates to:
  /// **'Planned End Time'**
  String get setupPlannedEndTime;

  /// No description provided for @setupSchedulePreview.
  ///
  /// In en, this message translates to:
  /// **'Schedule Preview'**
  String get setupSchedulePreview;

  /// No description provided for @setupRoundDuration.
  ///
  /// In en, this message translates to:
  /// **'Round duration'**
  String get setupRoundDuration;

  /// No description provided for @setupRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get setupRoundsLabel;

  /// No description provided for @setupScheduledDuration.
  ///
  /// In en, this message translates to:
  /// **'Scheduled duration'**
  String get setupScheduledDuration;

  /// No description provided for @setupScheduledEndTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled end time'**
  String get setupScheduledEndTime;

  /// No description provided for @setupSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get setupSuggestions;

  /// No description provided for @setupFormatAutoAllplay.
  ///
  /// In en, this message translates to:
  /// **'Auto-Allplay'**
  String get setupFormatAutoAllplay;

  /// No description provided for @setupCourtsInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Currently fixed at 1 court.\n\nMulti-court support — assign and track multiple simultaneous courts with optimal rotation — is planned for a future release.'**
  String get setupCourtsInfoBody;

  /// No description provided for @setupSeedingRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get setupSeedingRandom;

  /// No description provided for @setupSeedingSeeded.
  ///
  /// In en, this message translates to:
  /// **'Seeded'**
  String get setupSeedingSeeded;

  /// No description provided for @setupOddTeamsByes.
  ///
  /// In en, this message translates to:
  /// **'Byes'**
  String get setupOddTeamsByes;

  /// No description provided for @setupOddTeamsPlayIn.
  ///
  /// In en, this message translates to:
  /// **'Play-in'**
  String get setupOddTeamsPlayIn;

  /// No description provided for @setupSectionTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get setupSectionTeams;

  /// No description provided for @setupRemoveAllTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all teams?'**
  String get setupRemoveAllTeamsTitle;

  /// No description provided for @setupRemoveAllTeamsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all added teams from the list.'**
  String get setupRemoveAllTeamsBody;

  /// No description provided for @setupNoTeamsMatch.
  ///
  /// In en, this message translates to:
  /// **'No teams match.'**
  String get setupNoTeamsMatch;

  /// No description provided for @setupNoTeamsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No teams added yet.'**
  String get setupNoTeamsAddedYet;

  /// No description provided for @setupTeamNameHint.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get setupTeamNameHint;

  /// No description provided for @setupAddExistingTeams.
  ///
  /// In en, this message translates to:
  /// **'Add Existing Teams ({count})'**
  String setupAddExistingTeams(int count);

  /// No description provided for @setupSearchTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Search teams…'**
  String get setupSearchTeamsHint;

  /// No description provided for @setupCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get setupCreateTeam;

  /// No description provided for @setupGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get setupGeneration;

  /// No description provided for @setupOddTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Odd Teams'**
  String get setupOddTeamsLabel;

  /// No description provided for @setupEarlyRounds.
  ///
  /// In en, this message translates to:
  /// **'Early Rounds'**
  String get setupEarlyRounds;

  /// No description provided for @setupFinalRounds.
  ///
  /// In en, this message translates to:
  /// **'Final Rounds'**
  String get setupFinalRounds;

  /// No description provided for @setupReadyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to start!'**
  String get setupReadyToStart;

  /// No description provided for @setupAddAllTeams.
  ///
  /// In en, this message translates to:
  /// **'Add all {count} teams to continue'**
  String setupAddAllTeams(int count);

  /// No description provided for @setupTapToAddTeams.
  ///
  /// In en, this message translates to:
  /// **'Tap to add teams'**
  String get setupTapToAddTeams;

  /// No description provided for @setupTeamsOf.
  ///
  /// In en, this message translates to:
  /// **'{count}/{target} teams added'**
  String setupTeamsOf(int count, int target);

  /// No description provided for @overviewSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewSectionOverview;

  /// No description provided for @overviewSectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Schedule preview'**
  String get overviewSectionTimeline;

  /// No description provided for @timelineStart.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String timelineStart(String time);

  /// No description provided for @timelinePredictedEnd.
  ///
  /// In en, this message translates to:
  /// **'Predicted end: {time}'**
  String timelinePredictedEnd(String time);

  /// No description provided for @timelineRound.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String timelineRound(int number);

  /// No description provided for @timelineBreakUntil.
  ///
  /// In en, this message translates to:
  /// **'Break until {time}'**
  String timelineBreakUntil(String time);

  /// No description provided for @timelineScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament schedule'**
  String get timelineScheduleTitle;

  /// No description provided for @timelineTournamentStart.
  ///
  /// In en, this message translates to:
  /// **'Tournament start'**
  String get timelineTournamentStart;

  /// No description provided for @timelineGameDuration.
  ///
  /// In en, this message translates to:
  /// **'Game duration (pending rounds)'**
  String get timelineGameDuration;

  /// No description provided for @timelineBreakDurationPending.
  ///
  /// In en, this message translates to:
  /// **'Break duration (pending rounds)'**
  String get timelineBreakDurationPending;

  /// No description provided for @timelinePaceAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pace alerts'**
  String get timelinePaceAlertsTitle;

  /// No description provided for @timelinePaceAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flag rounds as on track, due, or overdue'**
  String get timelinePaceAlertsSubtitle;

  /// No description provided for @timelineEditStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get timelineEditStartTime;

  /// No description provided for @timelineMatchDuration.
  ///
  /// In en, this message translates to:
  /// **'Match duration'**
  String get timelineMatchDuration;

  /// No description provided for @timelineBreakAfterRound.
  ///
  /// In en, this message translates to:
  /// **'Break after round'**
  String get timelineBreakAfterRound;

  /// No description provided for @overviewSectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get overviewSectionSchedule;

  /// No description provided for @overviewGamesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} games completed'**
  String overviewGamesCompleted(int completed, int total);

  /// No description provided for @overviewStatsSummary.
  ///
  /// In en, this message translates to:
  /// **'{rounds} rounds  ·  {courts} courts  ·  {players} players'**
  String overviewStatsSummary(int rounds, int courts, int players);

  /// No description provided for @overviewFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished: {time}'**
  String overviewFinished(String time);

  /// No description provided for @overviewEstFinish.
  ///
  /// In en, this message translates to:
  /// **'Est. finish: {time}'**
  String overviewEstFinish(String time);

  /// No description provided for @overviewSectionPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players ({count})'**
  String overviewSectionPlayers(int count);

  /// No description provided for @overviewAddPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Added players join as a late entry.'**
  String get overviewAddPlayerSubtitle;

  /// No description provided for @overviewAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {name}?'**
  String overviewAddConfirm(String name);

  /// No description provided for @overviewAddLateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will join as a late entry. Remaining pairings will be reshuffled — some players may end up with an unequal number of games.'**
  String overviewAddLateBody(String name);

  /// No description provided for @overviewSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap out {name}'**
  String overviewSwapTitle(String name);

  /// No description provided for @overviewSwapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from upcoming rounds.'**
  String overviewSwapSubtitle(String name);

  /// No description provided for @overviewEjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Eject {name}?'**
  String overviewEjectTitle(String name);

  /// No description provided for @overviewEjectBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from all upcoming rounds. Remaining pairings will be reshuffled — some players may end up with an unequal number of games. Completed games remain in the stats.'**
  String overviewEjectBody(String name);

  /// No description provided for @overviewEjectBtn.
  ///
  /// In en, this message translates to:
  /// **'Eject'**
  String get overviewEjectBtn;

  /// No description provided for @overviewEjectChoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from the lineup. Completed games remain in the stats. Choose how their remaining games are handled:'**
  String overviewEjectChoiceIntro(String name);

  /// No description provided for @overviewEjectOptPlaceholderReshuffleTitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder & reshuffle'**
  String get overviewEjectOptPlaceholderReshuffleTitle;

  /// No description provided for @overviewEjectOptPlaceholderReshuffleDesc.
  ///
  /// In en, this message translates to:
  /// **'Every remaining round is re-paired without {name}. If their game this round has already started elsewhere, that seat becomes an anonymous Placeholder so the other three can still play.'**
  String overviewEjectOptPlaceholderReshuffleDesc(String name);

  /// No description provided for @overviewEjectOptPlaceholderThroughoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder throughout'**
  String get overviewEjectOptPlaceholderThroughoutTitle;

  /// No description provided for @overviewEjectOptPlaceholderThroughoutDesc.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s seat becomes an anonymous Placeholder in every remaining round instead. Nobody else\'s pairings or schedule change.'**
  String overviewEjectOptPlaceholderThroughoutDesc(String name);

  /// No description provided for @overviewPlaceholderName.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get overviewPlaceholderName;

  /// No description provided for @overviewEditPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Player'**
  String get overviewEditPlayer;

  /// No description provided for @overviewAllPlayersAlready.
  ///
  /// In en, this message translates to:
  /// **'All existing players are already in this tournament.'**
  String get overviewAllPlayersAlready;

  /// No description provided for @overviewRound.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String overviewRound(int number);

  /// No description provided for @scorecardParallelCourts.
  ///
  /// In en, this message translates to:
  /// **'{count} courts — played in parallel'**
  String scorecardParallelCourts(int count);

  /// No description provided for @overviewActual.
  ///
  /// In en, this message translates to:
  /// **'actual'**
  String get overviewActual;

  /// No description provided for @overviewBreakUntil.
  ///
  /// In en, this message translates to:
  /// **'· Break until {time}'**
  String overviewBreakUntil(String time);

  /// No description provided for @scrambleStatusSwappedOut.
  ///
  /// In en, this message translates to:
  /// **'swapped out'**
  String get scrambleStatusSwappedOut;

  /// No description provided for @scrambleStatusSwappedIn.
  ///
  /// In en, this message translates to:
  /// **'sub in'**
  String get scrambleStatusSwappedIn;

  /// No description provided for @scrambleStatusLate.
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get scrambleStatusLate;

  /// No description provided for @tooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltipEdit;

  /// No description provided for @tooltipEject.
  ///
  /// In en, this message translates to:
  /// **'Eject'**
  String get tooltipEject;

  /// No description provided for @tooltipSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get tooltipSwap;

  /// No description provided for @tooltipRankings.
  ///
  /// In en, this message translates to:
  /// **'Player Rankings'**
  String get tooltipRankings;

  /// No description provided for @scorecardSwapSides.
  ///
  /// In en, this message translates to:
  /// **'Swap Sides'**
  String get scorecardSwapSides;

  /// No description provided for @scorecardSwapSidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch left and right display'**
  String get scorecardSwapSidesSubtitle;

  /// No description provided for @scorecardMatchHistory.
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get scorecardMatchHistory;

  /// No description provided for @scorecardMatchHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Point-by-point scoring timeline'**
  String get scorecardMatchHistorySubtitle;

  /// No description provided for @scorecardPlannedStart.
  ///
  /// In en, this message translates to:
  /// **'Planned start'**
  String get scorecardPlannedStart;

  /// No description provided for @scorecardPlannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Planned end'**
  String get scorecardPlannedEnd;

  /// No description provided for @scorecardEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get scorecardEnd;

  /// No description provided for @scorecardOverSchedule.
  ///
  /// In en, this message translates to:
  /// **'Over schedule!'**
  String get scorecardOverSchedule;

  /// No description provided for @scorecardOverScheduleHurry.
  ///
  /// In en, this message translates to:
  /// **'Over schedule · Hurry up!'**
  String get scorecardOverScheduleHurry;

  /// No description provided for @scorecardStartsServing.
  ///
  /// In en, this message translates to:
  /// **'{name} starts serving'**
  String scorecardStartsServing(String name);

  /// No description provided for @scorecardUndoCompletion.
  ///
  /// In en, this message translates to:
  /// **'Undo Completion'**
  String get scorecardUndoCompletion;

  /// No description provided for @scorecardStartMatch.
  ///
  /// In en, this message translates to:
  /// **'Start Match'**
  String get scorecardStartMatch;

  /// No description provided for @scorecardCompleteGame.
  ///
  /// In en, this message translates to:
  /// **'Complete Game'**
  String get scorecardCompleteGame;

  /// No description provided for @scorecardManualScore.
  ///
  /// In en, this message translates to:
  /// **'Manually Set Score'**
  String get scorecardManualScore;

  /// No description provided for @scorecardBackToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Back to Schedule'**
  String get scorecardBackToSchedule;

  /// No description provided for @scorecardManualScoreBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Score Not Available'**
  String get scorecardManualScoreBlockedTitle;

  /// No description provided for @scorecardManualScoreBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Manual score entry is only available before live scoring has started. This prevents accidentally overwriting points that were already tracked.'**
  String get scorecardManualScoreBlockedBody;

  /// No description provided for @scorecardEditScoreOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Override current score?'**
  String get scorecardEditScoreOverrideTitle;

  /// No description provided for @scorecardEditScoreOverrideBody.
  ///
  /// In en, this message translates to:
  /// **'This game already has a score. Editing it will replace the current result.'**
  String get scorecardEditScoreOverrideBody;

  /// No description provided for @scorecardEditWinnerLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Winner can\'t change'**
  String get scorecardEditWinnerLockedTitle;

  /// No description provided for @scorecardEditWinnerLockedBody.
  ///
  /// In en, this message translates to:
  /// **'The next match has already started, so the winner of this match can\'t change. You can still correct the points as long as the same team wins.'**
  String get scorecardEditWinnerLockedBody;

  /// No description provided for @scorecardManualScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this when the game was played without live scoring. Enter the final score for both sides and complete the game.'**
  String get scorecardManualScoreDescription;

  /// No description provided for @scorecardManualScoreTimeUpNote.
  ///
  /// In en, this message translates to:
  /// **'If the game was still in play when the timer ran out, you can set the final score manually here.'**
  String get scorecardManualScoreTimeUpNote;

  /// No description provided for @btnOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOK;

  /// No description provided for @btnAdjustFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Adjust Final Score'**
  String get btnAdjustFinalScore;

  /// No description provided for @btnRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get btnRestart;

  /// No description provided for @btnResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get btnResume;

  /// No description provided for @btnApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get btnApply;

  /// No description provided for @labelMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String labelMinutes(int n);

  /// No description provided for @matchScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get matchScorecard;

  /// No description provided for @matchOptions.
  ///
  /// In en, this message translates to:
  /// **'Match Options'**
  String get matchOptions;

  /// No description provided for @matchViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View point-by-point history'**
  String get matchViewHistory;

  /// No description provided for @matchComplete.
  ///
  /// In en, this message translates to:
  /// **'Match complete'**
  String get matchComplete;

  /// No description provided for @matchSetCompleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Set complete — undo set to edit score'**
  String get matchSetCompleteBanner;

  /// No description provided for @matchSuggestedToServe.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested to start serving'**
  String matchSuggestedToServe(String name);

  /// No description provided for @matchSuggestedReferee.
  ///
  /// In en, this message translates to:
  /// **'{name} suggested as referee'**
  String matchSuggestedReferee(String name);

  /// No description provided for @matchAssignRefereeManually.
  ///
  /// In en, this message translates to:
  /// **'Assign a referee manually'**
  String get matchAssignRefereeManually;

  /// No description provided for @matchScoresTiedSet.
  ///
  /// In en, this message translates to:
  /// **'Scores are tied — a set cannot end in a draw.'**
  String get matchScoresTiedSet;

  /// No description provided for @matchScoresTiedMatch.
  ///
  /// In en, this message translates to:
  /// **'Scores are tied — a winner must be determined before completing.'**
  String get matchScoresTiedMatch;

  /// No description provided for @matchSetsTied.
  ///
  /// In en, this message translates to:
  /// **'Sets are tied — a winner must be determined before completing.'**
  String get matchSetsTied;

  /// No description provided for @matchUndoSet.
  ///
  /// In en, this message translates to:
  /// **'Undo Set'**
  String get matchUndoSet;

  /// No description provided for @matchCompleteSet.
  ///
  /// In en, this message translates to:
  /// **'Complete Set'**
  String get matchCompleteSet;

  /// No description provided for @matchUndoMatchCompletion.
  ///
  /// In en, this message translates to:
  /// **'Undo Match Completion'**
  String get matchUndoMatchCompletion;

  /// No description provided for @matchCompleteMatch.
  ///
  /// In en, this message translates to:
  /// **'Complete Match'**
  String get matchCompleteMatch;

  /// No description provided for @matchSetScoreManually.
  ///
  /// In en, this message translates to:
  /// **'Set Score Manually'**
  String get matchSetScoreManually;

  /// No description provided for @matchBackToBracket.
  ///
  /// In en, this message translates to:
  /// **'Back to Bracket'**
  String get matchBackToBracket;

  /// No description provided for @matchCourtLabel.
  ///
  /// In en, this message translates to:
  /// **'Court {court}'**
  String matchCourtLabel(int court);

  /// No description provided for @matchStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts {time}'**
  String matchStartsAt(String time);

  /// No description provided for @matchSetNScore.
  ///
  /// In en, this message translates to:
  /// **'Set {n} Score'**
  String matchSetNScore(int n);

  /// No description provided for @matchSetScore.
  ///
  /// In en, this message translates to:
  /// **'Set Score'**
  String get matchSetScore;

  /// No description provided for @bracketWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Team?'**
  String get bracketWithdrawTitle;

  /// No description provided for @bracketWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Withdraw \"{name}\"? Their pending matches will be resolved as walkovers.'**
  String bracketWithdrawBody(String name);

  /// No description provided for @bracketWithdrawBtn.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get bracketWithdrawBtn;

  /// No description provided for @bracketFinalRoundsFormat.
  ///
  /// In en, this message translates to:
  /// **'Final Rounds Format'**
  String get bracketFinalRoundsFormat;

  /// No description provided for @bracketEarlyRoundsFormat.
  ///
  /// In en, this message translates to:
  /// **'Early Rounds Format'**
  String get bracketEarlyRoundsFormat;

  /// No description provided for @bracketFinalRoundsAppliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies to the last {n} round(s)'**
  String bracketFinalRoundsAppliesTo(int n);

  /// No description provided for @bracketEarlyRoundsAppliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies to all early rounds'**
  String get bracketEarlyRoundsAppliesTo;

  /// No description provided for @setupSetsPerGame.
  ///
  /// In en, this message translates to:
  /// **'Sets per game'**
  String get setupSetsPerGame;

  /// No description provided for @setupPointsPerSet.
  ///
  /// In en, this message translates to:
  /// **'Points per set'**
  String get setupPointsPerSet;

  /// No description provided for @bracketBreakFinalRounds.
  ///
  /// In en, this message translates to:
  /// **'Break — Final Rounds'**
  String get bracketBreakFinalRounds;

  /// No description provided for @bracketBreakEarlyRounds.
  ///
  /// In en, this message translates to:
  /// **'Break — Early Rounds'**
  String get bracketBreakEarlyRounds;

  /// No description provided for @bracketNoBreak.
  ///
  /// In en, this message translates to:
  /// **'No break'**
  String get bracketNoBreak;

  /// No description provided for @bracketNoStartTime.
  ///
  /// In en, this message translates to:
  /// **'No start time set'**
  String get bracketNoStartTime;

  /// No description provided for @bracketStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts: {label}'**
  String bracketStartsLabel(String label);

  /// No description provided for @bracketTournamentWinner.
  ///
  /// In en, this message translates to:
  /// **'Tournament Winner'**
  String get bracketTournamentWinner;

  /// No description provided for @bracketRunnerUp.
  ///
  /// In en, this message translates to:
  /// **'Runner-up'**
  String get bracketRunnerUp;

  /// No description provided for @bracketThirdPlace.
  ///
  /// In en, this message translates to:
  /// **'3rd place'**
  String get bracketThirdPlace;

  /// No description provided for @bracketSectionTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams ({count})'**
  String bracketSectionTeams(int count);

  /// No description provided for @bracketSwapTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Team'**
  String get bracketSwapTeamTitle;

  /// No description provided for @bracketSwapTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replacing \"{name}\" in all pending matches.'**
  String bracketSwapTeamSubtitle(String name);

  /// No description provided for @bracketSearchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams…'**
  String get bracketSearchTeams;

  /// No description provided for @bracketNoTeamsInHub.
  ///
  /// In en, this message translates to:
  /// **'No teams in Teams Hub yet.'**
  String get bracketNoTeamsInHub;

  /// No description provided for @bracketAllTeamsInTournament.
  ///
  /// In en, this message translates to:
  /// **'All hub teams are already in this tournament.'**
  String get bracketAllTeamsInTournament;

  /// No description provided for @scorecardMatchTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Match Timer'**
  String get scorecardMatchTimerLabel;

  /// No description provided for @scorecardUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Games'**
  String get scorecardUpcomingGames;

  /// No description provided for @scorecardPlayerCount.
  ///
  /// In en, this message translates to:
  /// **'{n} players'**
  String scorecardPlayerCount(int n);

  /// No description provided for @scorecardGameCompletedLock.
  ///
  /// In en, this message translates to:
  /// **'Game completed — undo to edit scores'**
  String get scorecardGameCompletedLock;

  /// No description provided for @kotcTimeIsUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up'**
  String get kotcTimeIsUp;

  /// No description provided for @kotcSessionEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The session timer has ended. Complete the tournament now?'**
  String get kotcSessionEndedBody;

  /// No description provided for @kotcSubstituteTitle.
  ///
  /// In en, this message translates to:
  /// **'Substitute {name}'**
  String kotcSubstituteTitle(String name);

  /// No description provided for @kotcSubstituteBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will return to the queue.'**
  String kotcSubstituteBody(String name);

  /// No description provided for @kotcAddLateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Late Player?'**
  String get kotcAddLateTitle;

  /// No description provided for @kotcAddLateBody.
  ///
  /// In en, this message translates to:
  /// **'This player is joining late and won\'t have had the same opportunities as players who started at the beginning. Their stats will be tagged as \"Late\".'**
  String get kotcAddLateBody;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @kotcLateTag.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get kotcLateTag;

  /// No description provided for @kotcAdminTag.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get kotcAdminTag;

  /// No description provided for @kotcChangeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Change Admin'**
  String get kotcChangeAdmin;

  /// No description provided for @kotcChangeAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select who keeps score. The current admin returns to the queue.'**
  String get kotcChangeAdminSubtitle;

  /// No description provided for @kotcNextAdmin.
  ///
  /// In en, this message translates to:
  /// **'NEXT ADMIN'**
  String get kotcNextAdmin;

  /// No description provided for @kotcNextAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested from the current court team.'**
  String get kotcNextAdminNote;

  /// No description provided for @kotcGameWon.
  ///
  /// In en, this message translates to:
  /// **'Game Won!'**
  String get kotcGameWon;

  /// No description provided for @kotcReachedPoints.
  ///
  /// In en, this message translates to:
  /// **'{names} reached {points} points!'**
  String kotcReachedPoints(String names, int points);

  /// No description provided for @kotcEjectReturn.
  ///
  /// In en, this message translates to:
  /// **'They will be ejected and return to the queue.'**
  String get kotcEjectReturn;

  /// No description provided for @kotcEjectTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Eject Team?'**
  String get kotcEjectTeamTitle;

  /// No description provided for @kotcEjectTeamBodyPoints.
  ///
  /// In en, this message translates to:
  /// **'Current team will be ejected. Their {pts} pts will be recorded.'**
  String kotcEjectTeamBodyPoints(int pts);

  /// No description provided for @kotcEjectTeamBodyNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Current team will be ejected and return to the queue.'**
  String get kotcEjectTeamBodyNoPoints;

  /// No description provided for @kotcLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without ejecting?'**
  String get kotcLeaveTitle;

  /// No description provided for @kotcLeaveBodyPoints.
  ///
  /// In en, this message translates to:
  /// **'The current team has {pts} unrecorded points. Leaving now will discard them. Eject the team first to save their score.'**
  String kotcLeaveBodyPoints(int pts);

  /// No description provided for @kotcTournamentComplete.
  ///
  /// In en, this message translates to:
  /// **'Tournament complete'**
  String get kotcTournamentComplete;

  /// No description provided for @kotcGamesSummary.
  ///
  /// In en, this message translates to:
  /// **'{games} games · {pts} pts total'**
  String kotcGamesSummary(int games, int pts);

  /// No description provided for @kotcStatGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get kotcStatGames;

  /// No description provided for @kotcStatWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get kotcStatWins;

  /// No description provided for @kotcStatPts.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get kotcStatPts;

  /// No description provided for @kotcOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get kotcOptions;

  /// No description provided for @kotcHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View all completed games'**
  String get kotcHistorySubtitle;

  /// No description provided for @kotcTeamEjected.
  ///
  /// In en, this message translates to:
  /// **'Team\nEjected'**
  String get kotcTeamEjected;

  /// No description provided for @kotcUndoEject.
  ///
  /// In en, this message translates to:
  /// **'Undo\nEject'**
  String get kotcUndoEject;

  /// No description provided for @kotcUndoLastEjection.
  ///
  /// In en, this message translates to:
  /// **'Undo Last Ejection'**
  String get kotcUndoLastEjection;

  /// No description provided for @kotcUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get kotcUpNext;

  /// No description provided for @kotcChallengers.
  ///
  /// In en, this message translates to:
  /// **'Challengers'**
  String get kotcChallengers;

  /// No description provided for @kotcCourtLabel.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get kotcCourtLabel;

  /// No description provided for @kotcStrikeOff.
  ///
  /// In en, this message translates to:
  /// **'No strike'**
  String get kotcStrikeOff;

  /// No description provided for @kotcTeamSizeChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to new teams. The team on court keeps its size until it rotates out.'**
  String get kotcTeamSizeChangeNote;

  /// No description provided for @kotcWaitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get kotcWaitingForPlayers;

  /// No description provided for @kotcEjectChallenger.
  ///
  /// In en, this message translates to:
  /// **'Eject challenger'**
  String get kotcEjectChallenger;

  /// No description provided for @kotcEjectChallengerShort.
  ///
  /// In en, this message translates to:
  /// **'Eject\nChallenger'**
  String get kotcEjectChallengerShort;

  /// No description provided for @kotcUndoEjectChallenger.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get kotcUndoEjectChallenger;

  /// No description provided for @kotcStrikePoints.
  ///
  /// In en, this message translates to:
  /// **'{n} pt strike'**
  String kotcStrikePoints(int n);

  /// No description provided for @kotcAdd4Random.
  ///
  /// In en, this message translates to:
  /// **'Add 4 random'**
  String get kotcAdd4Random;

  /// No description provided for @kotcExistingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Existing Players ({n})'**
  String kotcExistingPlayers(int n);

  /// No description provided for @kotcPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get kotcPlayerNameHint;

  /// No description provided for @labelEject.
  ///
  /// In en, this message translates to:
  /// **'Eject'**
  String get labelEject;

  /// No description provided for @kotcSetupStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get kotcSetupStyleLabel;

  /// No description provided for @kotcSetupStyleHelp.
  ///
  /// In en, this message translates to:
  /// **'The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court.'**
  String get kotcSetupStyleHelp;

  /// No description provided for @kotcSetupAssignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get kotcSetupAssignmentLabel;

  /// No description provided for @kotcSetupAssignmentHelp.
  ///
  /// In en, this message translates to:
  /// **'How the next court team is chosen.\n\nManual — the coach selects players from the queue by tapping them.\n\nAutomated — TournaQ suggests the best team, prioritising players who have waited longest and haven\'t been paired together recently. The coach can re-roll before confirming.\n\nAutomated — All Play — like Automated but no dedicated coach. A rotating admin keeps score while everyone else plays. TournaQ picks a random starting admin and suggests the next handoff from the ejected team after each game.'**
  String get kotcSetupAssignmentHelp;

  /// No description provided for @kotcSetupPlayersHelp.
  ///
  /// In en, this message translates to:
  /// **'Target number of players for the session. Used when auto-filling random players. Actual participants are added in the Players section below.'**
  String get kotcSetupPlayersHelp;

  /// No description provided for @autoAllplayLowPlayersWarning.
  ///
  /// In en, this message translates to:
  /// **'Auto-Allplay works with fewer players, but rotation may feel clunky below {count} players.'**
  String autoAllplayLowPlayersWarning(int count);

  /// No description provided for @kotcSetupTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Total session duration. The timer counts down from this value. When time runs out you will be prompted to complete the tournament or keep scoring.'**
  String get kotcSetupTimeHelp;

  /// No description provided for @kotcSetupStrikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Strike Points (0 = off)'**
  String get kotcSetupStrikeLabel;

  /// No description provided for @kotcSetupStrikeHelp.
  ///
  /// In en, this message translates to:
  /// **'Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them.'**
  String get kotcSetupStrikeHelp;

  /// No description provided for @kotcHistoryWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get kotcHistoryWon;

  /// No description provided for @kotcHistoryNoGames.
  ///
  /// In en, this message translates to:
  /// **'No games yet.'**
  String get kotcHistoryNoGames;

  /// No description provided for @kotcHistoryNoGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Games will appear here once a team is ejected.'**
  String get kotcHistoryNoGamesSubtitle;

  /// No description provided for @setupPlayersPerSide.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get setupPlayersPerSide;

  /// No description provided for @setupAppliesToLast.
  ///
  /// In en, this message translates to:
  /// **'Applies to last'**
  String get setupAppliesToLast;

  /// No description provided for @setupScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get setupScheduleLabel;

  /// No description provided for @setupScheduleSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft Schedule'**
  String get setupScheduleSoft;

  /// No description provided for @setupScheduleForced.
  ///
  /// In en, this message translates to:
  /// **'Forced Schedule'**
  String get setupScheduleForced;

  /// No description provided for @setupAddBreak.
  ///
  /// In en, this message translates to:
  /// **'Add break'**
  String get setupAddBreak;

  /// No description provided for @setupBreakMins.
  ///
  /// In en, this message translates to:
  /// **'{mins} min break'**
  String setupBreakMins(int mins);

  /// No description provided for @setupStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts: {date}'**
  String setupStartsAt(String date);

  /// No description provided for @setupMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String setupMatchCount(int count);

  /// No description provided for @setupRoundPlayIn.
  ///
  /// In en, this message translates to:
  /// **'Play-in'**
  String get setupRoundPlayIn;

  /// No description provided for @setupRoundFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get setupRoundFinal;

  /// No description provided for @setupRoundSemiFinal.
  ///
  /// In en, this message translates to:
  /// **'Semi-final'**
  String get setupRoundSemiFinal;

  /// No description provided for @setupRoundQuarterFinal.
  ///
  /// In en, this message translates to:
  /// **'Quarter-final'**
  String get setupRoundQuarterFinal;

  /// No description provided for @setupRoundN.
  ///
  /// In en, this message translates to:
  /// **'Round {n}'**
  String setupRoundN(int n);

  /// No description provided for @setupPlayerN.
  ///
  /// In en, this message translates to:
  /// **'Player {n}'**
  String setupPlayerN(int n);

  /// No description provided for @koEditTeam.
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get koEditTeam;

  /// No description provided for @koTeamSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to set up this team?'**
  String get koTeamSetupSubtitle;

  /// No description provided for @koCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Edit Manually'**
  String get koCreateNew;

  /// No description provided for @koCreateNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a custom name and assign players manually'**
  String get koCreateNewSubtitle;

  /// No description provided for @koImportFromHub.
  ///
  /// In en, this message translates to:
  /// **'Import from Teams Hub'**
  String get koImportFromHub;

  /// No description provided for @koImportFromHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing team — name and players fill in automatically'**
  String get koImportFromHubSubtitle;

  /// No description provided for @koNoTeamsInHub.
  ///
  /// In en, this message translates to:
  /// **'No teams in Teams Hub yet.\nCreate teams via the Teams section first.'**
  String get koNoTeamsInHub;

  /// No description provided for @koPlayersSection.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get koPlayersSection;

  /// No description provided for @koSkillRating.
  ///
  /// In en, this message translates to:
  /// **'Skill: {rating}'**
  String koSkillRating(Object rating);

  /// No description provided for @koUnrated.
  ///
  /// In en, this message translates to:
  /// **'Unrated'**
  String get koUnrated;

  /// No description provided for @koTapToAssign.
  ///
  /// In en, this message translates to:
  /// **'Tap to assign'**
  String get koTapToAssign;

  /// No description provided for @koImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Teams Hub'**
  String get koImportTitle;

  /// No description provided for @koNoTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found.'**
  String get koNoTeamsFound;

  /// No description provided for @koPlayerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player} other{{count} players}}'**
  String koPlayerCount(int count);

  /// No description provided for @koAddTeamN.
  ///
  /// In en, this message translates to:
  /// **'Add Team {n}'**
  String koAddTeamN(int n);

  /// No description provided for @koAddTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to add this team?'**
  String get koAddTeamSubtitle;

  /// No description provided for @koFromTeamsHub.
  ///
  /// In en, this message translates to:
  /// **'From Teams Hub'**
  String get koFromTeamsHub;

  /// No description provided for @koFromTeamsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing team from your hub'**
  String get koFromTeamsHubSubtitle;

  /// No description provided for @koNoTeamsInHubYet.
  ///
  /// In en, this message translates to:
  /// **'No teams in hub yet.'**
  String get koNoTeamsInHubYet;

  /// No description provided for @koNoTeamsInHubYetShort.
  ///
  /// In en, this message translates to:
  /// **'No teams in hub yet'**
  String get koNoTeamsInHubYetShort;

  /// No description provided for @koCreateNewTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Team'**
  String get koCreateNewTeamTitle;

  /// No description provided for @koAddTeamBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Team'**
  String get koAddTeamBtn;

  /// No description provided for @koFromPlayersHub.
  ///
  /// In en, this message translates to:
  /// **'B — From Players Hub'**
  String get koFromPlayersHub;

  /// No description provided for @koNoPlayersInHub.
  ///
  /// In en, this message translates to:
  /// **'No players in the hub yet.'**
  String get koNoPlayersInHub;

  /// No description provided for @koNoPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found.'**
  String get koNoPlayersFound;

  /// No description provided for @koEditPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Player'**
  String get koEditPlayer;

  /// No description provided for @koPlayerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get koPlayerNameLabel;

  /// No description provided for @koSkillRatingOptional.
  ///
  /// In en, this message translates to:
  /// **'Skill rating (optional)'**
  String get koSkillRatingOptional;

  /// No description provided for @koSectionAEditPlayer.
  ///
  /// In en, this message translates to:
  /// **'A — Edit Player'**
  String get koSectionAEditPlayer;

  /// No description provided for @koSectionANewPlayer.
  ///
  /// In en, this message translates to:
  /// **'A — New Player'**
  String get koSectionANewPlayer;

  /// No description provided for @koSectionBNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'B — New Player'**
  String get koSectionBNewPlayer;

  /// No description provided for @koSectionCFromHub.
  ///
  /// In en, this message translates to:
  /// **'C — From Players Hub'**
  String get koSectionCFromHub;

  /// No description provided for @quickGameSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get quickGameSettingsTitle;

  /// No description provided for @quickGamePlayersPerSide.
  ///
  /// In en, this message translates to:
  /// **'Players per side'**
  String get quickGamePlayersPerSide;

  /// No description provided for @quickGameFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get quickGameFormatLabel;

  /// No description provided for @quickGameTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get quickGameTeamsTitle;

  /// No description provided for @quickGameTapToConfigure.
  ///
  /// In en, this message translates to:
  /// **'Tap to configure team'**
  String get quickGameTapToConfigure;

  /// No description provided for @adminHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Manage players, teams, and groups to efficiently set up your games and tournaments.'**
  String get adminHelpBody;

  /// No description provided for @adminInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'About Administration'**
  String get adminInfoTooltip;

  /// No description provided for @adminManagePlayers.
  ///
  /// In en, this message translates to:
  /// **'Manage player profiles'**
  String get adminManagePlayers;

  /// No description provided for @adminManageTeams.
  ///
  /// In en, this message translates to:
  /// **'Manage teams and rosters'**
  String get adminManageTeams;

  /// No description provided for @adminManageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage groups and affiliations'**
  String get adminManageGroups;

  /// No description provided for @playerHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your global player pool'**
  String get playerHubSubtitle;

  /// No description provided for @teamHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your global team pool'**
  String get teamHubSubtitle;

  /// No description provided for @groupHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your global group pool'**
  String get groupHubSubtitle;

  /// No description provided for @modeQuickGamesName.
  ///
  /// In en, this message translates to:
  /// **'Quick Games'**
  String get modeQuickGamesName;

  /// No description provided for @modeSocialScramblesName.
  ///
  /// In en, this message translates to:
  /// **'Social Scrambles'**
  String get modeSocialScramblesName;

  /// No description provided for @modeKotcName.
  ///
  /// In en, this message translates to:
  /// **'King of the Court'**
  String get modeKotcName;

  /// No description provided for @modeDoghouseName.
  ///
  /// In en, this message translates to:
  /// **'Doghouse'**
  String get modeDoghouseName;

  /// No description provided for @modeLeagueName.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get modeLeagueName;

  /// No description provided for @modeLeagueFullName.
  ///
  /// In en, this message translates to:
  /// **'League / Round Robin'**
  String get modeLeagueFullName;

  /// No description provided for @modeSingleElimName.
  ///
  /// In en, this message translates to:
  /// **'Single Elimination'**
  String get modeSingleElimName;

  /// No description provided for @modeDoubleElimName.
  ///
  /// In en, this message translates to:
  /// **'Double Elimination'**
  String get modeDoubleElimName;

  /// No description provided for @modeGroupSeName.
  ///
  /// In en, this message translates to:
  /// **'Group + SE'**
  String get modeGroupSeName;

  /// No description provided for @modeGroupSeFullName.
  ///
  /// In en, this message translates to:
  /// **'Group + Single Elimination'**
  String get modeGroupSeFullName;

  /// No description provided for @modeGroupDeName.
  ///
  /// In en, this message translates to:
  /// **'Group + DE'**
  String get modeGroupDeName;

  /// No description provided for @modeGroupDeFullName.
  ///
  /// In en, this message translates to:
  /// **'Group + Double Elimination'**
  String get modeGroupDeFullName;

  /// No description provided for @modeSwissName.
  ///
  /// In en, this message translates to:
  /// **'Swiss System'**
  String get modeSwissName;

  /// No description provided for @modeComingSoonHelp.
  ///
  /// In en, this message translates to:
  /// **'Detailed description coming soon.'**
  String get modeComingSoonHelp;

  /// No description provided for @modeQuickGamesHelp.
  ///
  /// In en, this message translates to:
  /// **'Quick Games lets you start a scored match on the spot — no tournament setup required. Pick two teams, set the format, and start tracking the score immediately.\n\nIdeal for casual play, training sessions, or any time you just want to run a game without a bracket.'**
  String get modeQuickGamesHelp;

  /// No description provided for @modeSocialScramblesHelp.
  ///
  /// In en, this message translates to:
  /// **'Social Scrambles is a timed, rotating mixer where teams are randomly reshuffled every round. No one stays partnered for long — the whole point is to play with and against as many different people as possible across the session.\n\nPerfect for beach sessions, open days, or any group that wants competitive play without the pressure of a fixed bracket.\n\nFair by design. TournaQ schedules every player into the maximum number of rounds while keeping wait times as short as possible. When not everyone can fit on court at once, sitting-out rotations are balanced so no player waits longer than others.\n\nHow a round works:\n• Teams are randomly drawn at the start of each round\n• All courts play simultaneously for the set match duration\n• A short break follows before the next round\n• Cumulative wins are tracked across all rounds\n\nAdd your players, set a session timer, and go.'**
  String get modeSocialScramblesHelp;

  /// No description provided for @modeKotcHelp.
  ///
  /// In en, this message translates to:
  /// **'King of the Court is a fast, individual competition where every player fights for the crown. Players rotate on and off court in groups, scoring points for each rally won — but the ranking is entirely personal. The player who accumulates the most game wins (then points) across the session takes the title.\n\nShort format, high energy — perfect as a session warm-up or a standalone competition.\n\nFair by design. TournaQ\'s Automated assignment ensures everyone plays with and against different people, keeping wait times low and avoiding repeat pairings. Because matchups stay balanced throughout the session, the final standings are a genuine reflection of individual performance — not just who got the easiest draw.\n\nHow a game works:\n• Win a rally → each player on that side scores a point\n• Reach your Strike Points target → current group wins the game, everyone rotates back to the queue\n• Coach manually ejects → stint ends, points recorded as-is\n• Next players step up immediately\n\nBefore you start, agree on:\n• Who serves each rally\n• Whether to use Strike Points and what the target should be\n\nAdd your players, set a session timer, and go.'**
  String get modeKotcHelp;

  /// No description provided for @modeDoghouseHelp.
  ///
  /// In en, this message translates to:
  /// **'Doghouse is a fast, competitive tournament where the action never stops. One team battles from the doghouse — score enough points to escape and make way for the next challengers. Hit your loss limit first and you\'re out.\n\nShort format, high intensity — great as a session warm-up or a standalone competition.\n\nFair by design. TournaQ\'s Automated assignment ensures everyone plays with and against different people, keeping wait times low and avoiding repeat pairings. Because matchups stay balanced throughout the session, the final standings are a genuine reflection of how each player performed — not just who got the easier draw.\n\nHow a game works:\n• Win a rally → score a point\n• Lose a rally → game lost, point score resets\n• Reach your Escape Points target → escaped, back to the queue\n• Hit the Loss Limit → ejected, next team steps in\n\nBefore you start, agree on:\n• Which team serves each rally\n• Escape Points and Loss Limit settings\n\nAdd your players, set a session timer, and go.'**
  String get modeDoghouseHelp;

  /// No description provided for @btnEject.
  ///
  /// In en, this message translates to:
  /// **'Eject'**
  String get btnEject;

  /// No description provided for @modeScrambleKingName.
  ///
  /// In en, this message translates to:
  /// **'Scramble King'**
  String get modeScrambleKingName;

  /// No description provided for @modeScrambleKingDesc.
  ///
  /// In en, this message translates to:
  /// **'Scramble mixing meets King of the Court'**
  String get modeScrambleKingDesc;

  /// No description provided for @modeScrambleKingHelp.
  ///
  /// In en, this message translates to:
  /// **'Scramble King mixes the whole player pool into fresh courts and teams every round, then plays King of the Court within each court for the round\'s duration. Two players form a team and stay together for the whole round, cycling on and off the court as they win or lose — only the team currently on court can score.\n\nWhen a round\'s timer runs out, everyone is mixed again into new courts and new partners for the next round.\n\nIf a court ends up with an odd number of players, the leftover player still gets their own team and queues just like everyone else — only their partner is decided differently: a fixed random partner for the whole round (Placeholder), or a fresh fairness-balanced partner each time they\'re on court (Jumper).\n\nAdd your players, set the number of rounds and courts, and go.'**
  String get modeScrambleKingHelp;

  /// No description provided for @scrambleKingStatsRounds.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} rounds'**
  String scrambleKingStatsRounds(int completed, int total);

  /// No description provided for @scrambleKingSetupPlayersHelp.
  ///
  /// In en, this message translates to:
  /// **'How many players you plan to have. Used to size the \"fill random\" quick-add and to check your court/round settings make sense.'**
  String get scrambleKingSetupPlayersHelp;

  /// No description provided for @scrambleKingSetupRoundsHelp.
  ///
  /// In en, this message translates to:
  /// **'How many times the whole player pool gets mixed into new courts and teams.'**
  String get scrambleKingSetupRoundsHelp;

  /// No description provided for @scrambleKingSetupDurationHelp.
  ///
  /// In en, this message translates to:
  /// **'How long each round runs before everyone is reshuffled into new courts and teams.'**
  String get scrambleKingSetupDurationHelp;

  /// No description provided for @scrambleKingSetupCourtsHelp.
  ///
  /// In en, this message translates to:
  /// **'How many courts run at once, each with its own independent King of the Court queue for the round.'**
  String get scrambleKingSetupCourtsHelp;

  /// No description provided for @scrambleKingOddPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odd player handling'**
  String get scrambleKingOddPlayerLabel;

  /// No description provided for @scrambleKingOddPlayerHelp.
  ///
  /// In en, this message translates to:
  /// **'When a court can\'t be split evenly into teams of two, one player gets their own team and queues like everyone else — only their partner is decided by this setting. Placeholder picks a random free player the first time they take the court, then keeps that same partner for the rest of the round. Jumper re-picks a partner every time, using a fairness calculation so playing time stays balanced across the round. Either way, the odd player\'s own team earns the points, just like every other team.'**
  String get scrambleKingOddPlayerHelp;

  /// No description provided for @scrambleKingOddPlayerPlaceholderLabel.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get scrambleKingOddPlayerPlaceholderLabel;

  /// No description provided for @scrambleKingOddPlayerJumperLabel.
  ///
  /// In en, this message translates to:
  /// **'Jumper'**
  String get scrambleKingOddPlayerJumperLabel;

  /// No description provided for @scrambleKingJumperPartner.
  ///
  /// In en, this message translates to:
  /// **'Jumper: {name}'**
  String scrambleKingJumperPartner(String name);

  /// No description provided for @scrambleKingNextAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested fairly from players not about to play.'**
  String get scrambleKingNextAdminNote;

  /// No description provided for @scrambleKingJumperAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Jumper · awaiting ejection'**
  String get scrambleKingJumperAwaiting;

  /// No description provided for @scrambleKingRoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {n}'**
  String scrambleKingRoundLabel(int n);

  /// No description provided for @scrambleKingRoundsProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} rounds complete'**
  String scrambleKingRoundsProgress(int completed, int total);

  /// No description provided for @scrambleKingRoundsPill.
  ///
  /// In en, this message translates to:
  /// **'{n} rounds'**
  String scrambleKingRoundsPill(int n);

  /// No description provided for @scrambleKingCourtsPill.
  ///
  /// In en, this message translates to:
  /// **'{n} courts'**
  String scrambleKingCourtsPill(int n);

  /// No description provided for @scrambleKingPlayersPill.
  ///
  /// In en, this message translates to:
  /// **'{n} players'**
  String scrambleKingPlayersPill(int n);

  /// No description provided for @scrambleKingRoundsPillLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get scrambleKingRoundsPillLabel;

  /// No description provided for @scrambleKingCourtsPillLabel.
  ///
  /// In en, this message translates to:
  /// **'Courts'**
  String get scrambleKingCourtsPillLabel;

  /// No description provided for @scrambleKingInvalidCourtCount.
  ///
  /// In en, this message translates to:
  /// **'That many courts doesn\'t work for the current player count.'**
  String get scrambleKingInvalidCourtCount;

  /// No description provided for @scrambleKingOverallRanking.
  ///
  /// In en, this message translates to:
  /// **'Overall Ranking'**
  String get scrambleKingOverallRanking;

  /// No description provided for @scrambleKingNoResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No results yet.\nRankings will appear here as rounds are played.'**
  String get scrambleKingNoResultsYet;

  /// No description provided for @scrambleKingRoundsPlayed.
  ///
  /// In en, this message translates to:
  /// **'{n} rounds played'**
  String scrambleKingRoundsPlayed(int n);

  /// No description provided for @scrambleKingCourtLabel.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get scrambleKingCourtLabel;

  /// No description provided for @scrambleKingReadyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to start'**
  String get scrambleKingReadyToStart;

  /// No description provided for @scrambleKingStartCourt.
  ///
  /// In en, this message translates to:
  /// **'Start Court'**
  String get scrambleKingStartCourt;

  /// No description provided for @scrambleKingRoundEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Round complete — head back to see the results.'**
  String get scrambleKingRoundEndedBody;

  /// No description provided for @scrambleKingCompleteRound.
  ///
  /// In en, this message translates to:
  /// **'Complete round'**
  String get scrambleKingCompleteRound;

  /// No description provided for @scrambleKingCourtPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Court {n}'**
  String scrambleKingCourtPageTitle(int n);

  /// No description provided for @scrambleKingEjectCourt.
  ///
  /// In en, this message translates to:
  /// **'Eject\nCourt'**
  String get scrambleKingEjectCourt;

  /// No description provided for @scrambleKingEjectChallenger.
  ///
  /// In en, this message translates to:
  /// **'Eject\nChallenger'**
  String get scrambleKingEjectChallenger;

  /// No description provided for @scrambleKingPickStartingTeam.
  ///
  /// In en, this message translates to:
  /// **'Pick a team below to start on court.'**
  String get scrambleKingPickStartingTeam;

  /// No description provided for @scrambleKingSendToCourt.
  ///
  /// In en, this message translates to:
  /// **'Send to court'**
  String get scrambleKingSendToCourt;

  /// No description provided for @scrambleKingQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get scrambleKingQueueLabel;

  /// No description provided for @scrambleKingRefereeBanner.
  ///
  /// In en, this message translates to:
  /// **'{name} is refereeing this court'**
  String scrambleKingRefereeBanner(String name);

  /// No description provided for @scrambleKingPickFloaterPartner.
  ///
  /// In en, this message translates to:
  /// **'Pick a partner for the floater'**
  String get scrambleKingPickFloaterPartner;

  /// No description provided for @scrambleKingScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get scrambleKingScorecard;

  /// No description provided for @scrambleKingExportCourt.
  ///
  /// In en, this message translates to:
  /// **'Export court'**
  String get scrambleKingExportCourt;

  /// No description provided for @scrambleKingScanCourtHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a court QR code.'**
  String get scrambleKingScanCourtHint;

  /// No description provided for @scrambleKingScanNotCourt.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a court.'**
  String get scrambleKingScanNotCourt;

  /// No description provided for @scrambleKingImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported court from “{name}”.'**
  String scrambleKingImportSuccess(String name);

  /// No description provided for @scrambleKingImportedCourts.
  ///
  /// In en, this message translates to:
  /// **'Imported Courts'**
  String get scrambleKingImportedCourts;

  /// No description provided for @scrambleKingImportedUpcomingHint.
  ///
  /// In en, this message translates to:
  /// **'For other courts, see the host device.'**
  String get scrambleKingImportedUpcomingHint;

  /// No description provided for @scrambleKingSetResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Court Result'**
  String get scrambleKingSetResultTitle;

  /// No description provided for @scrambleKingSetResultDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter each team\'s points to complete this court without playing it.'**
  String get scrambleKingSetResultDescription;

  /// No description provided for @scrambleKingManuallyEdited.
  ///
  /// In en, this message translates to:
  /// **'Manually edited'**
  String get scrambleKingManuallyEdited;

  /// No description provided for @scrambleKingEditTeamResult.
  ///
  /// In en, this message translates to:
  /// **'Edit result'**
  String get scrambleKingEditTeamResult;

  /// No description provided for @scrambleKingGamesWonLabel.
  ///
  /// In en, this message translates to:
  /// **'Games Won'**
  String get scrambleKingGamesWonLabel;

  /// No description provided for @scrambleKingPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get scrambleKingPointsLabel;

  /// No description provided for @scrambleKingTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get scrambleKingTeamsLabel;

  /// No description provided for @scrambleKingTeamsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scrambleKingTeamsFilterAll;

  /// No description provided for @scrambleKingTeamsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams for this filter yet.'**
  String get scrambleKingTeamsEmpty;

  /// No description provided for @scrambleKingEditFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get scrambleKingEditFormatTitle;

  /// No description provided for @scrambleKingStatRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get scrambleKingStatRounds;

  /// No description provided for @scrambleKingTeamsSummary.
  ///
  /// In en, this message translates to:
  /// **'{teams} teams · {pts} pts total'**
  String scrambleKingTeamsSummary(int teams, int pts);

  /// No description provided for @scrambleKingUndoFinishCourt.
  ///
  /// In en, this message translates to:
  /// **'Undo Finish'**
  String get scrambleKingUndoFinishCourt;

  /// No description provided for @scrambleKingCourtCompleteBanner.
  ///
  /// In en, this message translates to:
  /// **'This court\'s round is complete'**
  String get scrambleKingCourtCompleteBanner;

  /// No description provided for @scrambleKingCourtCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap here to view or edit results'**
  String get scrambleKingCourtCompleteHint;

  /// No description provided for @scrambleKingEditResults.
  ///
  /// In en, this message translates to:
  /// **'View / edit results'**
  String get scrambleKingEditResults;

  /// No description provided for @scrambleKingRoundTimer.
  ///
  /// In en, this message translates to:
  /// **'Round Timer'**
  String get scrambleKingRoundTimer;

  /// No description provided for @scrambleKingFinishCourt.
  ///
  /// In en, this message translates to:
  /// **'Finish court'**
  String get scrambleKingFinishCourt;

  /// No description provided for @scrambleKingFinishCourtTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish this court?'**
  String get scrambleKingFinishCourtTitle;

  /// No description provided for @scrambleKingFinishCourtBody.
  ///
  /// In en, this message translates to:
  /// **'Record this court\'s results now and end its round.'**
  String get scrambleKingFinishCourtBody;

  /// No description provided for @scrambleKingUndoDiscardPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard recorded points?'**
  String get scrambleKingUndoDiscardPointsTitle;

  /// No description provided for @scrambleKingUndoDiscardPointsBody.
  ///
  /// In en, this message translates to:
  /// **'The team currently on court has {points} point(s) recorded. Undoing will discard them.'**
  String scrambleKingUndoDiscardPointsBody(int points);

  /// No description provided for @scrambleKingUndoDiscardPointsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard and undo'**
  String get scrambleKingUndoDiscardPointsConfirm;

  /// No description provided for @scrambleKingBackToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Back to schedule'**
  String get scrambleKingBackToSchedule;

  /// No description provided for @scrambleExportScorecard.
  ///
  /// In en, this message translates to:
  /// **'Export scorecard'**
  String get scrambleExportScorecard;

  /// No description provided for @scrambleExportResult.
  ///
  /// In en, this message translates to:
  /// **'Export result'**
  String get scrambleExportResult;

  /// No description provided for @scrambleExportGame.
  ///
  /// In en, this message translates to:
  /// **'Export game'**
  String get scrambleExportGame;

  /// No description provided for @scrambleImportResult.
  ///
  /// In en, this message translates to:
  /// **'Import result'**
  String get scrambleImportResult;

  /// No description provided for @scrambleQrScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this code on the other device.'**
  String get scrambleQrScanHint;

  /// No description provided for @scrambleQrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This scorecard is too large to fit in a QR code.'**
  String get scrambleQrTooLarge;

  /// No description provided for @scrambleScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scrambleScanTitle;

  /// No description provided for @scrambleScanScorecardHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a scorecard QR code.'**
  String get scrambleScanScorecardHint;

  /// No description provided for @scrambleScanResultHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a result QR code.'**
  String get scrambleScanResultHint;

  /// No description provided for @scrambleScanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan QR codes. Enable it in Settings.'**
  String get scrambleScanCameraDenied;

  /// No description provided for @scrambleOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get scrambleOpenSettings;

  /// No description provided for @scrambleScanToImport.
  ///
  /// In en, this message translates to:
  /// **'Scan to import'**
  String get scrambleScanToImport;

  /// No description provided for @scrambleScanNotScorecard.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a scorecard.'**
  String get scrambleScanNotScorecard;

  /// No description provided for @scrambleScanNotResult.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a result.'**
  String get scrambleScanNotResult;

  /// No description provided for @koBracketScanMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a match QR code.'**
  String get koBracketScanMatchHint;

  /// No description provided for @koBracketScanNotMatch.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a match.'**
  String get koBracketScanNotMatch;

  /// No description provided for @koBracketImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported match from “{name}”.'**
  String koBracketImportSuccess(String name);

  /// No description provided for @scrambleResultImported.
  ///
  /// In en, this message translates to:
  /// **'Result imported.'**
  String get scrambleResultImported;

  /// No description provided for @scrambleResultMismatch.
  ///
  /// In en, this message translates to:
  /// **'This result is for a different tournament.'**
  String get scrambleResultMismatch;

  /// No description provided for @scrambleResultAlreadyRecorded.
  ///
  /// In en, this message translates to:
  /// **'A result has already been recorded for this game.'**
  String get scrambleResultAlreadyRecorded;

  /// No description provided for @scrambleImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported scorecard from “{name}”.'**
  String scrambleImportSuccess(String name);

  /// No description provided for @scrambleImportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported Scorecards ({count})'**
  String scrambleImportedTitle(int count);

  /// No description provided for @scrambleImportedFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by tournament'**
  String get scrambleImportedFilterHint;

  /// No description provided for @scrambleImportedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No imported scorecards match.'**
  String get scrambleImportedEmpty;

  /// No description provided for @scrambleImportedDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all imported?'**
  String get scrambleImportedDeleteAllTitle;

  /// No description provided for @scrambleImportedDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all {count} imported scorecard(s).'**
  String scrambleImportedDeleteAllBody(int count);

  /// No description provided for @scrambleImportedCourt.
  ///
  /// In en, this message translates to:
  /// **'Court {number}'**
  String scrambleImportedCourt(int number);

  /// No description provided for @scrambleStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scrambleStatusScheduled;

  /// No description provided for @scrambleImportedUpcomingHint.
  ///
  /// In en, this message translates to:
  /// **'For other games, see the host device.'**
  String get scrambleImportedUpcomingHint;

  /// No description provided for @scrambleTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get scrambleTabHistory;

  /// No description provided for @scrambleTabImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get scrambleTabImported;

  /// No description provided for @scrambleBackToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Hub'**
  String get scrambleBackToHub;

  /// No description provided for @scrambleImportedScorecard.
  ///
  /// In en, this message translates to:
  /// **'Imported Scorecard'**
  String get scrambleImportedScorecard;

  /// No description provided for @scrambleAdjustHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Adjust final score to enter the final result.'**
  String get scrambleAdjustHint;

  /// No description provided for @overviewSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament Settings'**
  String get overviewSettingsTitle;

  /// No description provided for @overviewSettingsLockedRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds 1–{count} are already underway and won\'t change.'**
  String overviewSettingsLockedRounds(int count);

  /// No description provided for @overviewSettingsRoundsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Rounds {from}–{to} will be removed.'**
  String overviewSettingsRoundsRemoved(int from, int to);

  /// No description provided for @overviewSettingsRoundsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} more round(s) will be added.'**
  String overviewSettingsRoundsAdded(int count);

  /// No description provided for @overviewSettingsRemix.
  ///
  /// In en, this message translates to:
  /// **'The remaining schedule will be re-mixed as fairly as possible.'**
  String get overviewSettingsRemix;

  /// No description provided for @overviewSettingsModeLocked.
  ///
  /// In en, this message translates to:
  /// **'Mode can\'t be changed once a game has started.'**
  String get overviewSettingsModeLocked;

  /// No description provided for @overviewSettingsCourtsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Only {count} court(s) can be filled with the current players — reduce courts or add players.'**
  String overviewSettingsCourtsBlocked(int count);

  /// No description provided for @overviewSettingsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply these changes?'**
  String get overviewSettingsConfirmTitle;

  /// No description provided for @overviewSettingsConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get overviewSettingsConfirmBtn;

  /// No description provided for @overviewTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get overviewTeamsLabel;

  /// No description provided for @overviewTeamsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get overviewTeamsFilterAll;

  /// No description provided for @overviewTeamsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams for this filter yet.'**
  String get overviewTeamsEmpty;

  /// No description provided for @overviewScoreSaved.
  ///
  /// In en, this message translates to:
  /// **'Score saved.'**
  String get overviewScoreSaved;

  /// No description provided for @overviewSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get overviewSettingsSaved;

  /// No description provided for @rosterMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get rosterMenuTooltip;

  /// No description provided for @rosterDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get rosterDownloadTemplate;

  /// No description provided for @rosterImport.
  ///
  /// In en, this message translates to:
  /// **'Import players…'**
  String get rosterImport;

  /// No description provided for @rosterExport.
  ///
  /// In en, this message translates to:
  /// **'Export players…'**
  String get rosterExport;

  /// No description provided for @rosterMenuInfo.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get rosterMenuInfo;

  /// No description provided for @rosterNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'There are no players to export yet.'**
  String get rosterNothingToExport;

  /// No description provided for @rosterImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import roster'**
  String get rosterImportTitle;

  /// No description provided for @rosterImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read this file. Please choose a TournaQ Excel template or export (.xlsx).'**
  String get rosterImportInvalidFile;

  /// No description provided for @rosterImportNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes were found in this file.'**
  String get rosterImportNoChanges;

  /// No description provided for @rosterImportSummary.
  ///
  /// In en, this message translates to:
  /// **'{created} added · {updated} updated · {teamsCreated} new teams · {groupsCreated} new groups'**
  String rosterImportSummary(
    int created,
    int updated,
    int teamsCreated,
    int groupsCreated,
  );

  /// No description provided for @rosterImportDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player will be permanently deleted:} other{{count} players will be permanently deleted:}}'**
  String rosterImportDeleteWarning(int count);

  /// No description provided for @rosterMirrorDisabledNote.
  ///
  /// In en, this message translates to:
  /// **'Deletion is disabled for this file (not a full export from this device), so no one will be removed.'**
  String get rosterMirrorDisabledNote;

  /// No description provided for @rosterImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get rosterImportConfirm;

  /// No description provided for @rosterImportConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete & import'**
  String get rosterImportConfirmDelete;

  /// No description provided for @rosterImportDone.
  ///
  /// In en, this message translates to:
  /// **'{created} added, {updated} updated, {deleted} removed.'**
  String rosterImportDone(int created, int updated, int deleted);

  /// No description provided for @skSugTooFewRounds.
  ///
  /// In en, this message translates to:
  /// **'At least 1 round is needed.'**
  String get skSugTooFewRounds;

  /// No description provided for @skSugZeroDuration.
  ///
  /// In en, this message translates to:
  /// **'Round duration must be greater than zero.'**
  String get skSugZeroDuration;

  /// No description provided for @skSugMinPlayers.
  ///
  /// In en, this message translates to:
  /// **'At least {min} players are needed for one court.'**
  String skSugMinPlayers(int min);

  /// No description provided for @skSugInvalidCombo.
  ///
  /// In en, this message translates to:
  /// **'This player/court combination can\'t form a valid court. Add more players or reduce courts.'**
  String get skSugInvalidCombo;

  /// No description provided for @skSugCourtsUnfilled.
  ///
  /// In en, this message translates to:
  /// **'Only {filled} of {courts} courts can be filled with {players} players. Reduce courts or add players.'**
  String skSugCourtsUnfilled(int filled, int courts, int players);

  /// No description provided for @skSugFloaterSameTeam.
  ///
  /// In en, this message translates to:
  /// **'With this player count, the floater always partners with the same team on the rounds they float. Add players for more variety.'**
  String get skSugFloaterSameTeam;

  /// No description provided for @ssSugTooFewRounds.
  ///
  /// In en, this message translates to:
  /// **'At least 1 round is needed to build a schedule.'**
  String get ssSugTooFewRounds;

  /// No description provided for @ssSugZeroDuration.
  ///
  /// In en, this message translates to:
  /// **'Match and break duration must be greater than zero.'**
  String get ssSugZeroDuration;

  /// No description provided for @ssSugMinPlayers.
  ///
  /// In en, this message translates to:
  /// **'At least {n} players are needed for one {perTeam}v{perTeam} court. Add more players or switch to a smaller format.'**
  String ssSugMinPlayers(int n, int perTeam);

  /// No description provided for @ssSugLargeGroup.
  ///
  /// In en, this message translates to:
  /// **'With {n} players the mixing becomes statistical — everyone-against-everyone is no longer guaranteed, but equal play time still is. This works well for large events.'**
  String ssSugLargeGroup(int n);

  /// No description provided for @ssSugRepeatPartners.
  ///
  /// In en, this message translates to:
  /// **'With {rounds} rounds, some partnerships will repeat. Up to {max} rounds keeps every partnership unique.'**
  String ssSugRepeatPartners(int rounds, int max);

  /// No description provided for @ssSugCoverageNote.
  ///
  /// In en, this message translates to:
  /// **' Full coverage (everyone partners with everyone) would take {target} rounds, but then some players would repeat partners.'**
  String ssSugCoverageNote(int target);

  /// No description provided for @ssSugCapAction.
  ///
  /// In en, this message translates to:
  /// **'Cap at {max} rounds'**
  String ssSugCapAction(int max);

  /// No description provided for @ssSugAllUniqueNoCoverage.
  ///
  /// In en, this message translates to:
  /// **'This setup keeps every partnership unique for all {rounds} rounds. Full coverage (everyone partners with everyone) isn\'t possible without repeats for this player/court combination — it would need {target} rounds.'**
  String ssSugAllUniqueNoCoverage(int rounds, int target);

  /// No description provided for @ssSugCourtsUnfilled.
  ///
  /// In en, this message translates to:
  /// **'Only {active} of {courts} courts can be filled with {players} players in {perTeam}v{perTeam}. Reduce courts to {active} or add more players.'**
  String ssSugCourtsUnfilled(int active, int courts, int players, int perTeam);

  /// No description provided for @ssSugNoReferee.
  ///
  /// In en, this message translates to:
  /// **'With {players} players filling {active, plural, =1{1 court} other{{active} courts}} in {perTeam}v{perTeam}, only {sitting, plural, =1{1 player} other{{sitting} players}} sit out each round — {without, plural, =1{1 court} other{{without} courts}} won\'t have a dedicated referee and will need scores entered manually.'**
  String ssSugNoReferee(
    int players,
    int active,
    int perTeam,
    int sitting,
    int without,
  );

  /// No description provided for @ssSugBreakTooLong.
  ///
  /// In en, this message translates to:
  /// **'Break duration ({breakDur}) is longer than match duration ({matchDur}). Consider reducing breaks to allow more rounds.'**
  String ssSugBreakTooLong(String breakDur, String matchDur);

  /// No description provided for @bracketGenerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Bracket generation'**
  String get bracketGenerationTitle;

  /// No description provided for @bracketSeeding.
  ///
  /// In en, this message translates to:
  /// **'Seeding'**
  String get bracketSeeding;

  /// No description provided for @bracketSeedingRandomDesc.
  ///
  /// In en, this message translates to:
  /// **'Shuffle teams into the bracket'**
  String get bracketSeedingRandomDesc;

  /// No description provided for @bracketSeedingSeededDesc.
  ///
  /// In en, this message translates to:
  /// **'Order by team skill rating'**
  String get bracketSeedingSeededDesc;

  /// No description provided for @bracketOddTeamsSection.
  ///
  /// In en, this message translates to:
  /// **'Odd teams'**
  String get bracketOddTeamsSection;

  /// No description provided for @bracketOddByesDesc.
  ///
  /// In en, this message translates to:
  /// **'Top teams skip the first round'**
  String get bracketOddByesDesc;

  /// No description provided for @bracketOddPlayInDesc.
  ///
  /// In en, this message translates to:
  /// **'Extra teams fight into round 1'**
  String get bracketOddPlayInDesc;

  /// No description provided for @bracketOddPlayInPlusDesc.
  ///
  /// In en, this message translates to:
  /// **'Play-in with a repechage back-in'**
  String get bracketOddPlayInPlusDesc;

  /// No description provided for @bracketPlayInPlus.
  ///
  /// In en, this message translates to:
  /// **'Play-in+'**
  String get bracketPlayInPlus;

  /// No description provided for @bracketRegenNote.
  ///
  /// In en, this message translates to:
  /// **'Regenerates the bracket. Available only before the first match starts.'**
  String get bracketRegenNote;

  /// No description provided for @bracketSetSchedule.
  ///
  /// In en, this message translates to:
  /// **'Set schedule'**
  String get bracketSetSchedule;

  /// No description provided for @bracketEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends {time}'**
  String bracketEndsAt(String time);

  /// No description provided for @bracketRoundBreak.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m break'**
  String bracketRoundBreak(int minutes);

  /// No description provided for @bracketTargetScore.
  ///
  /// In en, this message translates to:
  /// **'Target score'**
  String get bracketTargetScore;

  /// No description provided for @bracketSideChange.
  ///
  /// In en, this message translates to:
  /// **'Side change'**
  String get bracketSideChange;

  /// No description provided for @bracketSideChangeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get bracketSideChangeOff;

  /// No description provided for @bracketSideChangeEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {points} points'**
  String bracketSideChangeEvery(int points);

  /// No description provided for @bracketNotifyTarget.
  ///
  /// In en, this message translates to:
  /// **'Notify at target score'**
  String get bracketNotifyTarget;

  /// No description provided for @bracketNotifyTargetDesc.
  ///
  /// In en, this message translates to:
  /// **'Prompt to finish when a side reaches the target'**
  String get bracketNotifyTargetDesc;

  /// No description provided for @bracketManualSet.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String bracketManualSet(int number);

  /// No description provided for @bracketManualScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get bracketManualScore;

  /// No description provided for @bracketTbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get bracketTbd;

  /// No description provided for @bracketRefs.
  ///
  /// In en, this message translates to:
  /// **'{name} refs'**
  String bracketRefs(String name);

  /// No description provided for @bracketRoundFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get bracketRoundFinal;

  /// No description provided for @bracketRoundSemi.
  ///
  /// In en, this message translates to:
  /// **'Semi-final'**
  String get bracketRoundSemi;

  /// No description provided for @bracketRoundQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter-final'**
  String get bracketRoundQuarter;

  /// No description provided for @bracketRoundNumbered.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String bracketRoundNumbered(int round);

  /// No description provided for @bracketTagBye.
  ///
  /// In en, this message translates to:
  /// **'BYE'**
  String get bracketTagBye;

  /// No description provided for @bracketTagWalkover.
  ///
  /// In en, this message translates to:
  /// **'W/O'**
  String get bracketTagWalkover;

  /// No description provided for @bracketTagPlayIn.
  ///
  /// In en, this message translates to:
  /// **'PLAY-IN'**
  String get bracketTagPlayIn;

  /// No description provided for @bracketTagRepechage.
  ///
  /// In en, this message translates to:
  /// **'REPECHAGE'**
  String get bracketTagRepechage;

  /// No description provided for @bracketAddBreak.
  ///
  /// In en, this message translates to:
  /// **'Add break'**
  String get bracketAddBreak;

  /// No description provided for @bracketBreakAfter.
  ///
  /// In en, this message translates to:
  /// **'Break after {round}'**
  String bracketBreakAfter(String round);

  /// No description provided for @bracketMatchNumber.
  ///
  /// In en, this message translates to:
  /// **'Match {number}'**
  String bracketMatchNumber(int number);

  /// No description provided for @bracketFinishBeforeExport.
  ///
  /// In en, this message translates to:
  /// **'Finish the match before exporting the result.'**
  String get bracketFinishBeforeExport;
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
      <String>['de', 'en', 'es'].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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
  /// **'Quick Start Game'**
  String get navQuickStart;

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

  /// No description provided for @pageGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
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
  /// **'Tournaments'**
  String get pageTournaments;

  /// No description provided for @pageClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
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
  /// **'Create Club'**
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
  /// **'Quick Start Game'**
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
  /// **'Clubs ({count})'**
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
  /// **'Search clubs...'**
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
  /// **'Club'**
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

  /// No description provided for @landingTournamentManagement.
  ///
  /// In en, this message translates to:
  /// **'Tournament Management'**
  String get landingTournamentManagement;

  /// No description provided for @landingTournamentManagementSub.
  ///
  /// In en, this message translates to:
  /// **'Create and manage tournaments with multiple formats.'**
  String get landingTournamentManagementSub;

  /// No description provided for @landingTournamentManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize structured competitions, formats, and match results in one place.'**
  String get landingTournamentManagementDesc;

  /// No description provided for @landingAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Player, Team & Club Administration'**
  String get landingAdminTitle;

  /// No description provided for @landingAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Organize players, teams and clubs.'**
  String get landingAdminSub;

  /// No description provided for @landingAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize Players, Teams and Clubs.'**
  String get landingAdminDesc;

  /// No description provided for @landingAdminPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get landingAdminPageTitle;

  /// No description provided for @landingCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Services'**
  String get landingCloudTitle;

  /// No description provided for @landingCloudSub.
  ///
  /// In en, this message translates to:
  /// **'Cloud synchronization and connected features.'**
  String get landingCloudSub;

  /// No description provided for @landingCloudDesc.
  ///
  /// In en, this message translates to:
  /// **'Future connected features for syncing, sharing, and accessing TournaQ across devices.'**
  String get landingCloudDesc;

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
  /// **'Future partners, clubs and organizations may be featured here.'**
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
  /// **'Coming soon'**
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
  /// **'Remove from Club'**
  String get dialogRemoveFromClub;

  /// No description provided for @dialogRemoveFromClubBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this team from the club?'**
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
  /// **'Assign to Club'**
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
  /// **'Add to Club'**
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
  /// **'No clubs yet.'**
  String get noClubsYet;

  /// No description provided for @noClubsFiltered.
  ///
  /// In en, this message translates to:
  /// **'No clubs match the current filters.'**
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
  /// **'Not in any clubs yet.'**
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
  /// **'Club Details'**
  String get pageClubDetails;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player not found.'**
  String get playerNotFound;

  /// No description provided for @clubNotFound.
  ///
  /// In en, this message translates to:
  /// **'Club not found.'**
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
  /// **'Remove this player from the club?'**
  String get dialogRemovePlayerFromClubBody;

  /// No description provided for @dialogRemoveTournamentFromClub.
  ///
  /// In en, this message translates to:
  /// **'Remove Tournament'**
  String get dialogRemoveTournamentFromClub;

  /// No description provided for @dialogRemoveTournamentFromClubBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this tournament from the club?'**
  String get dialogRemoveTournamentFromClubBody;

  /// No description provided for @notAssignedToTeams.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any teams.'**
  String get notAssignedToTeams;

  /// No description provided for @notAssignedToClubs.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any clubs.'**
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
  /// **'Club name'**
  String get hintClubName;

  /// No description provided for @labelAssignToTeams.
  ///
  /// In en, this message translates to:
  /// **'Assign to Teams'**
  String get labelAssignToTeams;

  /// No description provided for @labelAssignToClubs.
  ///
  /// In en, this message translates to:
  /// **'Assign to Clubs'**
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
  /// **'Club'**
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
  /// **'All clubs'**
  String get filterAllClubs;

  /// No description provided for @noTeamsInClub.
  ///
  /// In en, this message translates to:
  /// **'No teams in this club.'**
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
  /// **'Club for random teams'**
  String get labelClubForRandomTeams;

  /// No description provided for @radioNoClub.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get radioNoClub;

  /// No description provided for @radioAddToExistingClub.
  ///
  /// In en, this message translates to:
  /// **'Add to existing club'**
  String get radioAddToExistingClub;

  /// No description provided for @hintSelectClub.
  ///
  /// In en, this message translates to:
  /// **'Select a club'**
  String get hintSelectClub;

  /// No description provided for @radioCreateNewClub.
  ///
  /// In en, this message translates to:
  /// **'Create new club'**
  String get radioCreateNewClub;

  /// No description provided for @hintClubNameRandom.
  ///
  /// In en, this message translates to:
  /// **'Club name (leave blank for random)'**
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
  /// **'Tournament is already in all clubs.'**
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
  /// **'Not in any clubs yet.'**
  String get notInAnyClubsYet;

  /// No description provided for @clubPlayersAndTeams.
  ///
  /// In en, this message translates to:
  /// **'{players} player(s) • {teams} team(s)'**
  String clubPlayersAndTeams(int players, int teams);
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

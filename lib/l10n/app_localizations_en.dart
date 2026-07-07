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
  String get navQuickStart => 'Start Game';

  @override
  String get navTournaments => 'TournaQ Arena';

  @override
  String get navTeams => 'Teams';

  @override
  String get navClubs => 'Groups';

  @override
  String get navPlayers => 'Players';

  @override
  String get navAdmin => 'Administration';

  @override
  String get navSponsoring => 'Sponsoring & Promo';

  @override
  String get navContact => 'Contact & About';

  @override
  String get pageGames => 'Quick Games';

  @override
  String get pageTeams => 'Teams';

  @override
  String get pagePlayers => 'Players';

  @override
  String get pageTournaments => 'TournaQ Arena';

  @override
  String get pageClubs => 'Groups';

  @override
  String get pageGameScorecard => 'Scoreboard';

  @override
  String get pageGameplayHistory => 'Match History';

  @override
  String get pageTeamDetails => 'Team Details';

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
  String get btnDelete => 'Delete';

  @override
  String get btnAssign => 'Assign';

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
  String get btnCreateTeam => 'Create Team';

  @override
  String get btnCreatePlayer => 'Create Player';

  @override
  String get btnCreateTournament => 'Create Tournament';

  @override
  String get btnCreateClub => 'Create Group';

  @override
  String get btnSavePlayers => 'Save Players';

  @override
  String get btnDeleteHistory => 'Delete History';

  @override
  String get btnGenerate10RandomTeams => 'Generate 10 Random Teams';

  @override
  String get btnGenerate10RandomPlayers => 'Generate 10 Random Players';

  @override
  String get quickStartTitle => 'Quick Game';

  @override
  String get quickStartFormatQuestion => 'How many sets?';

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
  String get quickStartSelectTeam1 => 'Select Team 1';

  @override
  String get quickStartSelectTeam2 => 'Select Team 2';

  @override
  String get quickStartTeam1Name => 'Team 1 Name';

  @override
  String get quickStartTeam2Name => 'Team 2 Name';

  @override
  String get quickStartBack => 'Back';

  @override
  String get quickStartReRoll => 'Re-roll';

  @override
  String get sectionMatchHistory => 'Match History';

  @override
  String get sectionGameplayControls => 'Gameplay Controls';

  @override
  String get sectionMatchActions => 'Match Actions';

  @override
  String get sectionSponsoring => 'Sponsoring';

  @override
  String get sectionOpportunities => 'Opportunities';

  @override
  String get sectionGetInvolved => 'Get Involved';

  @override
  String sectionTeamsCount(int count) {
    return 'Teams ($count)';
  }

  @override
  String sectionPlayersCount(int count) {
    return 'Players ($count)';
  }

  @override
  String sectionTournamentsCount(int count) {
    return 'Tournaments ($count)';
  }

  @override
  String sectionClubsCount(int count) {
    return 'Groups ($count)';
  }

  @override
  String get hintSearchTeams => 'Search teams...';

  @override
  String get hintSearchPlayers => 'Search players...';

  @override
  String get hintSearchTournaments => 'Search tournaments...';

  @override
  String get hintSearchClubs => 'Search groups...';

  @override
  String get filterPlayer => 'Player';

  @override
  String get filterTeam => 'Team';

  @override
  String get filterTournament => 'Tournament';

  @override
  String get filterClub => 'Group';

  @override
  String get filterMode => 'Mode';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterSource => 'Source';

  @override
  String get sideChangeTitle => 'Side Change';

  @override
  String get sideChangeBody => 'Teams must switch sides now.';

  @override
  String sideChangeBodyWithScore(int score) {
    return 'Total score is $score.\n\nTeams must switch sides now.';
  }

  @override
  String get sideChangeContinue => 'Sides Switched — Continue';

  @override
  String get scoreGameOptions => 'Game Options';

  @override
  String get scoreSwapTeams => 'Swap Teams';

  @override
  String get scoreSwapSubtitle => 'Switch left and right sides';

  @override
  String get scoreChangeService => 'Change Service';

  @override
  String get scoreChangeServiceSubtitle => 'Advance to next server';

  @override
  String get scoreGameplayHistory => 'Gameplay History';

  @override
  String get scoreGameplayHistorySubtitle => 'Point-by-point scoring timeline';

  @override
  String get scoreHistoryCompact => 'History';

  @override
  String get scoreTargetScore => 'Target score:';

  @override
  String get scoreLockBannerGameComplete =>
      'Game completed — undo completion to edit scores';

  @override
  String get scoreLockBannerSetComplete =>
      'Set completed — undo completion to edit scores';

  @override
  String get scoreTooltipDecrease => 'Decrease';

  @override
  String get scoreTooltipIncrease => 'Increase';

  @override
  String get gameStatusCompleted => 'Completed';

  @override
  String get gameStatusInProgress => 'In Progress';

  @override
  String get gameStatusPending => 'Pending';

  @override
  String get gameMenuScorecard => 'Scoreboard';

  @override
  String get gameMenuDelete => 'Delete Game';

  @override
  String get gameTileQuick => 'Quick';

  @override
  String setHeader(int n, int target) {
    return 'Set $n  ·  to $target';
  }

  @override
  String setFinalScore(int s1, int s2) {
    return 'Final: $s1 – $s2';
  }

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get comingSoonLabel => 'COMING SOON';

  @override
  String get comingSoonBody =>
      'Your feedback can help shape this feature before it launches.';

  @override
  String get comingSoonLearnMore => 'Learn more on website';

  @override
  String get landingTournamentsSubtitle => 'Manage games and tournaments';

  @override
  String get landingAdminSubtitle => 'Manage players, teams & groups';

  @override
  String get btnGotIt => 'Got it';

  @override
  String get btnLearnMore => 'Learn more';

  @override
  String get tournamentsSectionQuickGames => 'Quick Games';

  @override
  String get tournamentsSectionSingle => 'Single Competitions & Socials';

  @override
  String get tournamentsSectionTeam => 'Team Competitions';

  @override
  String get tournamentsSectionHistory => 'Tournament History';

  @override
  String get modeQuickGamesDesc => 'Ad-hoc matches';

  @override
  String get modeSocialScramblesDesc => 'Meet and compete';

  @override
  String get modeKotcDesc => 'Establish you reign';

  @override
  String get modeDoghouseDesc => 'Get out of the Doghouse';

  @override
  String get modeLeagueDesc => 'Points-based standings';

  @override
  String get modeSingleElimDesc => 'Classic knockout bracket';

  @override
  String get modeDoubleElimDesc => 'Two-chance bracket';

  @override
  String get modeGroupSeDesc => 'Group stage · Single Elimination';

  @override
  String get modeGroupDeDesc => 'Group stage · Double Elimination';

  @override
  String get modeSwissDesc => 'Paired rounds by score';

  @override
  String get modeLeagueShortDesc =>
      'Track standings across a full round-robin season with points, wins, and goal difference.';

  @override
  String get modeDoubleElimShortDesc =>
      'Winners and losers brackets — you need two losses to be eliminated.';

  @override
  String get modeGroupSeShortDesc =>
      'Teams advance from a group stage into a single-elimination knockout bracket.';

  @override
  String get modeGroupDeShortDesc =>
      'Teams advance from a group stage into a double-elimination bracket.';

  @override
  String get modeSwissShortDesc =>
      'Players are paired each round based on their current score — no eliminations, full schedule.';

  @override
  String get tournamentsDeleteTitle => 'Delete all history?';

  @override
  String tournamentsDeleteBody(int count) {
    return 'This will permanently delete all $count tournaments. This cannot be undone.';
  }

  @override
  String get tournamentsDeleteAll => 'Delete all';

  @override
  String get tournamentsAllLabel => 'All Tournaments';

  @override
  String get tournamentsInfoContent =>
      'Start a match or run a full tournament — all from one place.\n\nQuick Games — Scored matches on the spot. Minimal setup, just pick two teams and go.\n\nSingle Competitions & Socials — Individual formats where players compete and rank as themselves, rotating across the session.\n\nTeam Competitions — Team-based formats where pre-formed teams face off in a bracket or standings table.\n\nTap Info on any tile to learn more before you begin.';

  @override
  String get landingQuickStartSubtitle => 'Beach Volleyball Match';

  @override
  String get landingMatchHistoryTitle => 'Match History';

  @override
  String get landingMatchHistorySubtitle => 'Browse and review past games';

  @override
  String get landingMoreTournamentTitle => 'More Tournament Features';

  @override
  String get landingMoreTournamentSub =>
      'Additional formats, brackets, and competitive structures.';

  @override
  String get landingDeviceScalabilityTitle => 'Device & Screen Scalability';

  @override
  String get landingDeviceScalabilitySub =>
      'Optimised layouts for tablets, web, and all screen sizes.';

  @override
  String get landingScorecardSharingTitle =>
      'Scorecard Sharing & Tournament Scaling';

  @override
  String get landingScorecardSharingSub =>
      'Share results and support larger events and groups.';

  @override
  String get landingLiveTournamentTitle => 'Live Tournament Features';

  @override
  String get landingLiveTournamentSub =>
      'Real-time scoring, standings, and live event updates.';

  @override
  String get landingAdvancedAdminTitle => 'Advanced User Administration';

  @override
  String get landingAdvancedAdminSub =>
      'Manage players, teams, groups, and organiser roles.';

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
      'Your rating helps us grow and improve TournaQ.';

  @override
  String get promoHelpTitle => 'Help Shape TournaQ';

  @override
  String get promoHelpSubtitle =>
      'We welcome suggestions and ideas for future features and partnerships.';

  @override
  String get promoAdPlaceholder => 'Advertisement';

  @override
  String get promoAdNotSupported => 'Ads available on iOS & Android';

  @override
  String get promoAdThankYou => 'Thank you for supporting TournaQ.';

  @override
  String get promoPartnerSpotlight => 'Partner Spotlight';

  @override
  String get promoPartnerSpotlightSub =>
      'Future partners, groups and organizations may be featured here.';

  @override
  String get promoTournamentPartnerships => 'Tournament Partnerships';

  @override
  String get promoTournamentPartnershipsSub =>
      'Support for tournament organizers and event partnerships.';

  @override
  String get promoPromoteEvent => 'Promote Your Event';

  @override
  String get promoPromoteEventSub =>
      'Future opportunities to showcase tournaments, leagues and events.';

  @override
  String get contactInstagram => 'Instagram';

  @override
  String get contactInstagramHandle => '@tournaq';

  @override
  String get contactSectionSocial => 'Social';

  @override
  String get contactSectionSupport => 'Contact & Support';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactFeedbackForm => 'Feedback Form';

  @override
  String get contactFeedbackSubtitle => 'Feedback, bugs and feature requests';

  @override
  String get contactWebsite => 'Website';

  @override
  String get contactWebsiteSubtitle => 'Visit our website';

  @override
  String get contactSectionLegal => 'Legal';

  @override
  String get contactPrivacyPolicy => 'Privacy Policy';

  @override
  String get contactPrivacyPolicySub => 'How we handle your data';

  @override
  String get contactTermsOfUse => 'Terms of Use';

  @override
  String get contactTermsOfUseSub => 'Rules for using TournaQ';

  @override
  String get contactLegalNotice => 'Legal Notice';

  @override
  String get contactLegalNoticeSub => 'Developer & app information (EU)';

  @override
  String get contactPrivacyOptions => 'Privacy Options';

  @override
  String get contactPrivacyOptionsSub => 'Manage your ad consent choices';

  @override
  String get contactSectionResources => 'Resources';

  @override
  String get contactUserGuide => 'Feature Overview';

  @override
  String get contactUserGuideSub =>
      'Explore all modes and features on the website';

  @override
  String get contactLegalHub => 'Legal Documentation';

  @override
  String get contactLegalHubSub => 'Privacy policy, terms & legal notice';

  @override
  String get ratingDialogBody =>
      'A quick rating helps us reach more players and tournament organizers.';

  @override
  String get deleteHistoryTitle => 'Delete All Match History?';

  @override
  String get deleteHistoryBody =>
      'This will permanently delete all local game records. This cannot be undone.';

  @override
  String dialogDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get dialogDeleteBody => 'This cannot be undone.';

  @override
  String get dialogRemovePlayer => 'Remove Player';

  @override
  String get dialogRemovePlayerBody => 'Remove this player from the team?';

  @override
  String get dialogRemoveFromTournament => 'Remove from Tournament';

  @override
  String get dialogRemoveFromTournamentBody =>
      'Remove this team from the tournament?';

  @override
  String get dialogRemoveFromClub => 'Remove from Group';

  @override
  String get dialogRemoveFromClubBody => 'Remove this team from the group?';

  @override
  String get menuEditPlayers => 'Edit Players';

  @override
  String get menuAssignToTournament => 'Assign to Tournament';

  @override
  String get menuAssignToClub => 'Assign to Group';

  @override
  String get menuAssignToTeam => 'Assign to Team';

  @override
  String get menuAssignPlayer => 'Assign Player';

  @override
  String get menuAssignTeam => 'Assign Team';

  @override
  String get menuAssignTournament => 'Assign Tournament';

  @override
  String get menuGenerateGames => 'Generate Games';

  @override
  String get menuAddToTournament => 'Add to Tournament';

  @override
  String get menuAddToClub => 'Add to Group';

  @override
  String get noGamesYet => 'No games yet';

  @override
  String get noGamesYetSubtitle => 'Start scoring to track gameplay.';

  @override
  String get noGamesYetHint => 'Use Quick Start above or create a tournament.';

  @override
  String get noGamesFiltered => 'No games match the current filters';

  @override
  String get noGamesFilteredHint => 'Try clearing some filters.';

  @override
  String get noTeamsYet => 'No teams yet.';

  @override
  String get noTeamsFiltered => 'No teams match the current filters.';

  @override
  String get noPlayersYet => 'No players yet.';

  @override
  String get noPlayersFiltered => 'No players match the current filters.';

  @override
  String get noTournamentsYet => 'No tournaments yet.';

  @override
  String get noTournamentsFiltered =>
      'No tournaments match the current filters.';

  @override
  String get noClubsYet => 'No groups yet.';

  @override
  String get noClubsFiltered => 'No groups match the current filters.';

  @override
  String get noScoringHistoryYet => 'No scoring history yet';

  @override
  String get noPlayersInTeam => 'No players yet.';

  @override
  String get noTournamentsInTeam => 'Not in any tournaments yet.';

  @override
  String get noClubsInTeam => 'Not in any groups yet.';

  @override
  String get teamNotFound => 'Team not found.';

  @override
  String snackbarGeneratedTeams(int count) {
    return 'Generated $count random teams.';
  }

  @override
  String snackbarGeneratedPlayers(int count) {
    return 'Generated $count random players.';
  }

  @override
  String get snackbarGamesAlreadyGenerated =>
      'Games already generated for this tournament.';

  @override
  String get snackbarAddTeamsFirst =>
      'Add at least 2 teams before generating games.';

  @override
  String teamScopeLabel(String name) {
    return 'Scope: $name';
  }

  @override
  String get editPlayerNamesSubtitle => 'Edit player names';

  @override
  String get playerOne => 'Player 1';

  @override
  String get playerTwo => 'Player 2';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get langAutomatic => 'Automatic';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get errorLinkNotAvailable => 'Link not available yet';

  @override
  String get errorCouldNotOpenLink => 'Could not open link';

  @override
  String get errorCouldNotOpenEmail => 'Could not open email app';

  @override
  String get errorStoreNotAvailable =>
      'Could not open the store — please search for TournaQ manually.';

  @override
  String get gameOptions => 'Game Options';

  @override
  String get swapTeams => 'Swap Teams';

  @override
  String get swapTeamsSubtitle => 'Switch left and right sides';

  @override
  String get changeService => 'Change Service';

  @override
  String get changeServiceSubtitle => 'Advance to next server';

  @override
  String get gameplayHistorySubtitle => 'Point-by-point scoring timeline';

  @override
  String get historyShort => 'History';

  @override
  String get completeSet => 'Complete Set';

  @override
  String get undoSetCompletion => 'Undo Set Completion';

  @override
  String get completeGame => 'Complete Game';

  @override
  String get undoGameCompletion => 'Undo Game Completion';

  @override
  String get targetScore => 'Target score:';

  @override
  String get swapPlayers => 'Swap Players';

  @override
  String get lockBannerGame =>
      'Game completed — undo completion to edit scores';

  @override
  String get lockBannerSet => 'Set completed — undo completion to edit scores';

  @override
  String gameTileWinner(String name) {
    return 'Winner: $name';
  }

  @override
  String get noWinnerDetermined => 'No winner determined';

  @override
  String gameTileMatch(String status) {
    return 'Match: $status';
  }

  @override
  String get menuGameScorecard => 'Game Scorecard';

  @override
  String get btnDeleteGame => 'Delete Game';

  @override
  String get pagePlayerDetails => 'Player Details';

  @override
  String get pageClubDetails => 'Group Details';

  @override
  String get playerNotFound => 'Player not found.';

  @override
  String get clubNotFound => 'Group not found.';

  @override
  String get dialogRemoveFromTeam => 'Remove from Team';

  @override
  String get dialogRemoveFromTeamBody => 'Remove this player from the team?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      'Remove this player from the group?';

  @override
  String get dialogRemoveTournamentFromClub => 'Remove Tournament';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      'Remove this tournament from the group?';

  @override
  String get notAssignedToTeams => 'Not assigned to any teams.';

  @override
  String get notAssignedToClubs => 'Not assigned to any groups.';

  @override
  String userEmailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String userRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get menuAddPlayer => 'Add Player';

  @override
  String get menuAddTeam => 'Add Team';

  @override
  String get menuAddTournament => 'Add Tournament';

  @override
  String get labelName => 'Name';

  @override
  String get btnSuggest => 'Suggest';

  @override
  String get labelEmailOptional => 'Email (optional)';

  @override
  String get labelRoleOptional => 'Role (optional)';

  @override
  String get labelScope => 'Scope';

  @override
  String get hintClubName => 'Group name';

  @override
  String get labelAssignToTeams => 'Assign to Teams';

  @override
  String get labelAssignToClubs => 'Assign to Groups';

  @override
  String get labelAssignToTournaments => 'Assign to Tournaments';

  @override
  String get labelAssignPlayers => 'Assign Players';

  @override
  String get labelAssignTeams => 'Assign Teams';

  @override
  String get labelAssignTournaments => 'Assign Tournaments';

  @override
  String get scopeTemporary => 'Temporary';

  @override
  String get scopeTournament => 'Tournament';

  @override
  String get scopeClub => 'Group';

  @override
  String get labelMode => 'Mode';

  @override
  String get hybridConfigureGroups => 'Configure Hybrid Groups';

  @override
  String hybridGroupsConfigured(int count) {
    return '$count groups configured — tap to edit';
  }

  @override
  String get labelAssignExistingTeams => 'Assign Existing Teams';

  @override
  String get filterAllClubs => 'All groups';

  @override
  String get noTeamsInClub => 'No teams in this group.';

  @override
  String get noTeamsAvailableYet => 'No teams available yet.';

  @override
  String get labelAvailable => 'Available';

  @override
  String get hintDragTeamsHere => 'Tap or drag teams here';

  @override
  String labelSelectedCount(int count) {
    return 'Selected ($count)';
  }

  @override
  String get labelGenerateRandomTeams => 'Generate Random Teams';

  @override
  String get labelNone => 'None';

  @override
  String get labelClubForRandomTeams => 'Group for random teams';

  @override
  String get radioNoClub => 'No group';

  @override
  String get radioAddToExistingClub => 'Add to existing group';

  @override
  String get hintSelectClub => 'Select a group';

  @override
  String get radioCreateNewClub => 'Create new group';

  @override
  String get hintClubNameRandom => 'Group name (leave blank for random)';

  @override
  String get tooltipSuggestName => 'Suggest a name';

  @override
  String get noTeamsFoundSearch => 'No teams found.';

  @override
  String get quickStartShort => 'Quick Start';

  @override
  String get formatBestOfThreeShort => 'Best of Three';

  @override
  String get teamMethodExistingSubtitle => 'Choose from your saved teams';

  @override
  String get teamMethodNewSubtitle => 'Name your teams on the fly';

  @override
  String get teamMethodRandomSubtitle => 'Let us pick fun team names';

  @override
  String get quickStartChooseTeams => 'Choose your teams';

  @override
  String get quickStartSelectTeamsTitle => 'Select Teams';

  @override
  String get quickStartNotEnoughTeams => 'Not enough teams';

  @override
  String get quickStartNotEnoughTeamsBody =>
      'You need at least 2 saved teams.\nTry creating or generating teams instead.';

  @override
  String get teamOne => 'Team 1';

  @override
  String get teamTwo => 'Team 2';

  @override
  String get quickStartChooseTeam1 => 'Choose Team 1';

  @override
  String get quickStartChooseTeam2 => 'Choose Team 2';

  @override
  String get quickStartCreateTeamsTitle => 'Create Teams';

  @override
  String get hintTeam1Example => 'e.g. Red Eagles';

  @override
  String get hintTeam2Example => 'e.g. Blue Lions';

  @override
  String get quickStartRandomTeamsTitle => 'Random Teams';

  @override
  String get quickStartReRollTeams => 'Re-roll Teams';

  @override
  String get btnStart => 'Start';

  @override
  String get labelVs => 'vs';

  @override
  String get hybridModeSetup => 'Hybrid Mode Setup';

  @override
  String get btnDone => 'Done';

  @override
  String get hybridAvailableModes => 'Available Modes';

  @override
  String hybridRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get hybridDragHint =>
      'Long-press to drag into a group, or tap to add to the first group.';

  @override
  String get hybridAllModesAssigned => 'All modes assigned to groups.';

  @override
  String get hybridModeGroups => 'Mode Groups';

  @override
  String get hybridAddGroup => 'Add Group';

  @override
  String get hybridAddGroupHint =>
      'Add a group above, then drag or tap modes into it.';

  @override
  String hybridGroupN(int n) {
    return 'Group $n';
  }

  @override
  String get hybridDragModesHere => 'Drag modes here';

  @override
  String get hybridTip =>
      'Tip: Each group defines a round of play. Teams cycle through all mode groups.';

  @override
  String get pageTournamentDetails => 'Tournament Details';

  @override
  String get tournamentNotFound => 'Tournament not found.';

  @override
  String get assignAllTeamsInTournament =>
      'All teams are already in this tournament.';

  @override
  String get assignTournamentAllClubs => 'Tournament is already in all groups.';

  @override
  String get snackbarAddTeamsFirstCreate =>
      'Add at least 2 teams before creating games.';

  @override
  String get dialogClearAllGames => 'Clear All Games';

  @override
  String get dialogClearAllGamesBody =>
      'Are you sure you want to delete all games in this tournament?';

  @override
  String get btnClear => 'Clear';

  @override
  String get btnCreateGame => 'Create Game';

  @override
  String get btnClearGames => 'Clear Games';

  @override
  String tournamentModeLabel(String name) {
    return 'Mode: $name';
  }

  @override
  String tournamentStatusLabel(String name) {
    return 'Status: $name';
  }

  @override
  String tournamentTeamsLabel(int count) {
    return 'Teams: $count';
  }

  @override
  String tournamentGamesLabel(int count) {
    return 'Games: $count';
  }

  @override
  String get sectionHybridGroups => 'Hybrid Groups';

  @override
  String get noHybridGroupsYet => 'No hybrid groups configured yet.';

  @override
  String get noTeamsAssignedYet => 'No teams assigned yet.';

  @override
  String nPlayersCount(int count) {
    return '$count player(s)';
  }

  @override
  String get sectionLeagueStandings => 'League Standings';

  @override
  String get labelUnknown => 'Unknown';

  @override
  String sectionGamesCount(int count) {
    return 'Games ($count)';
  }

  @override
  String get noGamesCreatedYet => 'No games created yet.';

  @override
  String get notInAnyClubsYet => 'Not in any groups yet.';

  @override
  String clubPlayersAndTeams(int players, int teams) {
    return '$players player(s) • $teams team(s)';
  }

  @override
  String get labelStyle => 'Style';

  @override
  String get assignNothingAvailable => 'Nothing available to assign.';

  @override
  String get btnDeleteAll => 'Delete All';

  @override
  String get statusSetup => 'Setup';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusDue => 'Due';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get labelLate => 'LATE';

  @override
  String get statPts => 'pts';

  @override
  String get statEsc => 'Esc';

  @override
  String get statGames => 'Games';

  @override
  String get statLost => 'Lost';

  @override
  String get doghouseTitle => 'Doghouse';

  @override
  String get doghouseGameHistory => 'Game History';

  @override
  String get doghouseEscaped => 'Escaped';

  @override
  String get doghouseEjected => 'Ejected';

  @override
  String doghouseNGamesLost(int count) {
    return '$count lost';
  }

  @override
  String get doghouseNoGamesYet => 'No games yet.';

  @override
  String get doghouseNoGamesYetBody =>
      'Games will appear here once a team finishes.';

  @override
  String get doghouseNoTournamentsYet => 'No tournaments yet.';

  @override
  String get doghouseNoTournamentsHint => 'Tap New Tournament to get started.';

  @override
  String get doghouseDeleteTournamentTitle => 'Delete Tournament?';

  @override
  String doghouseDeleteTournamentBody(String name) {
    return 'This will permanently delete \"$name\" and all its data.';
  }

  @override
  String get doghouseDeleteAllTitle => 'Delete All Tournaments?';

  @override
  String doghouseDeleteAllBody(int count) {
    return 'This will permanently delete all $count tournament(s).';
  }

  @override
  String get doghouseNewTournament => 'New Tournament';

  @override
  String doghouseTournamentHistory(int count) {
    return 'Tournament History ($count)';
  }

  @override
  String doghouseStatsPlayers(int count) {
    return '$count players';
  }

  @override
  String doghouseStatsGames(int count) {
    return '$count games';
  }

  @override
  String doghouseStatsEscapes(int count) {
    return '$count escapes';
  }

  @override
  String get btnAdd => 'Add';

  @override
  String get btnStop => 'Stop';

  @override
  String get btnUndo => 'Undo';

  @override
  String get labelOptions => 'Options';

  @override
  String get labelGotIt => 'Got it';

  @override
  String get labelTime => 'Time';

  @override
  String get labelAssignment => 'Assignment';

  @override
  String get labelEscapePoints => 'Escape Points';

  @override
  String get labelLossLimit => 'Loss Limit';

  @override
  String get hintPlayerName => 'Player name';

  @override
  String get doghouseScoreboard => 'Scoreboard';

  @override
  String get doghouseTimeUp => 'Time is up';

  @override
  String get doghouseTimerEndedBody =>
      'The session timer has ended. Complete the tournament now?';

  @override
  String get doghouseCompleteTournament => 'Complete Tournament';

  @override
  String get doghouseContinueScoring => 'Continue scoring';

  @override
  String doghouseSubstitute(String name) {
    return 'Substitute $name';
  }

  @override
  String doghouseReturnToQueue(String name) {
    return '$name will return to the queue.';
  }

  @override
  String get doghouseAddPlayersToQueue => 'Add Players to Queue';

  @override
  String doghouseNAdded(int count) {
    return '$count added';
  }

  @override
  String get doghouseLateTagInfo =>
      'All players added here will be tagged \"Late\" in stats.';

  @override
  String get doghouseNoPlayersMatch => 'No players match.';

  @override
  String get doghouseAdd4Random => 'Add 4 random';

  @override
  String get doghouseNoLatePlayersYet => 'No late players added yet.';

  @override
  String get doghouseEscapedExcl => 'Escaped!';

  @override
  String doghouseEscapedScoreMsg(String names, int points) {
    return '$names scored $points points!';
  }

  @override
  String get doghouseEscapeDesc =>
      'They escape the doghouse and return to the queue.';

  @override
  String get doghouseEscapeBtn => 'Escape!';

  @override
  String get doghouseEjectedExcl => 'Ejected!';

  @override
  String doghouseEjectedScoreMsg(String names, int count) {
    return '$names lost $count games!';
  }

  @override
  String get doghouseEjectDesc =>
      'They are ejected from the doghouse and return to the queue.';

  @override
  String get doghouseEjectTeam => 'Eject Team';

  @override
  String get doghouseLeaveTitle => 'Leave without ending game?';

  @override
  String doghouseLeaveBodyPts(int count) {
    return 'The current team has $count unrecorded point(s). Leaving now will discard them.';
  }

  @override
  String get doghouseLeaveBodyEmpty =>
      'The current team\'s unrecorded data will be lost.';

  @override
  String get doghouseLeaveAnyway => 'Leave anyway';

  @override
  String get doghouseTournamentComplete => 'Tournament Complete';

  @override
  String doghouseSummaryStats(int games, int escapes) {
    return '$games game(s) · $escapes escapes';
  }

  @override
  String get doghouseFinalStandings => 'Final Standings';

  @override
  String doghousePairStat(int escapes, int losses) {
    return '$escapes escaped · $losses lost';
  }

  @override
  String get doghousePlayerStats => 'Player Stats';

  @override
  String get doghouseSessionTimer => 'SESSION TIMER';

  @override
  String get doghouseGameplayControls => 'Gameplay Controls';

  @override
  String get doghouseMatchControls => 'Match Controls';

  @override
  String get doghouseStartRestart => 'Start / Restart';

  @override
  String get doghouseTournamentCompleted => 'Tournament completed';

  @override
  String get doghouseNotEnoughInQueue => 'Not enough players in queue.';

  @override
  String get doghouseSuggestedTeam => 'Suggested Team';

  @override
  String doghouseSelectPlayers(int needed, int selected) {
    return 'Select $needed players ($selected / $needed)';
  }

  @override
  String get doghouseQueueTapToAdd => 'Queue — tap to add';

  @override
  String get doghouseEnterDoghouse => 'Enter Doghouse';

  @override
  String get doghouseViewAllGames => 'View all completed games';

  @override
  String doghouseEscapePointsLabel(int count) {
    return '$count pt escape';
  }

  @override
  String doghouseLossLimitLabel(int count) {
    return '$count loss limit';
  }

  @override
  String get doghouseAddPlayerToQueue => 'Add Player to Queue';

  @override
  String get doghouseUndoCompletion => 'Undo Completion';

  @override
  String get doghouseSaveAndReturn => 'Save and Return';

  @override
  String get doghouseGameLost => 'Game\nLost';

  @override
  String get doghouseUndoGame => 'Undo\nGame';

  @override
  String get doghouseUndoLastGame => 'Undo Last Game';

  @override
  String get doghouseTournamentSetup => 'Tournament Setup';

  @override
  String get doghouseTapToAddPlayers => 'Tap to add players';

  @override
  String doghouseNPlayersAdded(int count) {
    return '$count players added';
  }

  @override
  String doghouseNeedAtLeastN(int count, int min) {
    return '$count added · need at least $min';
  }

  @override
  String get doghouseClearAll => 'Clear all';

  @override
  String doghouseFillNRandom(int count) {
    return 'Fill $count random';
  }

  @override
  String get doghouseSetupNoPlayers => 'No players added yet.';

  @override
  String get doghouseSourceExisting => 'Existing player';

  @override
  String get doghouseSourceNew => 'New player';

  @override
  String get doghouseSourceRandom => 'Random placeholder';

  @override
  String get doghouseTournamentName => 'Tournament Name';

  @override
  String get doghouseSetupGood => 'Setup looks good!';

  @override
  String get doghouseSetupIncomplete => 'Setup incomplete';

  @override
  String get doghouseRemoveAllTitle => 'Remove all players?';

  @override
  String get doghouseRemoveAllBody =>
      'This will remove all added players from the list.';

  @override
  String get doghouseRemoveAll => 'Remove all';

  @override
  String get doghouseAssignmentManual => 'Manual';

  @override
  String get doghouseAssignmentAutomated => 'Automated';

  @override
  String doghouseAddedCount(int added, int total) {
    return 'Added ($added/$total)';
  }

  @override
  String statsRounds(int count) {
    return '$count rounds';
  }

  @override
  String statsPtsScored(int total) {
    return '$total pts scored';
  }

  @override
  String statsTeams(int count) {
    return '$count teams';
  }

  @override
  String statsCourts(int count) {
    return '$count courts';
  }

  @override
  String statsMatchesOf(int completed, int total) {
    return '$completed / $total matches';
  }

  @override
  String statsGamesOf(int completed, int total) {
    return '$completed/$total games';
  }

  @override
  String get setupDuplicateNameTitle => 'Duplicate Name';

  @override
  String setupDuplicateNameBody(String name) {
    return '\"$name\" is already added to this tournament. Add anyway?';
  }

  @override
  String get btnAddAnyway => 'Add Anyway';

  @override
  String get setupSectionPlayers => 'Players';

  @override
  String get setupSectionCreatePlayer => 'Create Player';

  @override
  String setupAddExistingPlayers(int count) {
    return 'Add Existing Players ($count)';
  }

  @override
  String get setupSearchPlayersHint => 'Search players…';

  @override
  String get setupPlayerNameHint => 'Player name';

  @override
  String setupPlayersOf(int count, int target) {
    return '$count/$target players added';
  }

  @override
  String get setupTargetPlayers => 'Target Players';

  @override
  String get setupAvailableTime => 'Available Time';

  @override
  String get setupMatchDuration => 'Match Duration';

  @override
  String get setupCourts => 'Courts';

  @override
  String get setupBreakBetweenRounds => 'Break Between Rounds';

  @override
  String get setupFormat => 'Format';

  @override
  String get setupPlannedStartTime => 'Planned Start Time';

  @override
  String get setupPlannedEndTime => 'Planned End Time';

  @override
  String get setupSchedulePreview => 'Schedule Preview';

  @override
  String get setupRoundDuration => 'Round duration';

  @override
  String get setupRoundsLabel => 'Rounds';

  @override
  String get setupScheduledDuration => 'Scheduled duration';

  @override
  String get setupScheduledEndTime => 'Scheduled end time';

  @override
  String get setupSuggestions => 'Suggestions';

  @override
  String get setupFormatAutoAllplay => 'Auto-Allplay';

  @override
  String get setupCourtsInfoBody =>
      'Currently fixed at 1 court.\n\nMulti-court support — assign and track multiple simultaneous courts with optimal rotation — is planned for a future release.';

  @override
  String get setupSeedingRandom => 'Random';

  @override
  String get setupSeedingSeeded => 'Seeded';

  @override
  String get setupOddTeamsByes => 'Byes';

  @override
  String get setupOddTeamsPlayIn => 'Play-in';

  @override
  String get setupSectionTeams => 'Teams';

  @override
  String get setupRemoveAllTeamsTitle => 'Remove all teams?';

  @override
  String get setupRemoveAllTeamsBody =>
      'This will remove all added teams from the list.';

  @override
  String get setupNoTeamsMatch => 'No teams match.';

  @override
  String get setupNoTeamsAddedYet => 'No teams added yet.';

  @override
  String get setupTeamNameHint => 'Team name';

  @override
  String setupAddExistingTeams(int count) {
    return 'Add Existing Teams ($count)';
  }

  @override
  String get setupSearchTeamsHint => 'Search teams…';

  @override
  String get setupCreateTeam => 'Create Team';

  @override
  String get setupGeneration => 'Generation';

  @override
  String get setupOddTeamsLabel => 'Odd Teams';

  @override
  String get setupEarlyRounds => 'Early Rounds';

  @override
  String get setupFinalRounds => 'Final Rounds';

  @override
  String get setupReadyToStart => 'Ready to start!';

  @override
  String setupAddAllTeams(int count) {
    return 'Add all $count teams to continue';
  }

  @override
  String get setupTapToAddTeams => 'Tap to add teams';

  @override
  String setupTeamsOf(int count, int target) {
    return '$count/$target teams added';
  }

  @override
  String get overviewSectionOverview => 'Overview';

  @override
  String get overviewSectionTimeline => 'Schedule preview';

  @override
  String timelineStart(String time) {
    return 'Start: $time';
  }

  @override
  String timelinePredictedEnd(String time) {
    return 'Predicted end: $time';
  }

  @override
  String timelineRound(int number) {
    return 'Round $number';
  }

  @override
  String timelineBreakUntil(String time) {
    return 'Break until $time';
  }

  @override
  String get timelineScheduleTitle => 'Tournament schedule';

  @override
  String get timelineTournamentStart => 'Tournament start';

  @override
  String get timelineGameDuration => 'Game duration (pending rounds)';

  @override
  String get timelineBreakDurationPending => 'Break duration (pending rounds)';

  @override
  String get timelinePaceAlertsTitle => 'Pace alerts';

  @override
  String get timelinePaceAlertsSubtitle =>
      'Flag rounds as on track, due, or overdue';

  @override
  String get timelineEditStartTime => 'Start time';

  @override
  String get timelineMatchDuration => 'Match duration';

  @override
  String get timelineBreakAfterRound => 'Break after round';

  @override
  String get overviewSectionSchedule => 'Schedule';

  @override
  String overviewGamesCompleted(int completed, int total) {
    return '$completed / $total games completed';
  }

  @override
  String overviewStatsSummary(int rounds, int courts, int players) {
    return '$rounds rounds  ·  $courts courts  ·  $players players';
  }

  @override
  String overviewFinished(String time) {
    return 'Finished: $time';
  }

  @override
  String overviewEstFinish(String time) {
    return 'Est. finish: $time';
  }

  @override
  String overviewSectionPlayers(int count) {
    return 'Players ($count)';
  }

  @override
  String get overviewAddPlayerSubtitle => 'Added players join as a late entry.';

  @override
  String overviewAddConfirm(String name) {
    return 'Add $name?';
  }

  @override
  String overviewAddLateBody(String name) {
    return '$name will join as a late entry. Remaining pairings will be reshuffled — some players may end up with an unequal number of games.';
  }

  @override
  String overviewSwapTitle(String name) {
    return 'Swap out $name';
  }

  @override
  String overviewSwapSubtitle(String name) {
    return '$name will be removed from upcoming rounds.';
  }

  @override
  String overviewEjectTitle(String name) {
    return 'Eject $name?';
  }

  @override
  String overviewEjectBody(String name) {
    return '$name will be removed from all upcoming rounds. Remaining pairings will be reshuffled — some players may end up with an unequal number of games. Completed games remain in the stats.';
  }

  @override
  String get overviewEjectBtn => 'Eject';

  @override
  String get overviewEditPlayer => 'Edit Player';

  @override
  String get overviewAllPlayersAlready =>
      'All existing players are already in this tournament.';

  @override
  String overviewRound(int number) {
    return 'Round $number';
  }

  @override
  String get overviewActual => 'actual';

  @override
  String overviewBreakUntil(String time) {
    return '· Break until $time';
  }

  @override
  String get scrambleStatusSwappedOut => 'swapped out';

  @override
  String get scrambleStatusSwappedIn => 'sub in';

  @override
  String get scrambleStatusLate => 'late';

  @override
  String get tooltipEdit => 'Edit';

  @override
  String get tooltipEject => 'Eject';

  @override
  String get tooltipSwap => 'Swap';

  @override
  String get tooltipRankings => 'Player Rankings';

  @override
  String get scorecardSwapSides => 'Swap Sides';

  @override
  String get scorecardSwapSidesSubtitle => 'Switch left and right display';

  @override
  String get scorecardMatchHistory => 'Match History';

  @override
  String get scorecardMatchHistorySubtitle => 'Point-by-point scoring timeline';

  @override
  String get scorecardPlannedStart => 'Planned start';

  @override
  String get scorecardPlannedEnd => 'Planned end';

  @override
  String get scorecardEnd => 'End';

  @override
  String get scorecardOverSchedule => 'Over schedule!';

  @override
  String get scorecardOverScheduleHurry => 'Over schedule · Hurry up!';

  @override
  String scorecardStartsServing(String name) {
    return '$name starts serving';
  }

  @override
  String get scorecardUndoCompletion => 'Undo Completion';

  @override
  String get scorecardStartMatch => 'Start Match';

  @override
  String get scorecardCompleteGame => 'Complete Game';

  @override
  String get scorecardManualScore => 'Manually Set Score';

  @override
  String get scorecardBackToSchedule => 'Back to Schedule';

  @override
  String get scorecardManualScoreBlockedTitle => 'Manual Score Not Available';

  @override
  String get scorecardManualScoreBlockedBody =>
      'Manual score entry is only available before live scoring has started. This prevents accidentally overwriting points that were already tracked.';

  @override
  String get scorecardManualScoreDescription =>
      'Use this when the game was played without live scoring. Enter the final score for both sides and complete the game.';

  @override
  String get btnOK => 'OK';

  @override
  String get btnAdjustFinalScore => 'Adjust Final Score';

  @override
  String get btnRestart => 'Restart';

  @override
  String get btnResume => 'Resume';

  @override
  String get btnApply => 'Apply';

  @override
  String labelMinutes(int n) {
    return '$n min';
  }

  @override
  String get matchScorecard => 'Scorecard';

  @override
  String get matchOptions => 'Match Options';

  @override
  String get matchViewHistory => 'View point-by-point history';

  @override
  String get matchComplete => 'Match complete';

  @override
  String get matchSetCompleteBanner => 'Set complete — undo set to edit score';

  @override
  String matchSuggestedToServe(String name) {
    return '$name suggested to start serving';
  }

  @override
  String matchSuggestedReferee(String name) {
    return '$name suggested as referee';
  }

  @override
  String get matchAssignRefereeManually => 'Assign a referee manually';

  @override
  String get matchScoresTiedSet =>
      'Scores are tied — a set cannot end in a draw.';

  @override
  String get matchScoresTiedMatch =>
      'Scores are tied — a winner must be determined before completing.';

  @override
  String get matchSetsTied =>
      'Sets are tied — a winner must be determined before completing.';

  @override
  String get matchUndoSet => 'Undo Set';

  @override
  String get matchCompleteSet => 'Complete Set';

  @override
  String get matchUndoMatchCompletion => 'Undo Match Completion';

  @override
  String get matchCompleteMatch => 'Complete Match';

  @override
  String get matchSetScoreManually => 'Set Score Manually';

  @override
  String get matchBackToBracket => 'Back to Bracket';

  @override
  String matchCourtLabel(int court) {
    return 'Court $court';
  }

  @override
  String matchStartsAt(String time) {
    return 'Starts $time';
  }

  @override
  String matchSetNScore(int n) {
    return 'Set $n Score';
  }

  @override
  String get matchSetScore => 'Set Score';

  @override
  String get bracketWithdrawTitle => 'Withdraw Team?';

  @override
  String bracketWithdrawBody(String name) {
    return 'Withdraw \"$name\"? Their pending matches will be resolved as walkovers.';
  }

  @override
  String get bracketWithdrawBtn => 'Withdraw';

  @override
  String get bracketFinalRoundsFormat => 'Final Rounds Format';

  @override
  String get bracketEarlyRoundsFormat => 'Early Rounds Format';

  @override
  String bracketFinalRoundsAppliesTo(int n) {
    return 'Applies to the last $n round(s)';
  }

  @override
  String get bracketEarlyRoundsAppliesTo => 'Applies to all early rounds';

  @override
  String get setupSetsPerGame => 'Sets per game';

  @override
  String get setupPointsPerSet => 'Points per set';

  @override
  String get bracketBreakFinalRounds => 'Break — Final Rounds';

  @override
  String get bracketBreakEarlyRounds => 'Break — Early Rounds';

  @override
  String get bracketNoBreak => 'No break';

  @override
  String get bracketNoStartTime => 'No start time set';

  @override
  String bracketStartsLabel(String label) {
    return 'Starts: $label';
  }

  @override
  String get bracketTournamentWinner => 'Tournament Winner';

  @override
  String get bracketRunnerUp => 'Runner-up';

  @override
  String get bracketThirdPlace => '3rd place';

  @override
  String bracketSectionTeams(int count) {
    return 'Teams ($count)';
  }

  @override
  String get bracketSwapTeamTitle => 'Swap Team';

  @override
  String bracketSwapTeamSubtitle(String name) {
    return 'Replacing \"$name\" in all pending matches.';
  }

  @override
  String get bracketSearchTeams => 'Search teams…';

  @override
  String get bracketNoTeamsInHub => 'No teams in Teams Hub yet.';

  @override
  String get bracketAllTeamsInTournament =>
      'All hub teams are already in this tournament.';

  @override
  String get scorecardMatchTimerLabel => 'Match Timer';

  @override
  String get scorecardUpcomingGames => 'Upcoming Games';

  @override
  String scorecardPlayerCount(int n) {
    return '$n players';
  }

  @override
  String get scorecardGameCompletedLock =>
      'Game completed — undo to edit scores';

  @override
  String get kotcTimeIsUp => 'Time is up';

  @override
  String get kotcSessionEndedBody =>
      'The session timer has ended. Complete the tournament now?';

  @override
  String kotcSubstituteTitle(String name) {
    return 'Substitute $name';
  }

  @override
  String kotcSubstituteBody(String name) {
    return '$name will return to the queue.';
  }

  @override
  String get kotcAddLateTitle => 'Add Late Player?';

  @override
  String get kotcAddLateBody =>
      'This player is joining late and won\'t have had the same opportunities as players who started at the beginning. Their stats will be tagged as \"Late\".';

  @override
  String get btnContinue => 'Continue';

  @override
  String get kotcLateTag => 'LATE';

  @override
  String get kotcAdminTag => 'ADMIN';

  @override
  String get kotcChangeAdmin => 'Change Admin';

  @override
  String get kotcChangeAdminSubtitle =>
      'Select who keeps score. The current admin returns to the queue.';

  @override
  String get kotcNextAdmin => 'NEXT ADMIN';

  @override
  String get kotcNextAdminNote => 'Suggested from the current court team.';

  @override
  String get kotcGameWon => 'Game Won!';

  @override
  String kotcReachedPoints(String names, int points) {
    return '$names reached $points points!';
  }

  @override
  String get kotcEjectReturn => 'They will be ejected and return to the queue.';

  @override
  String get kotcEjectTeamTitle => 'Eject Team?';

  @override
  String kotcEjectTeamBodyPoints(int pts) {
    return 'Current team will be ejected. Their $pts pts will be recorded.';
  }

  @override
  String get kotcEjectTeamBodyNoPoints =>
      'Current team will be ejected and return to the queue.';

  @override
  String get kotcLeaveTitle => 'Leave without ejecting?';

  @override
  String kotcLeaveBodyPoints(int pts) {
    return 'The current team has $pts unrecorded points. Leaving now will discard them. Eject the team first to save their score.';
  }

  @override
  String get kotcTournamentComplete => 'Tournament complete';

  @override
  String kotcGamesSummary(int games, int pts) {
    return '$games games · $pts pts total';
  }

  @override
  String get kotcStatGames => 'Games';

  @override
  String get kotcStatWins => 'Wins';

  @override
  String get kotcStatPts => 'Pts';

  @override
  String get kotcOptions => 'Options';

  @override
  String get kotcHistorySubtitle => 'View all completed games';

  @override
  String get kotcTeamEjected => 'Team\nEjected';

  @override
  String get kotcUndoEject => 'Undo\nEject';

  @override
  String get kotcUndoLastEjection => 'Undo Last Ejection';

  @override
  String get kotcUpNext => 'Up Next';

  @override
  String get kotcChallengers => 'Challengers';

  @override
  String get kotcWaitingForPlayers => 'Waiting for players...';

  @override
  String kotcStrikePoints(int n) {
    return '$n pt strike';
  }

  @override
  String get kotcAdd4Random => 'Add 4 random';

  @override
  String kotcExistingPlayers(int n) {
    return 'Existing Players ($n)';
  }

  @override
  String get kotcPlayerNameHint => 'Player name';

  @override
  String get labelEject => 'Eject';

  @override
  String get kotcSetupStyleLabel => 'Style';

  @override
  String get kotcSetupStyleHelp =>
      'The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court.';

  @override
  String get kotcSetupAssignmentLabel => 'Assignment';

  @override
  String get kotcSetupAssignmentHelp =>
      'How the next court team is chosen.\n\nManual — the coach selects players from the queue by tapping them.\n\nAutomated — TournaQ suggests the best team, prioritising players who have waited longest and haven\'t been paired together recently. The coach can re-roll before confirming.\n\nAutomated — All Play — like Automated but no dedicated coach. A rotating admin keeps score while everyone else plays. TournaQ picks a random starting admin and suggests the next handoff from the ejected team after each game.';

  @override
  String get kotcSetupPlayersHelp =>
      'Target number of players for the session. Used when auto-filling random players. Actual participants are added in the Players section below.';

  @override
  String get kotcSetupTimeHelp =>
      'Total session duration. The timer counts down from this value. When time runs out you will be prompted to complete the tournament or keep scoring.';

  @override
  String get kotcSetupStrikeLabel => 'Strike Points (0 = off)';

  @override
  String get kotcSetupStrikeHelp =>
      'Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them.';

  @override
  String get kotcHistoryWon => 'Won';

  @override
  String get kotcHistoryNoGames => 'No games yet.';

  @override
  String get kotcHistoryNoGamesSubtitle =>
      'Games will appear here once a team is ejected.';

  @override
  String get setupPlayersPerSide => 'Style';

  @override
  String get setupAppliesToLast => 'Applies to last';

  @override
  String get setupScheduleLabel => 'Schedule';

  @override
  String get setupScheduleSoft => 'Soft Schedule';

  @override
  String get setupScheduleForced => 'Forced Schedule';

  @override
  String get setupAddBreak => 'Add break';

  @override
  String setupBreakMins(int mins) {
    return '$mins min break';
  }

  @override
  String setupStartsAt(String date) {
    return 'Starts: $date';
  }

  @override
  String setupMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get setupRoundPlayIn => 'Play-in';

  @override
  String get setupRoundFinal => 'Final';

  @override
  String get setupRoundSemiFinal => 'Semi-final';

  @override
  String get setupRoundQuarterFinal => 'Quarter-final';

  @override
  String setupRoundN(int n) {
    return 'Round $n';
  }

  @override
  String setupPlayerN(int n) {
    return 'Player $n';
  }

  @override
  String get koEditTeam => 'Edit Team';

  @override
  String get koTeamSetupSubtitle => 'How would you like to set up this team?';

  @override
  String get koCreateNew => 'Edit Manually';

  @override
  String get koCreateNewSubtitle =>
      'Set a custom name and assign players manually';

  @override
  String get koImportFromHub => 'Import from Teams Hub';

  @override
  String get koImportFromHubSubtitle =>
      'Pick an existing team — name and players fill in automatically';

  @override
  String get koNoTeamsInHub =>
      'No teams in Teams Hub yet.\nCreate teams via the Teams section first.';

  @override
  String get koPlayersSection => 'Players';

  @override
  String koSkillRating(Object rating) {
    return 'Skill: $rating';
  }

  @override
  String get koUnrated => 'Unrated';

  @override
  String get koTapToAssign => 'Tap to assign';

  @override
  String get koImportTitle => 'Import from Teams Hub';

  @override
  String get koNoTeamsFound => 'No teams found.';

  @override
  String koPlayerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String koAddTeamN(int n) {
    return 'Add Team $n';
  }

  @override
  String get koAddTeamSubtitle => 'How would you like to add this team?';

  @override
  String get koFromTeamsHub => 'From Teams Hub';

  @override
  String get koFromTeamsHubSubtitle => 'Pick an existing team from your hub';

  @override
  String get koNoTeamsInHubYet => 'No teams in hub yet.';

  @override
  String get koNoTeamsInHubYetShort => 'No teams in hub yet';

  @override
  String get koCreateNewTeamTitle => 'Create New Team';

  @override
  String get koAddTeamBtn => 'Add Team';

  @override
  String get koFromPlayersHub => 'B — From Players Hub';

  @override
  String get koNoPlayersInHub => 'No players in the hub yet.';

  @override
  String get koNoPlayersFound => 'No players found.';

  @override
  String get koEditPlayer => 'Edit Player';

  @override
  String get koPlayerNameLabel => 'Name';

  @override
  String get koSkillRatingOptional => 'Skill rating (optional)';

  @override
  String get koSectionAEditPlayer => 'A — Edit Player';

  @override
  String get koSectionANewPlayer => 'A — New Player';

  @override
  String get koSectionBNewPlayer => 'B — New Player';

  @override
  String get koSectionCFromHub => 'C — From Players Hub';

  @override
  String get quickGameSettingsTitle => 'Game Settings';

  @override
  String get quickGamePlayersPerSide => 'Players per side';

  @override
  String get quickGameFormatLabel => 'Format';

  @override
  String get quickGameTeamsTitle => 'Teams';

  @override
  String get quickGameTapToConfigure => 'Tap to configure team';

  @override
  String get adminHelpBody =>
      'Manage players, teams, and groups to efficiently set up your games and tournaments.';

  @override
  String get adminInfoTooltip => 'About Administration';

  @override
  String get adminManagePlayers => 'Manage player profiles';

  @override
  String get adminManageTeams => 'Manage teams and rosters';

  @override
  String get adminManageGroups => 'Manage groups and affiliations';

  @override
  String get playerHubSubtitle => 'Manage your global player pool';

  @override
  String get teamHubSubtitle => 'Manage your global team pool';

  @override
  String get groupHubSubtitle => 'Manage your global group pool';

  @override
  String get modeQuickGamesName => 'Quick Games';

  @override
  String get modeSocialScramblesName => 'Social Scrambles';

  @override
  String get modeKotcName => 'King of the Court';

  @override
  String get modeDoghouseName => 'Doghouse';

  @override
  String get modeLeagueName => 'League';

  @override
  String get modeLeagueFullName => 'League / Round Robin';

  @override
  String get modeSingleElimName => 'Single Elimination';

  @override
  String get modeDoubleElimName => 'Double Elimination';

  @override
  String get modeGroupSeName => 'Group + SE';

  @override
  String get modeGroupSeFullName => 'Group + Single Elimination';

  @override
  String get modeGroupDeName => 'Group + DE';

  @override
  String get modeGroupDeFullName => 'Group + Double Elimination';

  @override
  String get modeSwissName => 'Swiss System';

  @override
  String get modeComingSoonHelp => 'Detailed description coming soon.';

  @override
  String get modeQuickGamesHelp =>
      'Quick Games lets you start a scored match on the spot — no tournament setup required. Pick two teams, set the format, and start tracking the score immediately.\n\nIdeal for casual play, training sessions, or any time you just want to run a game without a bracket.';

  @override
  String get modeSocialScramblesHelp =>
      'Social Scrambles is a timed, rotating mixer where teams are randomly reshuffled every round. No one stays partnered for long — the whole point is to play with and against as many different people as possible across the session.\n\nPerfect for beach sessions, open days, or any group that wants competitive play without the pressure of a fixed bracket.\n\nFair by design. TournaQ schedules every player into the maximum number of rounds while keeping wait times as short as possible. When not everyone can fit on court at once, sitting-out rotations are balanced so no player waits longer than others.\n\nHow a round works:\n• Teams are randomly drawn at the start of each round\n• All courts play simultaneously for the set match duration\n• A short break follows before the next round\n• Cumulative wins are tracked across all rounds\n\nAdd your players, set a session timer, and go.';

  @override
  String get modeKotcHelp =>
      'King of the Court is a fast, individual competition where every player fights for the crown. Players rotate on and off court in groups, scoring points for each rally won — but the ranking is entirely personal. The player who accumulates the most game wins (then points) across the session takes the title.\n\nShort format, high energy — perfect as a session warm-up or a standalone competition.\n\nFair by design. TournaQ\'s Automated assignment ensures everyone plays with and against different people, keeping wait times low and avoiding repeat pairings. Because matchups stay balanced throughout the session, the final standings are a genuine reflection of individual performance — not just who got the easiest draw.\n\nHow a game works:\n• Win a rally → each player on that side scores a point\n• Reach your Strike Points target → current group wins the game, everyone rotates back to the queue\n• Coach manually ejects → stint ends, points recorded as-is\n• Next players step up immediately\n\nBefore you start, agree on:\n• Who serves each rally\n• Whether to use Strike Points and what the target should be\n\nAdd your players, set a session timer, and go.';

  @override
  String get modeDoghouseHelp =>
      'Doghouse is a fast, competitive tournament where the action never stops. One team battles from the doghouse — score enough points to escape and make way for the next challengers. Hit your loss limit first and you\'re out.\n\nShort format, high intensity — great as a session warm-up or a standalone competition.\n\nFair by design. TournaQ\'s Automated assignment ensures everyone plays with and against different people, keeping wait times low and avoiding repeat pairings. Because matchups stay balanced throughout the session, the final standings are a genuine reflection of how each player performed — not just who got the easier draw.\n\nHow a game works:\n• Win a rally → score a point\n• Lose a rally → game lost, point score resets\n• Reach your Escape Points target → escaped, back to the queue\n• Hit the Loss Limit → ejected, next team steps in\n\nBefore you start, agree on:\n• Which team serves each rally\n• Escape Points and Loss Limit settings\n\nAdd your players, set a session timer, and go.';
}

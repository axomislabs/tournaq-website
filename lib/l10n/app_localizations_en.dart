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
  String get pageGames => 'Games';

  @override
  String get pageTeams => 'Teams';

  @override
  String get pagePlayers => 'Players';

  @override
  String get pageTournaments => 'Tournaments';

  @override
  String get pageClubs => 'Clubs';

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
  String get btnCreateClub => 'Create Club';

  @override
  String get btnSavePlayers => 'Save Players';

  @override
  String get btnDeleteHistory => 'Delete History';

  @override
  String get btnGenerate10RandomTeams => 'Generate 10 Random Teams';

  @override
  String get btnGenerate10RandomPlayers => 'Generate 10 Random Players';

  @override
  String get quickStartTitle => 'Quick Start Game';

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
    return 'Clubs ($count)';
  }

  @override
  String get hintSearchTeams => 'Search teams...';

  @override
  String get hintSearchPlayers => 'Search players...';

  @override
  String get hintSearchTournaments => 'Search tournaments...';

  @override
  String get hintSearchClubs => 'Search clubs...';

  @override
  String get filterPlayer => 'Player';

  @override
  String get filterTeam => 'Team';

  @override
  String get filterTournament => 'Tournament';

  @override
  String get filterClub => 'Club';

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
  String get landingQuickStartSubtitle => 'Beach Volleyball Match';

  @override
  String get landingMatchHistoryTitle => 'Match History';

  @override
  String get landingMatchHistorySubtitle => 'Browse and review past games';

  @override
  String get landingTournamentManagement => 'Tournament Management';

  @override
  String get landingTournamentManagementSub =>
      'Create and manage tournaments with multiple formats.';

  @override
  String get landingTournamentManagementDesc =>
      'Organize structured competitions, formats, and match results in one place.';

  @override
  String get landingAdminTitle => 'Player, Team & Club Administration';

  @override
  String get landingAdminSub => 'Organize players, teams and clubs.';

  @override
  String get landingAdminDesc => 'Organize Players, Teams and Clubs.';

  @override
  String get landingAdminPageTitle => 'Administration';

  @override
  String get landingCloudTitle => 'Cloud Services';

  @override
  String get landingCloudSub => 'Cloud synchronization and connected features.';

  @override
  String get landingCloudDesc =>
      'Future connected features for syncing, sharing, and accessing TournaQ across devices.';

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
      'Future partners, clubs and organizations may be featured here.';

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
  String get contactWebsiteSubtitle => 'Coming soon';

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
  String get dialogRemoveFromClub => 'Remove from Club';

  @override
  String get dialogRemoveFromClubBody => 'Remove this team from the club?';

  @override
  String get menuEditPlayers => 'Edit Players';

  @override
  String get menuAssignToTournament => 'Assign to Tournament';

  @override
  String get menuAssignToClub => 'Assign to Club';

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
  String get menuAddToClub => 'Add to Club';

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
  String get noClubsYet => 'No clubs yet.';

  @override
  String get noClubsFiltered => 'No clubs match the current filters.';

  @override
  String get noScoringHistoryYet => 'No scoring history yet';

  @override
  String get noPlayersInTeam => 'No players yet.';

  @override
  String get noTournamentsInTeam => 'Not in any tournaments yet.';

  @override
  String get noClubsInTeam => 'Not in any clubs yet.';

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
  String get pageClubDetails => 'Club Details';

  @override
  String get playerNotFound => 'Player not found.';

  @override
  String get clubNotFound => 'Club not found.';

  @override
  String get dialogRemoveFromTeam => 'Remove from Team';

  @override
  String get dialogRemoveFromTeamBody => 'Remove this player from the team?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      'Remove this player from the club?';

  @override
  String get dialogRemoveTournamentFromClub => 'Remove Tournament';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      'Remove this tournament from the club?';

  @override
  String get notAssignedToTeams => 'Not assigned to any teams.';

  @override
  String get notAssignedToClubs => 'Not assigned to any clubs.';

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
  String get hintClubName => 'Club name';

  @override
  String get labelAssignToTeams => 'Assign to Teams';

  @override
  String get labelAssignToClubs => 'Assign to Clubs';

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
  String get scopeClub => 'Club';

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
  String get filterAllClubs => 'All clubs';

  @override
  String get noTeamsInClub => 'No teams in this club.';

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
  String get labelClubForRandomTeams => 'Club for random teams';

  @override
  String get radioNoClub => 'No club';

  @override
  String get radioAddToExistingClub => 'Add to existing club';

  @override
  String get hintSelectClub => 'Select a club';

  @override
  String get radioCreateNewClub => 'Create new club';

  @override
  String get hintClubNameRandom => 'Club name (leave blank for random)';

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
  String get assignTournamentAllClubs => 'Tournament is already in all clubs.';

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
  String get notInAnyClubsYet => 'Not in any clubs yet.';

  @override
  String clubPlayersAndTeams(int players, int teams) {
    return '$players player(s) • $teams team(s)';
  }
}

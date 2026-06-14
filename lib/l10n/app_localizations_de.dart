// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'TournaQ';

  @override
  String get appTagline => 'Spielstand, Spiele und Turniere';

  @override
  String get navHome => 'Startseite';

  @override
  String get navQuickStart => 'Schnellstart Spiel';

  @override
  String get navTournaments => 'Turniere';

  @override
  String get navTeams => 'Teams';

  @override
  String get navClubs => 'Clubs';

  @override
  String get navPlayers => 'Spieler';

  @override
  String get navAdmin => 'Verwaltung';

  @override
  String get navSponsoring => 'Sponsoring & Promo';

  @override
  String get navContact => 'Kontakt & Info';

  @override
  String get pageGames => 'Spiele';

  @override
  String get pageTeams => 'Teams';

  @override
  String get pagePlayers => 'Spieler';

  @override
  String get pageTournaments => 'Turniere';

  @override
  String get pageClubs => 'Vereine';

  @override
  String get pageGameScorecard => 'Spielstand';

  @override
  String get pageGameplayHistory => 'Spielhistorie';

  @override
  String get pageTeamDetails => 'Team-Details';

  @override
  String get btnStartGame => 'Spiel starten';

  @override
  String get btnCancel => 'Abbrechen';

  @override
  String get btnCreate => 'Erstellen';

  @override
  String get btnRemove => 'Entfernen';

  @override
  String get btnSave => 'Speichern';

  @override
  String get btnOk => 'OK';

  @override
  String get btnDelete => 'Löschen';

  @override
  String get btnAssign => 'Zuweisen';

  @override
  String get btnGiveFeedback => 'Feedback geben';

  @override
  String get btnEmailUs => 'E-Mail senden';

  @override
  String get btnRateTournaQ => 'TournaQ bewerten';

  @override
  String get btnNotNow => 'Nicht jetzt';

  @override
  String get btnSaveAndReturn => 'Speichern & zurück zu Spielen';

  @override
  String get btnCreateTeam => 'Team erstellen';

  @override
  String get btnCreatePlayer => 'Spieler erstellen';

  @override
  String get btnCreateTournament => 'Turnier erstellen';

  @override
  String get btnCreateClub => 'Verein erstellen';

  @override
  String get btnSavePlayers => 'Spieler speichern';

  @override
  String get btnDeleteHistory => 'Löschen';

  @override
  String get btnGenerate10RandomTeams => '10 zufällige Teams generieren';

  @override
  String get btnGenerate10RandomPlayers => '10 zufällige Spieler generieren';

  @override
  String get quickStartTitle => 'Schnellstart Spiel';

  @override
  String get quickStartFormatQuestion => 'Wie viele Sets?';

  @override
  String get quickStartTeamQuestion => 'Wie möchtest du die Teams auswählen?';

  @override
  String get formatOneSet => 'Ein Satz';

  @override
  String get formatOneSetSubtitle => 'Einzelsatz entscheidet den Sieger';

  @override
  String get formatBestOfThree => 'Best of Three';

  @override
  String get formatBestOfThreeSubtitle =>
      'Wer zuerst zwei Sätze gewinnt, gewinnt das Match';

  @override
  String get teamMethodExisting => 'Bestehende Teams wählen';

  @override
  String get teamMethodNew => 'Neue Teams erstellen';

  @override
  String get teamMethodRandom => 'Zufällige Teams generieren';

  @override
  String get quickStartSelectTeam1 => 'Team 1 wählen';

  @override
  String get quickStartSelectTeam2 => 'Team 2 wählen';

  @override
  String get quickStartTeam1Name => 'Name Team 1';

  @override
  String get quickStartTeam2Name => 'Name Team 2';

  @override
  String get quickStartBack => 'Zurück';

  @override
  String get quickStartReRoll => 'Neu würfeln';

  @override
  String get sectionMatchHistory => 'Spielhistorie';

  @override
  String get sectionGameplayControls => 'Spielsteuerung';

  @override
  String get sectionMatchActions => 'Spielaktionen';

  @override
  String get sectionSponsoring => 'Sponsoring';

  @override
  String get sectionOpportunities => 'Möglichkeiten';

  @override
  String get sectionGetInvolved => 'Mitmachen';

  @override
  String sectionTeamsCount(int count) {
    return 'Teams ($count)';
  }

  @override
  String sectionPlayersCount(int count) {
    return 'Spieler ($count)';
  }

  @override
  String sectionTournamentsCount(int count) {
    return 'Turniere ($count)';
  }

  @override
  String sectionClubsCount(int count) {
    return 'Vereine ($count)';
  }

  @override
  String get hintSearchTeams => 'Teams suchen...';

  @override
  String get hintSearchPlayers => 'Spieler suchen...';

  @override
  String get hintSearchTournaments => 'Turniere suchen...';

  @override
  String get hintSearchClubs => 'Vereine suchen...';

  @override
  String get filterPlayer => 'Spieler';

  @override
  String get filterTeam => 'Team';

  @override
  String get filterTournament => 'Turnier';

  @override
  String get filterClub => 'Verein';

  @override
  String get filterMode => 'Modus';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterSource => 'Quelle';

  @override
  String get sideChangeTitle => 'Seitenwechsel';

  @override
  String get sideChangeBody => 'Die Teams müssen jetzt die Seiten wechseln.';

  @override
  String sideChangeBodyWithScore(int score) {
    return 'Gesamtstand: $score.\n\nDie Teams müssen jetzt die Seiten wechseln.';
  }

  @override
  String get sideChangeContinue => 'Seiten gewechselt — Weiter';

  @override
  String get scoreGameOptions => 'Spieloptionen';

  @override
  String get scoreSwapTeams => 'Teams tauschen';

  @override
  String get scoreSwapSubtitle => 'Links und rechts tauschen';

  @override
  String get scoreChangeService => 'Aufschlag wechseln';

  @override
  String get scoreChangeServiceSubtitle => 'Zum nächsten Aufschläger wechseln';

  @override
  String get scoreGameplayHistory => 'Spielverlauf';

  @override
  String get scoreGameplayHistorySubtitle => 'Punkt-für-Punkt-Verlauf';

  @override
  String get scoreHistoryCompact => 'Verlauf';

  @override
  String get scoreTargetScore => 'Zielpunktzahl:';

  @override
  String get scoreLockBannerGameComplete =>
      'Spiel abgeschlossen — Abschluss rückgängig machen, um Punkte zu bearbeiten';

  @override
  String get scoreLockBannerSetComplete =>
      'Satz abgeschlossen — Abschluss rückgängig machen, um Punkte zu bearbeiten';

  @override
  String get scoreTooltipDecrease => 'Verringern';

  @override
  String get scoreTooltipIncrease => 'Erhöhen';

  @override
  String get gameStatusCompleted => 'Abgeschlossen';

  @override
  String get gameStatusInProgress => 'Laufend';

  @override
  String get gameStatusPending => 'Ausstehend';

  @override
  String get gameMenuScorecard => 'Spielstand';

  @override
  String get gameMenuDelete => 'Spiel löschen';

  @override
  String get gameTileQuick => 'Schnell';

  @override
  String setHeader(int n, int target) {
    return 'Satz $n  ·  bis $target';
  }

  @override
  String setFinalScore(int s1, int s2) {
    return 'Ergebnis: $s1 – $s2';
  }

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get comingSoonLabel => 'DEMNÄCHST';

  @override
  String get comingSoonBody =>
      'Dein Feedback kann helfen, diese Funktion zu gestalten.';

  @override
  String get landingQuickStartSubtitle => 'Beach-Volleyball-Match';

  @override
  String get landingMatchHistoryTitle => 'Spielhistorie';

  @override
  String get landingMatchHistorySubtitle =>
      'Vergangene Spiele ansehen und überprüfen';

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
      'Manage players, teams, clubs, and organiser roles.';

  @override
  String get promoSupportTitle => 'TournaQ unterstützen';

  @override
  String get promoSupportSubtitle =>
      'Werbung und Sponsoring helfen, TournaQ weiterzuentwickeln.';

  @override
  String get promoFollowTitle => 'Folge der Reise';

  @override
  String get promoFollowSubtitle =>
      'Teile Events, bei denen TournaQ dabei war — markiere uns auf Instagram.';

  @override
  String get promoRateTitle => 'TournaQ gefällt dir?';

  @override
  String get promoRateSubtitle =>
      'Deine Bewertung hilft uns, zu wachsen und TournaQ zu verbessern.';

  @override
  String get promoHelpTitle => 'Gestalte TournaQ mit';

  @override
  String get promoHelpSubtitle =>
      'Wir freuen uns über Vorschläge und Ideen für neue Funktionen und Partnerschaften.';

  @override
  String get promoAdPlaceholder => 'Werbung';

  @override
  String get promoAdNotSupported => 'Werbung auf iOS & Android verfügbar';

  @override
  String get promoAdThankYou => 'Danke, dass du TournaQ unterstützt.';

  @override
  String get promoPartnerSpotlight => 'Partner-Spotlight';

  @override
  String get promoPartnerSpotlightSub =>
      'Zukünftige Partner, Vereine und Organisationen können hier vorgestellt werden.';

  @override
  String get promoTournamentPartnerships => 'Turnierpartnerschaften';

  @override
  String get promoTournamentPartnershipsSub =>
      'Unterstützung für Turnierveranstalter und Veranstaltungspartnerschaften.';

  @override
  String get promoPromoteEvent => 'Dein Event bewerben';

  @override
  String get promoPromoteEventSub =>
      'Zukünftige Möglichkeiten, Turniere, Ligen und Events zu präsentieren.';

  @override
  String get contactInstagram => 'Instagram';

  @override
  String get contactInstagramHandle => '@tournaq';

  @override
  String get contactSectionSocial => 'Social';

  @override
  String get contactSectionSupport => 'Kontakt & Support';

  @override
  String get contactEmailLabel => 'E-Mail';

  @override
  String get contactFeedbackForm => 'Feedback-Formular';

  @override
  String get contactFeedbackSubtitle => 'Feedback, Fehler und Funktionswünsche';

  @override
  String get contactWebsite => 'Website';

  @override
  String get contactWebsiteSubtitle => 'Unsere Homepage besuchen';

  @override
  String get contactSectionLegal => 'Rechtliches';

  @override
  String get contactPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get contactPrivacyPolicySub => 'Wie wir deine Daten verarbeiten';

  @override
  String get contactTermsOfUse => 'Nutzungsbedingungen';

  @override
  String get contactTermsOfUseSub => 'Regeln für die Nutzung von TournaQ';

  @override
  String get contactLegalNotice => 'Impressum';

  @override
  String get contactLegalNoticeSub => 'Entwickler- und App-Informationen (EU)';

  @override
  String get contactPrivacyOptions => 'Datenschutzoptionen';

  @override
  String get contactPrivacyOptionsSub =>
      'Einwilligungseinstellungen für Werbung verwalten';

  @override
  String get contactSectionResources => 'Ressourcen';

  @override
  String get contactUserGuide => 'Benutzerhandbuch';

  @override
  String get contactUserGuideSub => 'Anleitungen und Tutorials';

  @override
  String get contactLegalHub => 'Rechtliche Dokumentation';

  @override
  String get contactLegalHubSub =>
      'Datenschutz, Nutzungsbedingungen & Impressum';

  @override
  String get ratingDialogBody =>
      'Eine kurze Bewertung hilft uns, mehr Spieler und Turnierorganisatoren zu erreichen.';

  @override
  String get deleteHistoryTitle => 'Gesamte Spielhistorie löschen?';

  @override
  String get deleteHistoryBody =>
      'Alle lokalen Spielaufzeichnungen werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String dialogDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get dialogDeleteBody => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get dialogRemovePlayer => 'Spieler entfernen';

  @override
  String get dialogRemovePlayerBody => 'Diesen Spieler aus dem Team entfernen?';

  @override
  String get dialogRemoveFromTournament => 'Aus Turnier entfernen';

  @override
  String get dialogRemoveFromTournamentBody =>
      'Dieses Team aus dem Turnier entfernen?';

  @override
  String get dialogRemoveFromClub => 'Aus Verein entfernen';

  @override
  String get dialogRemoveFromClubBody =>
      'Dieses Team aus dem Verein entfernen?';

  @override
  String get menuEditPlayers => 'Spieler bearbeiten';

  @override
  String get menuAssignToTournament => 'Zu Turnier hinzufügen';

  @override
  String get menuAssignToClub => 'Zu Verein hinzufügen';

  @override
  String get menuAssignToTeam => 'Zu Team hinzufügen';

  @override
  String get menuAssignPlayer => 'Spieler zuweisen';

  @override
  String get menuAssignTeam => 'Team zuweisen';

  @override
  String get menuAssignTournament => 'Turnier zuweisen';

  @override
  String get menuGenerateGames => 'Spiele generieren';

  @override
  String get menuAddToTournament => 'Zu Turnier hinzufügen';

  @override
  String get menuAddToClub => 'Zu Verein hinzufügen';

  @override
  String get noGamesYet => 'Noch keine Spiele';

  @override
  String get noGamesYetSubtitle =>
      'Starte ein Spiel, um den Spielverlauf zu verfolgen.';

  @override
  String get noGamesYetHint =>
      'Nutze Schnellstart oben oder erstelle ein Turnier.';

  @override
  String get noGamesFiltered =>
      'Keine Spiele entsprechen den aktuellen Filtern';

  @override
  String get noGamesFilteredHint => 'Versuche, einige Filter zu entfernen.';

  @override
  String get noTeamsYet => 'Noch keine Teams.';

  @override
  String get noTeamsFiltered =>
      'Keine Teams entsprechen den aktuellen Filtern.';

  @override
  String get noPlayersYet => 'Noch keine Spieler.';

  @override
  String get noPlayersFiltered =>
      'Keine Spieler entsprechen den aktuellen Filtern.';

  @override
  String get noTournamentsYet => 'Noch keine Turniere.';

  @override
  String get noTournamentsFiltered =>
      'Keine Turniere entsprechen den aktuellen Filtern.';

  @override
  String get noClubsYet => 'Noch keine Vereine.';

  @override
  String get noClubsFiltered =>
      'Keine Vereine entsprechen den aktuellen Filtern.';

  @override
  String get noScoringHistoryYet => 'Noch keine Spielhistorie';

  @override
  String get noPlayersInTeam => 'Noch keine Spieler.';

  @override
  String get noTournamentsInTeam => 'Noch in keinen Turnieren.';

  @override
  String get noClubsInTeam => 'Noch in keinen Vereinen.';

  @override
  String get teamNotFound => 'Team nicht gefunden.';

  @override
  String snackbarGeneratedTeams(int count) {
    return '$count zufällige Teams generiert.';
  }

  @override
  String snackbarGeneratedPlayers(int count) {
    return '$count zufällige Spieler generiert.';
  }

  @override
  String get snackbarGamesAlreadyGenerated =>
      'Spiele wurden bereits für dieses Turnier generiert.';

  @override
  String get snackbarAddTeamsFirst =>
      'Füge mindestens 2 Teams hinzu, bevor du Spiele generierst.';

  @override
  String teamScopeLabel(String name) {
    return 'Bereich: $name';
  }

  @override
  String get editPlayerNamesSubtitle => 'Spielernamen bearbeiten';

  @override
  String get playerOne => 'Spieler 1';

  @override
  String get playerTwo => 'Spieler 2';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get langAutomatic => 'Automatisch';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get errorLinkNotAvailable => 'Link noch nicht verfügbar';

  @override
  String get errorCouldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get errorCouldNotOpenEmail =>
      'E-Mail-App konnte nicht geöffnet werden';

  @override
  String get errorStoreNotAvailable =>
      'Store konnte nicht geöffnet werden — bitte suche manuell nach TournaQ.';

  @override
  String get gameOptions => 'Spieloptionen';

  @override
  String get swapTeams => 'Teams tauschen';

  @override
  String get swapTeamsSubtitle => 'Linke und rechte Seite wechseln';

  @override
  String get changeService => 'Aufschlag wechseln';

  @override
  String get changeServiceSubtitle => 'Zum nächsten Aufschläger wechseln';

  @override
  String get gameplayHistorySubtitle => 'Punkt-für-Punkt Zeitleiste';

  @override
  String get historyShort => 'Verlauf';

  @override
  String get completeSet => 'Satz abschließen';

  @override
  String get undoSetCompletion => 'Satzabschluss rückgängig';

  @override
  String get completeGame => 'Spiel abschließen';

  @override
  String get undoGameCompletion => 'Spielabschluss rückgängig';

  @override
  String get targetScore => 'Zielpunktzahl:';

  @override
  String get swapPlayers => 'Spieler tauschen';

  @override
  String get lockBannerGame =>
      'Spiel abgeschlossen — Abschluss rückgängig machen, um Punkte zu bearbeiten';

  @override
  String get lockBannerSet =>
      'Satz abgeschlossen — Abschluss rückgängig machen, um Punkte zu bearbeiten';

  @override
  String gameTileWinner(String name) {
    return 'Sieger: $name';
  }

  @override
  String get noWinnerDetermined => 'Kein Sieger ermittelt';

  @override
  String gameTileMatch(String status) {
    return 'Spiel: $status';
  }

  @override
  String get menuGameScorecard => 'Spielprotokoll';

  @override
  String get btnDeleteGame => 'Spiel löschen';

  @override
  String get pagePlayerDetails => 'Spielerdetails';

  @override
  String get pageClubDetails => 'Clubdetails';

  @override
  String get playerNotFound => 'Spieler nicht gefunden.';

  @override
  String get clubNotFound => 'Club nicht gefunden.';

  @override
  String get dialogRemoveFromTeam => 'Aus Team entfernen';

  @override
  String get dialogRemoveFromTeamBody =>
      'Diesen Spieler aus dem Team entfernen?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      'Diesen Spieler aus dem Club entfernen?';

  @override
  String get dialogRemoveTournamentFromClub => 'Turnier entfernen';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      'Dieses Turnier aus dem Club entfernen?';

  @override
  String get notAssignedToTeams => 'Keinem Team zugeordnet.';

  @override
  String get notAssignedToClubs => 'Keinem Club zugeordnet.';

  @override
  String userEmailLabel(String email) {
    return 'E-Mail: $email';
  }

  @override
  String userRoleLabel(String role) {
    return 'Rolle: $role';
  }

  @override
  String get menuAddPlayer => 'Spieler hinzufügen';

  @override
  String get menuAddTeam => 'Team hinzufügen';

  @override
  String get menuAddTournament => 'Turnier hinzufügen';

  @override
  String get labelName => 'Name';

  @override
  String get btnSuggest => 'Vorschlag';

  @override
  String get labelEmailOptional => 'E-Mail (optional)';

  @override
  String get labelRoleOptional => 'Rolle (optional)';

  @override
  String get labelScope => 'Geltungsbereich';

  @override
  String get hintClubName => 'Clubname';

  @override
  String get labelAssignToTeams => 'Teams zuweisen';

  @override
  String get labelAssignToClubs => 'Clubs zuweisen';

  @override
  String get labelAssignToTournaments => 'Turniere zuweisen';

  @override
  String get labelAssignPlayers => 'Spieler zuweisen';

  @override
  String get labelAssignTeams => 'Teams zuweisen';

  @override
  String get labelAssignTournaments => 'Turniere zuweisen';

  @override
  String get scopeTemporary => 'Temporär';

  @override
  String get scopeTournament => 'Turnier';

  @override
  String get scopeClub => 'Club';

  @override
  String get labelMode => 'Modus';

  @override
  String get hybridConfigureGroups => 'Hybridgruppen konfigurieren';

  @override
  String hybridGroupsConfigured(int count) {
    return '$count Gruppen konfiguriert – tippen zum Bearbeiten';
  }

  @override
  String get labelAssignExistingTeams => 'Vorhandene Teams zuweisen';

  @override
  String get filterAllClubs => 'Alle Clubs';

  @override
  String get noTeamsInClub => 'Keine Teams in diesem Club.';

  @override
  String get noTeamsAvailableYet => 'Noch keine Teams vorhanden.';

  @override
  String get labelAvailable => 'Verfügbar';

  @override
  String get hintDragTeamsHere => 'Teams antippen oder hierher ziehen';

  @override
  String labelSelectedCount(int count) {
    return 'Ausgewählt ($count)';
  }

  @override
  String get labelGenerateRandomTeams => 'Zufällige Teams generieren';

  @override
  String get labelNone => 'Keine';

  @override
  String get labelClubForRandomTeams => 'Club für zufällige Teams';

  @override
  String get radioNoClub => 'Kein Club';

  @override
  String get radioAddToExistingClub => 'Zu vorhandenem Club hinzufügen';

  @override
  String get hintSelectClub => 'Club auswählen';

  @override
  String get radioCreateNewClub => 'Neuen Club erstellen';

  @override
  String get hintClubNameRandom => 'Clubname (leer lassen für Zufall)';

  @override
  String get tooltipSuggestName => 'Namen vorschlagen';

  @override
  String get noTeamsFoundSearch => 'Keine Teams gefunden.';

  @override
  String get quickStartShort => 'Schnellstart';

  @override
  String get formatBestOfThreeShort => 'Best of Three';

  @override
  String get teamMethodExistingSubtitle => 'Aus gespeicherten Teams wählen';

  @override
  String get teamMethodNewSubtitle => 'Teams spontan benennen';

  @override
  String get teamMethodRandomSubtitle => 'Wir wählen lustige Teamnamen';

  @override
  String get quickStartChooseTeams => 'Teams auswählen';

  @override
  String get quickStartSelectTeamsTitle => 'Teams auswählen';

  @override
  String get quickStartNotEnoughTeams => 'Nicht genug Teams';

  @override
  String get quickStartNotEnoughTeamsBody =>
      'Du brauchst mindestens 2 gespeicherte Teams.\nVersuche, Teams zu erstellen oder zu generieren.';

  @override
  String get teamOne => 'Team 1';

  @override
  String get teamTwo => 'Team 2';

  @override
  String get quickStartChooseTeam1 => 'Team 1 wählen';

  @override
  String get quickStartChooseTeam2 => 'Team 2 wählen';

  @override
  String get quickStartCreateTeamsTitle => 'Teams erstellen';

  @override
  String get hintTeam1Example => 'z. B. Rote Adler';

  @override
  String get hintTeam2Example => 'z. B. Blaue Löwen';

  @override
  String get quickStartRandomTeamsTitle => 'Zufällige Teams';

  @override
  String get quickStartReRollTeams => 'Teams neu generieren';

  @override
  String get btnStart => 'Start';

  @override
  String get labelVs => 'vs';

  @override
  String get hybridModeSetup => 'Hybrid-Modus einrichten';

  @override
  String get btnDone => 'Fertig';

  @override
  String get hybridAvailableModes => 'Verfügbare Modi';

  @override
  String hybridRemaining(int count) {
    return '$count verbleibend';
  }

  @override
  String get hybridDragHint =>
      'Lang drücken zum Ziehen in eine Gruppe oder tippen, um zur ersten Gruppe hinzuzufügen.';

  @override
  String get hybridAllModesAssigned => 'Alle Modi den Gruppen zugewiesen.';

  @override
  String get hybridModeGroups => 'Modusgruppen';

  @override
  String get hybridAddGroup => 'Gruppe hinzufügen';

  @override
  String get hybridAddGroupHint =>
      'Füge oben eine Gruppe hinzu, dann ziehe oder tippe Modi hinein.';

  @override
  String hybridGroupN(int n) {
    return 'Gruppe $n';
  }

  @override
  String get hybridDragModesHere => 'Modi hierher ziehen';

  @override
  String get hybridTip =>
      'Tipp: Jede Gruppe definiert eine Spielrunde. Teams durchlaufen alle Modusgruppen.';

  @override
  String get pageTournamentDetails => 'Turnierdetails';

  @override
  String get tournamentNotFound => 'Turnier nicht gefunden.';

  @override
  String get assignAllTeamsInTournament =>
      'Alle Teams sind bereits in diesem Turnier.';

  @override
  String get assignTournamentAllClubs =>
      'Das Turnier ist bereits in allen Clubs.';

  @override
  String get snackbarAddTeamsFirstCreate =>
      'Füge mindestens 2 Teams hinzu, bevor du Spiele erstellst.';

  @override
  String get dialogClearAllGames => 'Alle Spiele löschen';

  @override
  String get dialogClearAllGamesBody =>
      'Möchtest du wirklich alle Spiele dieses Turniers löschen?';

  @override
  String get btnClear => 'Löschen';

  @override
  String get btnCreateGame => 'Spiel erstellen';

  @override
  String get btnClearGames => 'Spiele löschen';

  @override
  String tournamentModeLabel(String name) {
    return 'Modus: $name';
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
    return 'Spiele: $count';
  }

  @override
  String get sectionHybridGroups => 'Hybridgruppen';

  @override
  String get noHybridGroupsYet => 'Noch keine Hybridgruppen konfiguriert.';

  @override
  String get noTeamsAssignedYet => 'Noch keine Teams zugewiesen.';

  @override
  String nPlayersCount(int count) {
    return '$count Spieler';
  }

  @override
  String get sectionLeagueStandings => 'Ligatabelle';

  @override
  String get labelUnknown => 'Unbekannt';

  @override
  String sectionGamesCount(int count) {
    return 'Spiele ($count)';
  }

  @override
  String get noGamesCreatedYet => 'Noch keine Spiele erstellt.';

  @override
  String get notInAnyClubsYet => 'Noch in keinem Club.';

  @override
  String clubPlayersAndTeams(int players, int teams) {
    return '$players Spieler • $teams Teams';
  }

  @override
  String get labelStyle => 'Stil';

  @override
  String get assignNothingAvailable => 'Nichts zum Zuweisen verfügbar.';

  @override
  String get btnDeleteAll => 'Alle löschen';

  @override
  String get statusSetup => 'Einrichtung';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get statusInProgress => 'Laufend';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String dateDaysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String get labelLate => 'SPÄT';

  @override
  String get statPts => 'Pkt';

  @override
  String get statEsc => 'Ent';

  @override
  String get statGames => 'Spiele';

  @override
  String get statLost => 'Verl';

  @override
  String get doghouseTitle => 'Doghouse';

  @override
  String get doghouseGameHistory => 'Spielhistorie';

  @override
  String get doghouseEscaped => 'Entkommen';

  @override
  String get doghouseEjected => 'Rausgeworfen';

  @override
  String doghouseNGamesLost(int count) {
    return '$count verl.';
  }

  @override
  String get doghouseNoGamesYet => 'Noch keine Spiele.';

  @override
  String get doghouseNoGamesYetBody =>
      'Spiele erscheinen hier, sobald ein Team fertig ist.';

  @override
  String get doghouseNoTournamentsYet => 'Noch keine Turniere.';

  @override
  String get doghouseNoTournamentsHint =>
      'Tippe auf Neues Turnier, um loszulegen.';

  @override
  String get doghouseDeleteTournamentTitle => 'Turnier löschen?';

  @override
  String doghouseDeleteTournamentBody(String name) {
    return 'Damit wird \"$name\" und alle zugehörigen Daten dauerhaft gelöscht.';
  }

  @override
  String get doghouseDeleteAllTitle => 'Alle Turniere löschen?';

  @override
  String doghouseDeleteAllBody(int count) {
    return 'Damit werden alle $count Turnier(e) dauerhaft gelöscht.';
  }

  @override
  String get doghouseNewTournament => 'Neues Turnier';

  @override
  String doghouseTournamentHistory(int count) {
    return 'Turnierhistorie ($count)';
  }

  @override
  String doghouseStatsPlayers(int count) {
    return '$count Spieler';
  }

  @override
  String doghouseStatsGames(int count) {
    return '$count Spiele';
  }

  @override
  String doghouseStatsEscapes(int count) {
    return '$count Entkommen';
  }

  @override
  String get btnAdd => 'Hinzufügen';

  @override
  String get btnStop => 'Stopp';

  @override
  String get btnUndo => 'Rückgängig';

  @override
  String get labelOptions => 'Optionen';

  @override
  String get labelGotIt => 'Verstanden';

  @override
  String get labelTime => 'Zeit';

  @override
  String get labelAssignment => 'Zuweisung';

  @override
  String get labelEscapePoints => 'Ausstiegspunkte';

  @override
  String get labelLossLimit => 'Verlustlimit';

  @override
  String get hintPlayerName => 'Spielername';

  @override
  String get doghouseScoreboard => 'Spielstand';

  @override
  String get doghouseTimeUp => 'Zeit abgelaufen';

  @override
  String get doghouseTimerEndedBody =>
      'Der Sitzungs-Timer ist abgelaufen. Turnier jetzt beenden?';

  @override
  String get doghouseCompleteTournament => 'Turnier beenden';

  @override
  String get doghouseContinueScoring => 'Weiter spielen';

  @override
  String doghouseSubstitute(String name) {
    return '$name ersetzen';
  }

  @override
  String doghouseReturnToQueue(String name) {
    return '$name kommt zurück in die Warteschlange.';
  }

  @override
  String get doghouseAddPlayersToQueue =>
      'Spieler zur Warteschlange hinzufügen';

  @override
  String doghouseNAdded(int count) {
    return '$count hinzugefügt';
  }

  @override
  String get doghouseLateTagInfo =>
      'Alle hier hinzugefügten Spieler werden in den Stats als \"Spät\" markiert.';

  @override
  String get doghouseNoPlayersMatch => 'Keine Spieler gefunden.';

  @override
  String get doghouseAdd4Random => '4 Zufällige hinzufügen';

  @override
  String get doghouseNoLatePlayersYet => 'Noch keine Nachzügler hinzugefügt.';

  @override
  String get doghouseEscapedExcl => 'Entkommen!';

  @override
  String doghouseEscapedScoreMsg(String names, int points) {
    return '$names hat $points Punkte erzielt!';
  }

  @override
  String get doghouseEscapeDesc =>
      'Sie entkommen der Doghouse und kehren in die Warteschlange zurück.';

  @override
  String get doghouseEscapeBtn => 'Entkommen!';

  @override
  String get doghouseEjectedExcl => 'Rausgeworfen!';

  @override
  String doghouseEjectedScoreMsg(String names, int count) {
    return '$names hat $count Spiele verloren!';
  }

  @override
  String get doghouseEjectDesc =>
      'Sie werden aus der Doghouse geworfen und kehren in die Warteschlange zurück.';

  @override
  String get doghouseEjectTeam => 'Team rauswerfen';

  @override
  String get doghouseLeaveTitle => 'Ohne Spielende verlassen?';

  @override
  String doghouseLeaveBodyPts(int count) {
    return 'Das aktuelle Team hat $count ungespeicherte(n) Punkt(e). Beim Verlassen gehen sie verloren.';
  }

  @override
  String get doghouseLeaveBodyEmpty =>
      'Die ungespeicherten Daten des aktuellen Teams gehen verloren.';

  @override
  String get doghouseLeaveAnyway => 'Trotzdem verlassen';

  @override
  String get doghouseTournamentComplete => 'Turnier beendet';

  @override
  String doghouseSummaryStats(int games, int escapes) {
    return '$games Spiel(e) · $escapes Entkommen';
  }

  @override
  String get doghouseFinalStandings => 'Abschlussranking';

  @override
  String doghousePairStat(int escapes, int losses) {
    return '$escapes entkommen · $losses verloren';
  }

  @override
  String get doghousePlayerStats => 'Spielerstatistiken';

  @override
  String get doghouseSessionTimer => 'SITZUNGS-TIMER';

  @override
  String get doghouseGameplayControls => 'Steuerung';

  @override
  String get doghouseMatchControls => 'Spielsteuerung';

  @override
  String get doghouseStartRestart => 'Start / Neu starten';

  @override
  String get doghouseTournamentCompleted => 'Turnier abgeschlossen';

  @override
  String get doghouseNotEnoughInQueue =>
      'Nicht genug Spieler in der Warteschlange.';

  @override
  String get doghouseSuggestedTeam => 'Vorgeschlagenes Team';

  @override
  String doghouseSelectPlayers(int needed, int selected) {
    return '$needed Spieler auswählen ($selected / $needed)';
  }

  @override
  String get doghouseQueueTapToAdd => 'Warteschlange — tippen zum Hinzufügen';

  @override
  String get doghouseEnterDoghouse => 'Doghouse betreten';

  @override
  String get doghouseViewAllGames => 'Alle abgeschlossenen Spiele anzeigen';

  @override
  String doghouseEscapePointsLabel(int count) {
    return '$count Pkt Ausstieg';
  }

  @override
  String doghouseLossLimitLabel(int count) {
    return '$count Verlustlimit';
  }

  @override
  String get doghouseAddPlayerToQueue => 'Spieler zur Warteschlange hinzufügen';

  @override
  String get doghouseUndoCompletion => 'Abschluss rückgängig';

  @override
  String get doghouseSaveAndReturn => 'Speichern und zurück';

  @override
  String get doghouseGameLost => 'Spiel\nVerloren';

  @override
  String get doghouseUndoGame => 'Rückgängig\nSpiel';

  @override
  String get doghouseUndoLastGame => 'Letztes Spiel rückgängig';

  @override
  String get doghouseTournamentSetup => 'Turnier-Einrichtung';

  @override
  String get doghouseTapToAddPlayers => 'Tippen um Spieler hinzuzufügen';

  @override
  String doghouseNPlayersAdded(int count) {
    return '$count Spieler hinzugefügt';
  }

  @override
  String doghouseNeedAtLeastN(int count, int min) {
    return '$count hinzugefügt · mindestens $min benötigt';
  }

  @override
  String get doghouseClearAll => 'Alle löschen';

  @override
  String doghouseFillNRandom(int count) {
    return '$count Zufällige auffüllen';
  }

  @override
  String get doghouseSetupNoPlayers => 'Noch keine Spieler hinzugefügt.';

  @override
  String get doghouseSourceExisting => 'Vorhandener Spieler';

  @override
  String get doghouseSourceNew => 'Neuer Spieler';

  @override
  String get doghouseSourceRandom => 'Zufälliger Platzhalter';

  @override
  String get doghouseTournamentName => 'Turniername';

  @override
  String get doghouseSetupGood => 'Einrichtung sieht gut aus!';

  @override
  String get doghouseSetupIncomplete => 'Einrichtung unvollständig';

  @override
  String get doghouseRemoveAllTitle => 'Alle Spieler entfernen?';

  @override
  String get doghouseRemoveAllBody =>
      'Damit werden alle hinzugefügten Spieler aus der Liste entfernt.';

  @override
  String get doghouseRemoveAll => 'Alle entfernen';

  @override
  String get doghouseAssignmentManual => 'Manuell';

  @override
  String get doghouseAssignmentAutomated => 'Automatisch';

  @override
  String doghouseAddedCount(int added, int total) {
    return 'Hinzugefügt ($added/$total)';
  }
}

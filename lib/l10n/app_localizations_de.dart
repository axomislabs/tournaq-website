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
  String get navTournaments => 'TournaQ Arena';

  @override
  String get navTeams => 'Teams';

  @override
  String get navClubs => 'Gruppen';

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
  String get pageTournaments => 'TournaQ Arena';

  @override
  String get pageClubs => 'Gruppen';

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
  String get btnCreateClub => 'Gruppe erstellen';

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
    return 'Gruppen ($count)';
  }

  @override
  String get hintSearchTeams => 'Teams suchen...';

  @override
  String get hintSearchPlayers => 'Spieler suchen...';

  @override
  String get hintSearchTournaments => 'Turniere suchen...';

  @override
  String get hintSearchClubs => 'Gruppen suchen...';

  @override
  String get filterPlayer => 'Spieler';

  @override
  String get filterTeam => 'Team';

  @override
  String get filterTournament => 'Turnier';

  @override
  String get filterClub => 'Gruppe';

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
  String get comingSoonLearnMore => 'Mehr auf der Website erfahren';

  @override
  String get landingTournamentsSubtitle => 'Turniere & Scrambles verwalten';

  @override
  String get landingAdminSubtitle => 'Spieler, Teams & Gruppen verwalten';

  @override
  String get btnGotIt => 'Verstanden';

  @override
  String get btnLearnMore => 'Mehr erfahren';

  @override
  String get tournamentsSectionQuickGames => 'Schnellspiele';

  @override
  String get tournamentsSectionSingle => 'Einzelwettbewerbe & Socials';

  @override
  String get tournamentsSectionTeam => 'Teamwettbewerbe';

  @override
  String get tournamentsSectionHistory => 'Turnierhistorie';

  @override
  String get modeQuickGamesDesc => 'Ad-hoc gewertete Matches';

  @override
  String get modeSocialScramblesDesc => 'Rotierender Round-Robin-Mixer';

  @override
  String get modeKotcDesc => 'Sieger bleiben, Herausforderer rotieren';

  @override
  String get modeDoghouseDesc => 'Aus dem Doghouse entkommen';

  @override
  String get modeLeagueDesc => 'Punktebasierte Tabelle';

  @override
  String get modeSingleElimDesc => 'Klassisches Knockout-Bracket';

  @override
  String get modeDoubleElimDesc => 'Bracket mit zweiter Chance';

  @override
  String get modeGroupSeDesc => 'Gruppenphase · Single Elimination';

  @override
  String get modeGroupDeDesc => 'Gruppenphase · Double Elimination';

  @override
  String get modeSwissDesc => 'Paarungen nach Punktestand';

  @override
  String get modeLeagueShortDesc =>
      'Tabelle über eine vollständige Round-Robin-Saison mit Punkten, Siegen und Tordifferenz.';

  @override
  String get modeDoubleElimShortDesc =>
      'Gewinner- und Verliererbracket — zwei Niederlagen bedeuten Ausscheiden.';

  @override
  String get modeGroupSeShortDesc =>
      'Teams steigen aus einer Gruppenphase in ein Single-Elimination-Bracket auf.';

  @override
  String get modeGroupDeShortDesc =>
      'Teams steigen aus einer Gruppenphase in ein Double-Elimination-Bracket auf.';

  @override
  String get modeSwissShortDesc =>
      'Spieler werden jede Runde nach Punktestand gepaart — keine Eliminierungen, voller Spielplan.';

  @override
  String get tournamentsDeleteTitle => 'Gesamten Verlauf löschen?';

  @override
  String tournamentsDeleteBody(int count) {
    return 'Dadurch werden alle $count Turniere dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get tournamentsDeleteAll => 'Alles löschen';

  @override
  String get tournamentsAllLabel => 'Alle Turniere';

  @override
  String get tournamentsInfoContent =>
      'Starte ein Match oder führe ein vollständiges Turnier durch — alles an einem Ort.\n\nQuick Games — Gewertete Matches auf der Stelle. Minimaler Aufwand, einfach zwei Teams wählen und loslegen.\n\nEinzelwettbewerbe & Socials — Individuelle Formate, bei denen Spieler als sie selbst antreten und rotieren.\n\nTeamwettbewerbe — Teambasierte Formate, bei denen vorgefertigte Teams in einem Bracket oder einer Tabelle gegeneinander antreten.\n\nTippe auf Info bei einer Kachel, um mehr zu erfahren.';

  @override
  String get landingQuickStartSubtitle => 'Beach-Volleyball-Match';

  @override
  String get landingMatchHistoryTitle => 'Spielhistorie';

  @override
  String get landingMatchHistorySubtitle =>
      'Vergangene Spiele ansehen und überprüfen';

  @override
  String get landingMoreTournamentTitle => 'Weitere Turnierfunktionen';

  @override
  String get landingMoreTournamentSub =>
      'Zusätzliche Formate, Brackets und Wettbewerbsstrukturen.';

  @override
  String get landingDeviceScalabilityTitle => 'Geräte- & Bildschirmskalierung';

  @override
  String get landingDeviceScalabilitySub =>
      'Optimierte Layouts für Tablets, Web und alle Bildschirmgrößen.';

  @override
  String get landingScorecardSharingTitle =>
      'Scorekarten teilen & Turnierskalierung';

  @override
  String get landingScorecardSharingSub =>
      'Ergebnisse teilen und größere Events und Gruppen unterstützen.';

  @override
  String get landingLiveTournamentTitle => 'Live-Turnierfunktionen';

  @override
  String get landingLiveTournamentSub =>
      'Echtzeit-Spielstand, Tabellen und Live-Event-Updates.';

  @override
  String get landingAdvancedAdminTitle => 'Erweiterte Benutzerverwaltung';

  @override
  String get landingAdvancedAdminSub =>
      'Spieler, Teams, Gruppen und Veranstalterrollen verwalten.';

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
      'Zukünftige Partner, Gruppen und Organisationen können hier vorgestellt werden.';

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
  String get contactUserGuide => 'Feature-Übersicht';

  @override
  String get contactUserGuideSub =>
      'Alle Modi und Features auf der Website entdecken';

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
  String get dialogRemoveFromClub => 'Aus Gruppe entfernen';

  @override
  String get dialogRemoveFromClubBody =>
      'Dieses Team aus der Gruppe entfernen?';

  @override
  String get menuEditPlayers => 'Spieler bearbeiten';

  @override
  String get menuAssignToTournament => 'Zu Turnier hinzufügen';

  @override
  String get menuAssignToClub => 'Zu Gruppe hinzufügen';

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
  String get menuAddToClub => 'Zu Gruppe hinzufügen';

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
  String get noClubsYet => 'Noch keine Gruppen.';

  @override
  String get noClubsFiltered =>
      'Keine Gruppen entsprechen den aktuellen Filtern.';

  @override
  String get noScoringHistoryYet => 'Noch keine Spielhistorie';

  @override
  String get noPlayersInTeam => 'Noch keine Spieler.';

  @override
  String get noTournamentsInTeam => 'Noch in keinen Turnieren.';

  @override
  String get noClubsInTeam => 'Noch in keinen Gruppen.';

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
  String get pageClubDetails => 'Gruppendetails';

  @override
  String get playerNotFound => 'Spieler nicht gefunden.';

  @override
  String get clubNotFound => 'Gruppe nicht gefunden.';

  @override
  String get dialogRemoveFromTeam => 'Aus Team entfernen';

  @override
  String get dialogRemoveFromTeamBody =>
      'Diesen Spieler aus dem Team entfernen?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      'Diesen Spieler aus der Gruppe entfernen?';

  @override
  String get dialogRemoveTournamentFromClub => 'Turnier entfernen';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      'Dieses Turnier aus der Gruppe entfernen?';

  @override
  String get notAssignedToTeams => 'Keinem Team zugeordnet.';

  @override
  String get notAssignedToClubs => 'Keiner Gruppe zugeordnet.';

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
  String get hintClubName => 'Gruppenname';

  @override
  String get labelAssignToTeams => 'Teams zuweisen';

  @override
  String get labelAssignToClubs => 'Gruppen zuweisen';

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
  String get scopeClub => 'Gruppe';

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
  String get filterAllClubs => 'Alle Gruppen';

  @override
  String get noTeamsInClub => 'Keine Teams in dieser Gruppe.';

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
  String get labelClubForRandomTeams => 'Gruppe für zufällige Teams';

  @override
  String get radioNoClub => 'Keine Gruppe';

  @override
  String get radioAddToExistingClub => 'Zu vorhandener Gruppe hinzufügen';

  @override
  String get hintSelectClub => 'Gruppe auswählen';

  @override
  String get radioCreateNewClub => 'Neue Gruppe erstellen';

  @override
  String get hintClubNameRandom => 'Gruppenname (leer lassen für Zufall)';

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
      'Das Turnier ist bereits in allen Gruppen.';

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
  String get notInAnyClubsYet => 'Noch in keiner Gruppe.';

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

  @override
  String statsRounds(int count) {
    return '$count Runden';
  }

  @override
  String statsPtsScored(int total) {
    return '$total Pkt. erzielt';
  }

  @override
  String statsTeams(int count) {
    return '$count Teams';
  }

  @override
  String statsCourts(int count) {
    return '$count Felder';
  }

  @override
  String statsMatchesOf(int completed, int total) {
    return '$completed / $total Spiele';
  }

  @override
  String statsGamesOf(int completed, int total) {
    return '$completed/$total Spiele';
  }

  @override
  String get setupDuplicateNameTitle => 'Doppelter Name';

  @override
  String setupDuplicateNameBody(String name) {
    return '\"$name\" ist bereits hinzugefügt. Trotzdem hinzufügen?';
  }

  @override
  String get btnAddAnyway => 'Trotzdem hinzufügen';

  @override
  String get setupSectionPlayers => 'Spieler';

  @override
  String get setupSectionCreatePlayer => 'Spieler erstellen';

  @override
  String setupAddExistingPlayers(int count) {
    return 'Vorhandene Spieler hinzufügen ($count)';
  }

  @override
  String get setupSearchPlayersHint => 'Spieler suchen…';

  @override
  String get setupPlayerNameHint => 'Spielername';

  @override
  String setupPlayersOf(int count, int target) {
    return '$count/$target Spieler hinzugefügt';
  }

  @override
  String get setupTargetPlayers => 'Anzahl Spieler';

  @override
  String get setupAvailableTime => 'Verfügbare Zeit';

  @override
  String get setupMatchDuration => 'Matchdauer';

  @override
  String get setupCourts => 'Felder';

  @override
  String get setupBreakBetweenRounds => 'Pause zwischen Runden';

  @override
  String get setupFormat => 'Format';

  @override
  String get setupPlannedStartTime => 'Geplante Startzeit';

  @override
  String get setupPlannedEndTime => 'Geplante Endzeit';

  @override
  String get setupSchedulePreview => 'Zeitplan-Vorschau';

  @override
  String get setupRoundDuration => 'Rundendauer';

  @override
  String get setupRoundsLabel => 'Runden';

  @override
  String get setupScheduledDuration => 'Geplante Dauer';

  @override
  String get setupScheduledEndTime => 'Geplantes Ende';

  @override
  String get setupSuggestions => 'Vorschläge';

  @override
  String get setupFormatAutoAllplay => 'Auto-Allplay';

  @override
  String get setupCourtsInfoBody =>
      'Derzeit auf 1 Feld festgelegt.\n\nMehrf-Feld-Unterstützung — mehrere simultane Felder zuweisen und verfolgen mit optimaler Rotation — ist für eine zukünftige Version geplant.';

  @override
  String get setupSeedingRandom => 'Zufällig';

  @override
  String get setupSeedingSeeded => 'Gesetzt';

  @override
  String get setupOddTeamsByes => 'Freilos';

  @override
  String get setupOddTeamsPlayIn => 'Play-in';

  @override
  String get setupSectionTeams => 'Teams';

  @override
  String get setupRemoveAllTeamsTitle => 'Alle Teams entfernen?';

  @override
  String get setupRemoveAllTeamsBody =>
      'Damit werden alle hinzugefügten Teams aus der Liste entfernt.';

  @override
  String get setupNoTeamsMatch => 'Keine Teams gefunden.';

  @override
  String get setupNoTeamsAddedYet => 'Noch keine Teams hinzugefügt.';

  @override
  String get setupTeamNameHint => 'Teamname';

  @override
  String setupAddExistingTeams(int count) {
    return 'Vorhandene Teams hinzufügen ($count)';
  }

  @override
  String get setupSearchTeamsHint => 'Teams suchen…';

  @override
  String get setupCreateTeam => 'Team erstellen';

  @override
  String get setupGeneration => 'Auslosung';

  @override
  String get setupOddTeamsLabel => 'Ungerade Teams';

  @override
  String get setupEarlyRounds => 'Vorrunden';

  @override
  String get setupFinalRounds => 'Endrunden';

  @override
  String get setupReadyToStart => 'Bereit loszulegen!';

  @override
  String setupAddAllTeams(int count) {
    return 'Füge alle $count Teams hinzu, um fortzufahren';
  }

  @override
  String get setupTapToAddTeams => 'Tippe um Teams hinzuzufügen';

  @override
  String setupTeamsOf(int count, int target) {
    return '$count/$target Teams hinzugefügt';
  }

  @override
  String get overviewSectionOverview => 'Übersicht';

  @override
  String get overviewSectionSchedule => 'Zeitplan';

  @override
  String overviewGamesCompleted(int completed, int total) {
    return '$completed / $total Spiele abgeschlossen';
  }

  @override
  String overviewStatsSummary(int rounds, int courts, int players) {
    return '$rounds Runden  ·  $courts Felder  ·  $players Spieler';
  }

  @override
  String overviewFinished(String time) {
    return 'Beendet: $time';
  }

  @override
  String overviewEstFinish(String time) {
    return 'Voraus. Ende: $time';
  }

  @override
  String overviewSectionPlayers(int count) {
    return 'Spieler ($count)';
  }

  @override
  String get overviewAddPlayerSubtitle =>
      'Hinzugefügte Spieler nehmen als Späteinsteiger teil.';

  @override
  String overviewAddConfirm(String name) {
    return '$name hinzufügen?';
  }

  @override
  String overviewAddLateBody(String name) {
    return '$name nimmt als Späteinsteiger teil. Die verbleibenden Paarungen werden neu ausgelost — einige Spieler erhalten möglicherweise unterschiedlich viele Spiele.';
  }

  @override
  String overviewSwapTitle(String name) {
    return '$name ersetzen';
  }

  @override
  String overviewSwapSubtitle(String name) {
    return '$name wird aus den weiteren Runden entfernt.';
  }

  @override
  String overviewEjectTitle(String name) {
    return '$name ausschließen?';
  }

  @override
  String overviewEjectBody(String name) {
    return '$name wird aus allen weiteren Runden entfernt. Die verbleibenden Paarungen werden neu ausgelost — einige Spieler erhalten möglicherweise unterschiedlich viele Spiele. Abgeschlossene Spiele bleiben in der Statistik.';
  }

  @override
  String get overviewEjectBtn => 'Ausschließen';

  @override
  String get overviewEditPlayer => 'Spieler bearbeiten';

  @override
  String get overviewAllPlayersAlready =>
      'Alle vorhandenen Spieler sind bereits in diesem Turnier.';

  @override
  String overviewRound(int number) {
    return 'Runde $number';
  }

  @override
  String get overviewActual => 'tatsächlich';

  @override
  String overviewBreakUntil(String time) {
    return '· Pause bis $time';
  }

  @override
  String get scrambleStatusSwappedOut => 'ausgetauscht';

  @override
  String get scrambleStatusSwappedIn => 'Einwechslung';

  @override
  String get scrambleStatusLate => 'spät';

  @override
  String get tooltipEdit => 'Bearbeiten';

  @override
  String get tooltipEject => 'Ausschließen';

  @override
  String get tooltipSwap => 'Ersetzen';

  @override
  String get tooltipRankings => 'Spielerwertung';

  @override
  String get scorecardSwapSides => 'Seiten tauschen';

  @override
  String get scorecardSwapSidesSubtitle => 'Links-Rechts-Anzeige tauschen';

  @override
  String get scorecardMatchHistory => 'Spielverlauf';

  @override
  String get scorecardMatchHistorySubtitle => 'Punkt-für-Punkt-Verlauf';

  @override
  String get scorecardPlannedStart => 'Geplanter Start';

  @override
  String get scorecardPlannedEnd => 'Geplantes Ende';

  @override
  String get scorecardEnd => 'Ende';

  @override
  String get scorecardOverSchedule => 'Überzogen!';

  @override
  String get scorecardOverScheduleHurry => 'Überzogen · Beeilung!';

  @override
  String scorecardStartsServing(String name) {
    return '$name beginnt mit Aufschlag';
  }

  @override
  String get scorecardUndoCompletion => 'Abschluss rückgängig';

  @override
  String get scorecardStartMatch => 'Spiel starten';

  @override
  String get scorecardCompleteGame => 'Spiel abschließen';

  @override
  String get scorecardManualScore => 'Score manuell eingeben';

  @override
  String get scorecardBackToSchedule => 'Zurück zum Zeitplan';

  @override
  String get scorecardManualScoreBlockedTitle =>
      'Manuelle Eingabe nicht verfügbar';

  @override
  String get scorecardManualScoreBlockedBody =>
      'Manuelle Score-Eingabe ist nur verfügbar, bevor die Live-Wertung gestartet hat. Das verhindert das versehentliche Überschreiben bereits erfasster Punkte.';

  @override
  String get scorecardManualScoreDescription =>
      'Verwende dies, wenn das Spiel ohne Live-Wertung gespielt wurde. Gib den Endstand für beide Seiten ein und schließe das Spiel ab.';

  @override
  String get btnOK => 'OK';

  @override
  String get btnAdjustFinalScore => 'Endergebnis anpassen';

  @override
  String get btnRestart => 'Neustart';

  @override
  String get btnResume => 'Fortsetzen';

  @override
  String get btnApply => 'Übernehmen';

  @override
  String labelMinutes(int n) {
    return '$n min';
  }

  @override
  String get matchScorecard => 'Anzeigetafel';

  @override
  String get matchOptions => 'Spieloptionen';

  @override
  String get matchViewHistory => 'Punkt-für-Punkt-Verlauf anzeigen';

  @override
  String get matchComplete => 'Spiel abgeschlossen';

  @override
  String get matchSetCompleteBanner =>
      'Satz abgeschlossen — vor nächstem Satz bestätigen';

  @override
  String matchSuggestedToServe(String name) {
    return '$name schlägt vor zu beginnen';
  }

  @override
  String matchSuggestedReferee(String name) {
    return '$name als Schiedsrichter vorgeschlagen';
  }

  @override
  String get matchAssignRefereeManually => 'Schiedsrichter manuell zuweisen';

  @override
  String get matchScoresTiedSet =>
      'Gleichstand — ein Satz kann nicht unentschieden enden.';

  @override
  String get matchScoresTiedMatch =>
      'Gleichstand — es muss ein Gewinner festgestellt werden.';

  @override
  String get matchSetsTied =>
      'Sätze sind unentschieden — es muss ein Gewinner bestimmt werden.';

  @override
  String get matchUndoSet => 'Satz rückgängig';

  @override
  String get matchCompleteSet => 'Satz abschließen';

  @override
  String get matchUndoMatchCompletion => 'Spielabschluss rückgängig';

  @override
  String get matchCompleteMatch => 'Spiel abschließen';

  @override
  String get matchSetScoreManually => 'Ergebnis manuell eingeben';

  @override
  String get matchBackToBracket => 'Zurück zum Bracket';

  @override
  String matchCourtLabel(int court) {
    return 'Platz $court';
  }

  @override
  String matchStartsAt(String time) {
    return 'Startet $time';
  }

  @override
  String matchSetNScore(int n) {
    return 'Satz $n Ergebnis';
  }

  @override
  String get matchSetScore => 'Ergebnis eingeben';

  @override
  String get bracketWithdrawTitle => 'Team zurückziehen?';

  @override
  String bracketWithdrawBody(String name) {
    return '\"$name\" zurückziehen? Ihre ausstehenden Spiele werden als Walkover gewertet.';
  }

  @override
  String get bracketWithdrawBtn => 'Zurückziehen';

  @override
  String get bracketFinalRoundsFormat => 'Format: Finale Runden';

  @override
  String get bracketEarlyRoundsFormat => 'Format: Frühe Runden';

  @override
  String bracketFinalRoundsAppliesTo(int n) {
    return 'Gilt für die letzten $n Runde(n)';
  }

  @override
  String get bracketEarlyRoundsAppliesTo => 'Gilt für alle frühen Runden';

  @override
  String get setupSetsPerGame => 'Sätze pro Spiel';

  @override
  String get setupPointsPerSet => 'Punkte pro Satz';

  @override
  String get bracketBreakFinalRounds => 'Pause — Finale Runden';

  @override
  String get bracketBreakEarlyRounds => 'Pause — Frühe Runden';

  @override
  String get bracketNoBreak => 'Keine Pause';

  @override
  String get bracketNoStartTime => 'Keine Startzeit festgelegt';

  @override
  String bracketStartsLabel(String label) {
    return 'Start: $label';
  }

  @override
  String get bracketTournamentWinner => 'Turniersieger';

  @override
  String bracketSectionTeams(int count) {
    return 'Teams ($count)';
  }

  @override
  String get bracketSwapTeamTitle => 'Team tauschen';

  @override
  String bracketSwapTeamSubtitle(String name) {
    return 'Ersetzt \"$name\" in allen ausstehenden Spielen.';
  }

  @override
  String get bracketSearchTeams => 'Teams suchen…';

  @override
  String get bracketNoTeamsInHub => 'Noch keine Teams im Teams-Hub.';

  @override
  String get bracketAllTeamsInTournament =>
      'Alle Hub-Teams sind bereits in diesem Turnier.';

  @override
  String get scorecardMatchTimerLabel => 'Spieltimer';

  @override
  String get scorecardUpcomingGames => 'Nächste Spiele';

  @override
  String scorecardPlayerCount(int n) {
    return '$n Spieler';
  }

  @override
  String get scorecardGameCompletedLock =>
      'Spiel abgeschlossen — Rückgängig zum Bearbeiten';

  @override
  String get kotcTimeIsUp => 'Zeit ist abgelaufen';

  @override
  String get kotcSessionEndedBody =>
      'Der Sitzungstimer ist abgelaufen. Turnier jetzt abschließen?';

  @override
  String kotcSubstituteTitle(String name) {
    return '$name ersetzen';
  }

  @override
  String kotcSubstituteBody(String name) {
    return '$name kehrt in die Warteschlange zurück.';
  }

  @override
  String get kotcAddLateTitle => 'Spieler nachträglich hinzufügen?';

  @override
  String get kotcAddLateBody =>
      'Dieser Spieler kommt zu spät und hatte nicht die gleichen Chancen wie Spieler, die von Anfang an dabei waren. Seine Statistiken werden als \"Spät\" markiert.';

  @override
  String get btnContinue => 'Weiter';

  @override
  String get kotcLateTag => 'SPÄT';

  @override
  String get kotcAdminTag => 'ADMIN';

  @override
  String get kotcChangeAdmin => 'Admin wechseln';

  @override
  String get kotcChangeAdminSubtitle =>
      'Wähle, wer den Spielstand führt. Der aktuelle Admin kehrt in die Warteschlange zurück.';

  @override
  String get kotcNextAdmin => 'NÄCHSTER ADMIN';

  @override
  String get kotcNextAdminNote => 'Vorschlag aus dem aktuellen Hofteam.';

  @override
  String get kotcGameWon => 'Spiel gewonnen!';

  @override
  String kotcReachedPoints(String names, int points) {
    return '$names hat $points Punkte erreicht!';
  }

  @override
  String get kotcEjectReturn =>
      'Sie werden ausgeschlossen und kehren in die Warteschlange zurück.';

  @override
  String get kotcEjectTeamTitle => 'Team ausschließen?';

  @override
  String kotcEjectTeamBodyPoints(int pts) {
    return 'Das aktuelle Team wird ausgeschlossen. Ihre $pts Punkte werden gespeichert.';
  }

  @override
  String get kotcEjectTeamBodyNoPoints =>
      'Das aktuelle Team wird ausgeschlossen und kehrt in die Warteschlange zurück.';

  @override
  String get kotcLeaveTitle => 'Verlassen ohne auszuschließen?';

  @override
  String kotcLeaveBodyPoints(int pts) {
    return 'Das Team hat $pts nicht gespeicherte Punkte. Beim Verlassen gehen sie verloren. Schließe das Team zuerst aus, um den Spielstand zu speichern.';
  }

  @override
  String get kotcTournamentComplete => 'Turnier abgeschlossen';

  @override
  String kotcGamesSummary(int games, int pts) {
    return '$games Spiele · $pts Punkte gesamt';
  }

  @override
  String get kotcStatGames => 'Spiele';

  @override
  String get kotcStatWins => 'Siege';

  @override
  String get kotcStatPts => 'Pkt';

  @override
  String get kotcOptions => 'Optionen';

  @override
  String get kotcHistorySubtitle => 'Alle abgeschlossenen Spiele anzeigen';

  @override
  String get kotcTeamEjected => 'Team\nraus';

  @override
  String get kotcUndoEject => 'Ausschluss\nrückgängig';

  @override
  String get kotcUndoLastEjection => 'Letzten Ausschluss rückgängig';

  @override
  String get kotcUpNext => 'Als Nächstes';

  @override
  String get kotcChallengers => 'Herausforderer';

  @override
  String get kotcWaitingForPlayers => 'Warte auf Spieler...';

  @override
  String kotcStrikePoints(int n) {
    return '$n Pkt. Strike';
  }

  @override
  String get kotcAdd4Random => '4 zufällige hinzufügen';

  @override
  String kotcExistingPlayers(int n) {
    return 'Bestehende Spieler ($n)';
  }

  @override
  String get kotcPlayerNameHint => 'Spielername';

  @override
  String get labelEject => 'Ausschließen';

  @override
  String get kotcSetupStyleLabel => 'Stil';

  @override
  String get kotcSetupStyleHelp =>
      'Das Format jedes Spiels — 2vs2, 3vs3 usw. Legt fest, wie viele Spieler jedes Team auf dem Platz ausmachen.';

  @override
  String get kotcSetupAssignmentLabel => 'Zuweisung';

  @override
  String get kotcSetupAssignmentHelp =>
      'Wie das nächste Hofteam ausgewählt wird.\n\nManuell — der Trainer wählt Spieler aus der Warteschlange durch Antippen.\n\nAutomatisch — TournaQ schlägt das beste Team vor und priorisiert Spieler, die am längsten gewartet haben und zuletzt nicht zusammen gespielt haben. Der Trainer kann vor der Bestätigung neu würfeln.\n\nAutomatisch — Alle spielen — wie Automatisch, aber ohne dedizierten Trainer. Ein rotierender Admin führt den Spielstand, während alle anderen spielen.';

  @override
  String get kotcSetupPlayersHelp =>
      'Zielvorgabe für die Spieleranzahl. Wird beim automatischen Auffüllen mit zufälligen Spielern verwendet. Tatsächliche Teilnehmer werden unten im Bereich Spieler hinzugefügt.';

  @override
  String get kotcSetupTimeHelp =>
      'Gesamte Sitzungsdauer. Der Timer zählt von diesem Wert herunter. Wenn die Zeit abläuft, wirst du aufgefordert, das Turnier abzuschließen oder weiterzuspielen.';

  @override
  String get kotcSetupStrikeLabel => 'Strike-Punkte (0 = aus)';

  @override
  String get kotcSetupStrikeHelp =>
      'Punkte, die ein Team erzielen muss, um das Spiel zu gewinnen und als Sieger ausgeschlossen zu werden. Auf 0 setzen zum Deaktivieren — Teams bleiben auf dem Platz, bis der Coach sie manuell ausschließt.';

  @override
  String get kotcHistoryWon => 'Gewonnen';

  @override
  String get kotcHistoryNoGames => 'Noch keine Spiele.';

  @override
  String get kotcHistoryNoGamesSubtitle =>
      'Spiele erscheinen hier, sobald ein Team ausgeschlossen wird.';

  @override
  String get setupPlayersPerSide => 'Spieler pro Seite';

  @override
  String get setupAppliesToLast => 'Gilt für letzte';

  @override
  String get setupScheduleLabel => 'Zeitplan';

  @override
  String get setupScheduleSoft => 'Flexibler Zeitplan';

  @override
  String get setupScheduleForced => 'Fester Zeitplan';

  @override
  String get setupAddBreak => 'Pause hinzufügen';

  @override
  String setupBreakMins(int mins) {
    return '$mins Min. Pause';
  }

  @override
  String setupStartsAt(String date) {
    return 'Start: $date';
  }

  @override
  String setupMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele',
      one: '1 Spiel',
    );
    return '$_temp0';
  }

  @override
  String get setupRoundPlayIn => 'Play-in';

  @override
  String get setupRoundFinal => 'Finale';

  @override
  String get setupRoundSemiFinal => 'Halbfinale';

  @override
  String get setupRoundQuarterFinal => 'Viertelfinale';

  @override
  String setupRoundN(int n) {
    return 'Runde $n';
  }
}

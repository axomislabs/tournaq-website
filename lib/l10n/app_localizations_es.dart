// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'TournaQ';

  @override
  String get appTagline => 'Marcador, Partidos y Torneos';

  @override
  String get navHome => 'Inicio';

  @override
  String get navQuickStart => 'Partido Rápido';

  @override
  String get navTournaments => 'Torneos';

  @override
  String get navTeams => 'Equipos';

  @override
  String get navClubs => 'Clubes';

  @override
  String get navPlayers => 'Jugadores';

  @override
  String get navAdmin => 'Administración';

  @override
  String get navSponsoring => 'Patrocinio y Promo';

  @override
  String get navContact => 'Contacto e Info';

  @override
  String get pageGames => 'Partidos';

  @override
  String get pageTeams => 'Equipos';

  @override
  String get pagePlayers => 'Jugadores';

  @override
  String get pageTournaments => 'Torneos';

  @override
  String get pageClubs => 'Clubes';

  @override
  String get pageGameScorecard => 'Marcador';

  @override
  String get pageGameplayHistory => 'Historial de Partidos';

  @override
  String get pageTeamDetails => 'Detalles del Equipo';

  @override
  String get btnStartGame => 'Iniciar Partido';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get btnCreate => 'Crear';

  @override
  String get btnRemove => 'Eliminar';

  @override
  String get btnSave => 'Guardar';

  @override
  String get btnOk => 'OK';

  @override
  String get btnDelete => 'Eliminar';

  @override
  String get btnAssign => 'Asignar';

  @override
  String get btnGiveFeedback => 'Enviar comentarios';

  @override
  String get btnEmailUs => 'Enviar correo electronico';

  @override
  String get btnRateTournaQ => 'Valorar TournaQ';

  @override
  String get btnNotNow => 'Ahora No';

  @override
  String get btnSaveAndReturn => 'Guardar y Volver a Partidos';

  @override
  String get btnCreateTeam => 'Crear Equipo';

  @override
  String get btnCreatePlayer => 'Crear Jugador';

  @override
  String get btnCreateTournament => 'Crear Torneo';

  @override
  String get btnCreateClub => 'Crear Club';

  @override
  String get btnSavePlayers => 'Guardar Jugadores';

  @override
  String get btnDeleteHistory => 'Eliminar';

  @override
  String get btnGenerate10RandomTeams => 'Generar 10 Equipos Aleatorios';

  @override
  String get btnGenerate10RandomPlayers => 'Generar 10 Jugadores Aleatorios';

  @override
  String get quickStartTitle => 'Partido Rapido';

  @override
  String get quickStartFormatQuestion => '¿Cuánto dura el partido?';

  @override
  String get quickStartTeamQuestion => '¿Cómo quieres elegir los equipos?';

  @override
  String get formatOneSet => 'Un Set';

  @override
  String get formatOneSetSubtitle => 'Un set para decidir el ganador';

  @override
  String get formatBestOfThree => 'Mejor de Tres Sets';

  @override
  String get formatBestOfThreeSubtitle =>
      'El primero en ganar dos sets gana el partido';

  @override
  String get teamMethodExisting => 'Seleccionar Equipos Existentes';

  @override
  String get teamMethodNew => 'Crear Nuevos Equipos';

  @override
  String get teamMethodRandom => 'Generar Equipos Aleatorios';

  @override
  String get quickStartSelectTeam1 => 'Seleccionar Equipo 1';

  @override
  String get quickStartSelectTeam2 => 'Seleccionar Equipo 2';

  @override
  String get quickStartTeam1Name => 'Nombre Equipo 1';

  @override
  String get quickStartTeam2Name => 'Nombre Equipo 2';

  @override
  String get quickStartBack => 'Atrás';

  @override
  String get quickStartReRoll => 'Regenerar Equipos';

  @override
  String get sectionMatchHistory => 'Historial de Partidos';

  @override
  String get sectionGameplayControls => 'Controles de Juego';

  @override
  String get sectionMatchActions => 'Acciones del Partido';

  @override
  String get sectionSponsoring => 'Patrocinio';

  @override
  String get sectionOpportunities => 'Oportunidades';

  @override
  String get sectionGetInvolved => 'Participa';

  @override
  String sectionTeamsCount(int count) {
    return 'Equipos ($count)';
  }

  @override
  String sectionPlayersCount(int count) {
    return 'Jugadores ($count)';
  }

  @override
  String sectionTournamentsCount(int count) {
    return 'Torneos ($count)';
  }

  @override
  String sectionClubsCount(int count) {
    return 'Clubes ($count)';
  }

  @override
  String get hintSearchTeams => 'Buscar equipos...';

  @override
  String get hintSearchPlayers => 'Buscar jugadores...';

  @override
  String get hintSearchTournaments => 'Buscar torneos...';

  @override
  String get hintSearchClubs => 'Buscar clubes...';

  @override
  String get filterPlayer => 'Jugador';

  @override
  String get filterTeam => 'Equipo';

  @override
  String get filterTournament => 'Torneo';

  @override
  String get filterClub => 'Club';

  @override
  String get filterMode => 'Modo';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterSource => 'Origen';

  @override
  String get sideChangeTitle => 'Cambio de Lado';

  @override
  String get sideChangeBody => 'Los equipos deben cambiar de lado ahora.';

  @override
  String sideChangeBodyWithScore(int score) {
    return 'Marcador total: $score.\n\nLos equipos deben cambiar de lado ahora.';
  }

  @override
  String get sideChangeContinue => 'Lados Cambiados — Continuar';

  @override
  String get scoreGameOptions => 'Opciones de Partido';

  @override
  String get scoreSwapTeams => 'Cambiar Equipos';

  @override
  String get scoreSwapSubtitle => 'Intercambiar lados izquierdo y derecho';

  @override
  String get scoreChangeService => 'Cambiar Servicio';

  @override
  String get scoreChangeServiceSubtitle => 'Pasar al siguiente servidor';

  @override
  String get scoreGameplayHistory => 'Historial de Juego';

  @override
  String get scoreGameplayHistorySubtitle => 'Línea de tiempo punto a punto';

  @override
  String get scoreHistoryCompact => 'Historial';

  @override
  String get scoreTargetScore => 'Puntos objetivo:';

  @override
  String get scoreLockBannerGameComplete =>
      'Partido completado — deshaz la finalización para editar puntos';

  @override
  String get scoreLockBannerSetComplete =>
      'Set completado — deshaz la finalización para editar puntos';

  @override
  String get scoreTooltipDecrease => 'Disminuir';

  @override
  String get scoreTooltipIncrease => 'Aumentar';

  @override
  String get gameStatusCompleted => 'Completado';

  @override
  String get gameStatusInProgress => 'En Progreso';

  @override
  String get gameStatusPending => 'Pendiente';

  @override
  String get gameMenuScorecard => 'Marcador';

  @override
  String get gameMenuDelete => 'Eliminar Partido';

  @override
  String get gameTileQuick => 'Rápido';

  @override
  String setHeader(int n, int target) {
    return 'Set $n  ·  a $target';
  }

  @override
  String setFinalScore(int s1, int s2) {
    return 'Final: $s1 – $s2';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get comingSoonLabel => 'PRÓXIMAMENTE';

  @override
  String get comingSoonBody =>
      'Tu opinión puede ayudar a dar forma a esta función antes de su lanzamiento.';

  @override
  String get landingQuickStartSubtitle => 'Partido de Vóley Playa';

  @override
  String get landingMatchHistoryTitle => 'Historial de Partidos';

  @override
  String get landingMatchHistorySubtitle => 'Ver y revisar partidos anteriores';

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
  String get promoSupportTitle => 'Apoya TournaQ';

  @override
  String get promoSupportSubtitle =>
      'La publicidad y el patrocinio ayudan a financiar el desarrollo continuo de TournaQ.';

  @override
  String get promoFollowTitle => 'Sigue el Viaje';

  @override
  String get promoFollowSubtitle =>
      'Comparte eventos y partidos donde TournaQ te ayudó — etiquétanos en Instagram.';

  @override
  String get promoRateTitle => '¿Disfrutas TournaQ?';

  @override
  String get promoRateSubtitle =>
      'Tu valoración nos ayuda a crecer y mejorar TournaQ.';

  @override
  String get promoHelpTitle => 'Ayuda a Dar Forma a TournaQ';

  @override
  String get promoHelpSubtitle =>
      'Agradecemos sugerencias e ideas para futuras funciones y colaboraciones.';

  @override
  String get promoAdPlaceholder => 'Publicidad';

  @override
  String get promoAdNotSupported => 'Publicidad disponible en iOS y Android';

  @override
  String get promoAdThankYou => 'Gracias por apoyar TournaQ.';

  @override
  String get promoPartnerSpotlight => 'Foco en Socios';

  @override
  String get promoPartnerSpotlightSub =>
      'Futuros socios, clubes y organizaciones podrían aparecer aquí.';

  @override
  String get promoTournamentPartnerships => 'Asociaciones de Torneos';

  @override
  String get promoTournamentPartnershipsSub =>
      'Apoyo para organizadores de torneos y asociaciones de eventos.';

  @override
  String get promoPromoteEvent => 'Promociona tu Evento';

  @override
  String get promoPromoteEventSub =>
      'Futuras oportunidades para mostrar torneos, ligas y eventos.';

  @override
  String get contactInstagram => 'Instagram';

  @override
  String get contactInstagramHandle => '@tournaq';

  @override
  String get contactSectionSocial => 'Social';

  @override
  String get contactSectionSupport => 'Contacto y Soporte';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactFeedbackForm => 'Formulario de Opinión';

  @override
  String get contactFeedbackSubtitle =>
      'Opiniones, errores y solicitudes de funciones';

  @override
  String get contactWebsite => 'Sitio Web';

  @override
  String get contactWebsiteSubtitle => 'Visita nuestra web';

  @override
  String get contactSectionLegal => 'Legal';

  @override
  String get contactPrivacyPolicy => 'Política de Privacidad';

  @override
  String get contactPrivacyPolicySub => 'Cómo gestionamos tus datos';

  @override
  String get contactTermsOfUse => 'Términos de Uso';

  @override
  String get contactTermsOfUseSub => 'Reglas para usar TournaQ';

  @override
  String get contactLegalNotice => 'Aviso Legal';

  @override
  String get contactLegalNoticeSub =>
      'Información del desarrollador y la app (UE)';

  @override
  String get contactPrivacyOptions => 'Opciones de Privacidad';

  @override
  String get contactPrivacyOptionsSub =>
      'Gestionar preferencias de consentimiento de anuncios';

  @override
  String get contactSectionResources => 'Recursos';

  @override
  String get contactUserGuide => 'Guía de Usuario';

  @override
  String get contactUserGuideSub => 'Tutoriales y guías prácticas';

  @override
  String get contactLegalHub => 'Documentación Legal';

  @override
  String get contactLegalHubSub => 'Privacidad, condiciones y aviso legal';

  @override
  String get ratingDialogBody =>
      'Una valoración rápida nos ayuda a llegar a más jugadores y organizadores de torneos.';

  @override
  String get deleteHistoryTitle => '¿Eliminar Todo el Historial?';

  @override
  String get deleteHistoryBody =>
      'Esto eliminará permanentemente todos los registros locales de partidos. Esta acción no se puede deshacer.';

  @override
  String dialogDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get dialogDeleteBody => 'Esta acción no se puede deshacer.';

  @override
  String get dialogRemovePlayer => 'Eliminar Jugador';

  @override
  String get dialogRemovePlayerBody => '¿Eliminar este jugador del equipo?';

  @override
  String get dialogRemoveFromTournament => 'Eliminar del Torneo';

  @override
  String get dialogRemoveFromTournamentBody =>
      '¿Eliminar este equipo del torneo?';

  @override
  String get dialogRemoveFromClub => 'Eliminar del Club';

  @override
  String get dialogRemoveFromClubBody => '¿Eliminar este equipo del club?';

  @override
  String get menuEditPlayers => 'Editar Jugadores';

  @override
  String get menuAssignToTournament => 'Añadir a Torneo';

  @override
  String get menuAssignToClub => 'Añadir a Club';

  @override
  String get menuAssignToTeam => 'Añadir a Equipo';

  @override
  String get menuAssignPlayer => 'Asignar Jugador';

  @override
  String get menuAssignTeam => 'Asignar Equipo';

  @override
  String get menuAssignTournament => 'Asignar Torneo';

  @override
  String get menuGenerateGames => 'Generar Partidos';

  @override
  String get menuAddToTournament => 'Añadir a Torneo';

  @override
  String get menuAddToClub => 'Añadir a Club';

  @override
  String get noGamesYet => 'Aún no hay partidos';

  @override
  String get noGamesYetSubtitle => 'Empieza a puntuar para registrar el juego.';

  @override
  String get noGamesYetHint => 'Usa Inicio Rápido arriba o crea un torneo.';

  @override
  String get noGamesFiltered =>
      'Ningún partido coincide con los filtros actuales';

  @override
  String get noGamesFilteredHint => 'Intenta borrar algunos filtros.';

  @override
  String get noTeamsYet => 'Aún no hay equipos.';

  @override
  String get noTeamsFiltered =>
      'Ningún equipo coincide con los filtros actuales.';

  @override
  String get noPlayersYet => 'Aún no hay jugadores.';

  @override
  String get noPlayersFiltered =>
      'Ningún jugador coincide con los filtros actuales.';

  @override
  String get noTournamentsYet => 'Aún no hay torneos.';

  @override
  String get noTournamentsFiltered =>
      'Ningún torneo coincide con los filtros actuales.';

  @override
  String get noClubsYet => 'Aún no hay clubes.';

  @override
  String get noClubsFiltered =>
      'Ningún club coincide con los filtros actuales.';

  @override
  String get noScoringHistoryYet => 'Aún no hay historial de puntuación';

  @override
  String get noPlayersInTeam => 'Aún no hay jugadores.';

  @override
  String get noTournamentsInTeam => 'Aún no está en ningún torneo.';

  @override
  String get noClubsInTeam => 'Aún no está en ningún club.';

  @override
  String get teamNotFound => 'Equipo no encontrado.';

  @override
  String snackbarGeneratedTeams(int count) {
    return '$count equipos aleatorios generados.';
  }

  @override
  String snackbarGeneratedPlayers(int count) {
    return '$count jugadores aleatorios generados.';
  }

  @override
  String get snackbarGamesAlreadyGenerated =>
      'Los partidos ya han sido generados para este torneo.';

  @override
  String get snackbarAddTeamsFirst =>
      'Añade al menos 2 equipos antes de generar partidos.';

  @override
  String teamScopeLabel(String name) {
    return 'Ámbito: $name';
  }

  @override
  String get editPlayerNamesSubtitle => 'Editar nombres de jugadores';

  @override
  String get playerOne => 'Jugador 1';

  @override
  String get playerTwo => 'Jugador 2';

  @override
  String get navSettings => 'Configuración';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get langAutomatic => 'Automático';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get errorLinkNotAvailable => 'Enlace aún no disponible';

  @override
  String get errorCouldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get errorCouldNotOpenEmail => 'No se pudo abrir la app de email';

  @override
  String get errorStoreNotAvailable =>
      'No se pudo abrir la tienda — busca TournaQ manualmente.';

  @override
  String get gameOptions => 'Opciones de juego';

  @override
  String get swapTeams => 'Cambiar equipos';

  @override
  String get swapTeamsSubtitle => 'Intercambiar lados izquierdo y derecho';

  @override
  String get changeService => 'Cambiar saque';

  @override
  String get changeServiceSubtitle => 'Pasar al siguiente sacador';

  @override
  String get gameplayHistorySubtitle => 'Línea de tiempo punto a punto';

  @override
  String get historyShort => 'Historial';

  @override
  String get completeSet => 'Completar set';

  @override
  String get undoSetCompletion => 'Deshacer set completado';

  @override
  String get completeGame => 'Completar partido';

  @override
  String get undoGameCompletion => 'Deshacer partido completado';

  @override
  String get targetScore => 'Puntuación:';

  @override
  String get swapPlayers => 'Intercambiar jugadores';

  @override
  String get lockBannerGame =>
      'Partido completado — deshaz la finalización para editar puntos';

  @override
  String get lockBannerSet =>
      'Set completado — deshaz la finalización para editar puntos';

  @override
  String gameTileWinner(String name) {
    return 'Ganador: $name';
  }

  @override
  String get noWinnerDetermined => 'Ganador no determinado';

  @override
  String gameTileMatch(String status) {
    return 'Partido: $status';
  }

  @override
  String get menuGameScorecard => 'Marcador del partido';

  @override
  String get btnDeleteGame => 'Eliminar partido';

  @override
  String get pagePlayerDetails => 'Detalles del jugador';

  @override
  String get pageClubDetails => 'Detalles del club';

  @override
  String get playerNotFound => 'Jugador no encontrado.';

  @override
  String get clubNotFound => 'Club no encontrado.';

  @override
  String get dialogRemoveFromTeam => 'Quitar del equipo';

  @override
  String get dialogRemoveFromTeamBody => '¿Quitar a este jugador del equipo?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      '¿Quitar a este jugador del club?';

  @override
  String get dialogRemoveTournamentFromClub => 'Quitar torneo';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      '¿Quitar este torneo del club?';

  @override
  String get notAssignedToTeams => 'No asignado a ningún equipo.';

  @override
  String get notAssignedToClubs => 'No asignado a ningún club.';

  @override
  String userEmailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String userRoleLabel(String role) {
    return 'Rol: $role';
  }

  @override
  String get menuAddPlayer => 'Añadir jugador';

  @override
  String get menuAddTeam => 'Añadir equipo';

  @override
  String get menuAddTournament => 'Añadir torneo';

  @override
  String get labelName => 'Nombre';

  @override
  String get btnSuggest => 'Sugerir';

  @override
  String get labelEmailOptional => 'Email (opcional)';

  @override
  String get labelRoleOptional => 'Rol (opcional)';

  @override
  String get labelScope => 'Alcance';

  @override
  String get hintClubName => 'Nombre del club';

  @override
  String get labelAssignToTeams => 'Asignar a equipos';

  @override
  String get labelAssignToClubs => 'Asignar a clubs';

  @override
  String get labelAssignToTournaments => 'Asignar a torneos';

  @override
  String get labelAssignPlayers => 'Asignar jugadores';

  @override
  String get labelAssignTeams => 'Asignar equipos';

  @override
  String get labelAssignTournaments => 'Asignar torneos';

  @override
  String get scopeTemporary => 'Temporal';

  @override
  String get scopeTournament => 'Torneo';

  @override
  String get scopeClub => 'Club';

  @override
  String get labelMode => 'Modo';

  @override
  String get hybridConfigureGroups => 'Configurar grupos híbridos';

  @override
  String hybridGroupsConfigured(int count) {
    return '$count grupos configurados — toca para editar';
  }

  @override
  String get labelAssignExistingTeams => 'Asignar equipos existentes';

  @override
  String get filterAllClubs => 'Todos los clubs';

  @override
  String get noTeamsInClub => 'No hay equipos en este club.';

  @override
  String get noTeamsAvailableYet => 'Aún no hay equipos disponibles.';

  @override
  String get labelAvailable => 'Disponible';

  @override
  String get hintDragTeamsHere => 'Toca o arrastra equipos aquí';

  @override
  String labelSelectedCount(int count) {
    return 'Seleccionados ($count)';
  }

  @override
  String get labelGenerateRandomTeams => 'Generar equipos aleatorios';

  @override
  String get labelNone => 'Ninguno';

  @override
  String get labelClubForRandomTeams => 'Club para equipos aleatorios';

  @override
  String get radioNoClub => 'Sin club';

  @override
  String get radioAddToExistingClub => 'Añadir a club existente';

  @override
  String get hintSelectClub => 'Seleccionar un club';

  @override
  String get radioCreateNewClub => 'Crear nuevo club';

  @override
  String get hintClubNameRandom =>
      'Nombre del club (dejar en blanco para aleatorio)';

  @override
  String get tooltipSuggestName => 'Sugerir un nombre';

  @override
  String get noTeamsFoundSearch => 'No se encontraron equipos.';

  @override
  String get quickStartShort => 'Inicio rápido';

  @override
  String get formatBestOfThreeShort => 'Al mejor de tres';

  @override
  String get teamMethodExistingSubtitle => 'Elige entre tus equipos guardados';

  @override
  String get teamMethodNewSubtitle => 'Nombra tus equipos sobre la marcha';

  @override
  String get teamMethodRandomSubtitle =>
      'Dejamos que elijamos nombres divertidos';

  @override
  String get quickStartChooseTeams => 'Elige tus equipos';

  @override
  String get quickStartSelectTeamsTitle => 'Seleccionar equipos';

  @override
  String get quickStartNotEnoughTeams => 'No hay suficientes equipos';

  @override
  String get quickStartNotEnoughTeamsBody =>
      'Necesitas al menos 2 equipos guardados.\nIntenta crear o generar equipos.';

  @override
  String get teamOne => 'Equipo 1';

  @override
  String get teamTwo => 'Equipo 2';

  @override
  String get quickStartChooseTeam1 => 'Elegir equipo 1';

  @override
  String get quickStartChooseTeam2 => 'Elegir equipo 2';

  @override
  String get quickStartCreateTeamsTitle => 'Crear equipos';

  @override
  String get hintTeam1Example => 'p. ej. Águilas rojas';

  @override
  String get hintTeam2Example => 'p. ej. Leones azules';

  @override
  String get quickStartRandomTeamsTitle => 'Equipos aleatorios';

  @override
  String get quickStartReRollTeams => 'Volver a sortear equipos';

  @override
  String get btnStart => 'Iniciar';

  @override
  String get labelVs => 'vs';

  @override
  String get hybridModeSetup => 'Configurar modo híbrido';

  @override
  String get btnDone => 'Listo';

  @override
  String get hybridAvailableModes => 'Modos disponibles';

  @override
  String hybridRemaining(int count) {
    return '$count restantes';
  }

  @override
  String get hybridDragHint =>
      'Mantén pulsado para arrastrar a un grupo, o toca para añadir al primer grupo.';

  @override
  String get hybridAllModesAssigned => 'Todos los modos asignados a grupos.';

  @override
  String get hybridModeGroups => 'Grupos de modos';

  @override
  String get hybridAddGroup => 'Añadir grupo';

  @override
  String get hybridAddGroupHint =>
      'Añade un grupo arriba, luego arrastra o toca los modos para añadirlos.';

  @override
  String hybridGroupN(int n) {
    return 'Grupo $n';
  }

  @override
  String get hybridDragModesHere => 'Arrastra modos aquí';

  @override
  String get hybridTip =>
      'Consejo: Cada grupo define una ronda de juego. Los equipos pasan por todos los grupos de modos.';

  @override
  String get pageTournamentDetails => 'Detalles del torneo';

  @override
  String get tournamentNotFound => 'Torneo no encontrado.';

  @override
  String get assignAllTeamsInTournament =>
      'Todos los equipos ya están en este torneo.';

  @override
  String get assignTournamentAllClubs =>
      'El torneo ya está en todos los clubs.';

  @override
  String get snackbarAddTeamsFirstCreate =>
      'Añade al menos 2 equipos antes de crear partidos.';

  @override
  String get dialogClearAllGames => 'Eliminar todos los partidos';

  @override
  String get dialogClearAllGamesBody =>
      '¿Seguro que quieres eliminar todos los partidos de este torneo?';

  @override
  String get btnClear => 'Eliminar';

  @override
  String get btnCreateGame => 'Crear partido';

  @override
  String get btnClearGames => 'Eliminar partidos';

  @override
  String tournamentModeLabel(String name) {
    return 'Modo: $name';
  }

  @override
  String tournamentStatusLabel(String name) {
    return 'Estado: $name';
  }

  @override
  String tournamentTeamsLabel(int count) {
    return 'Equipos: $count';
  }

  @override
  String tournamentGamesLabel(int count) {
    return 'Partidos: $count';
  }

  @override
  String get sectionHybridGroups => 'Grupos híbridos';

  @override
  String get noHybridGroupsYet => 'Aún no hay grupos híbridos configurados.';

  @override
  String get noTeamsAssignedYet => 'Aún no hay equipos asignados.';

  @override
  String nPlayersCount(int count) {
    return '$count jugador(es)';
  }

  @override
  String get sectionLeagueStandings => 'Clasificación de liga';

  @override
  String get labelUnknown => 'Desconocido';

  @override
  String sectionGamesCount(int count) {
    return 'Partidos ($count)';
  }

  @override
  String get noGamesCreatedYet => 'Aún no se han creado partidos.';

  @override
  String get notInAnyClubsYet => 'Aún no pertenece a ningún club.';

  @override
  String clubPlayersAndTeams(int players, int teams) {
    return '$players jugador(es) • $teams equipo(s)';
  }

  @override
  String get labelStyle => 'Estilo';

  @override
  String get assignNothingAvailable => 'Nada disponible para asignar.';

  @override
  String get btnDeleteAll => 'Eliminar todo';

  @override
  String get statusSetup => 'Configuración';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String dateDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get labelLate => 'TARDE';

  @override
  String get statPts => 'Pts';

  @override
  String get statEsc => 'Esc';

  @override
  String get statGames => 'Partidos';

  @override
  String get statLost => 'Perd';

  @override
  String get doghouseTitle => 'Doghouse';

  @override
  String get doghouseGameHistory => 'Historial de partidos';

  @override
  String get doghouseEscaped => 'Escapado';

  @override
  String get doghouseEjected => 'Expulsado';

  @override
  String doghouseNGamesLost(int count) {
    return '$count perd.';
  }

  @override
  String get doghouseNoGamesYet => 'Aún no hay partidos.';

  @override
  String get doghouseNoGamesYetBody =>
      'Los partidos aparecerán aquí cuando un equipo termine.';

  @override
  String get doghouseNoTournamentsYet => 'Aún no hay torneos.';

  @override
  String get doghouseNoTournamentsHint => 'Toca Nuevo torneo para empezar.';

  @override
  String get doghouseDeleteTournamentTitle => '¿Eliminar torneo?';

  @override
  String doghouseDeleteTournamentBody(String name) {
    return 'Se eliminará permanentemente \"$name\" y todos sus datos.';
  }

  @override
  String get doghouseDeleteAllTitle => '¿Eliminar todos los torneos?';

  @override
  String doghouseDeleteAllBody(int count) {
    return 'Se eliminarán permanentemente los $count torneo(s).';
  }

  @override
  String get doghouseNewTournament => 'Nuevo torneo';

  @override
  String doghouseTournamentHistory(int count) {
    return 'Historial de torneos ($count)';
  }

  @override
  String doghouseStatsPlayers(int count) {
    return '$count jugadores';
  }

  @override
  String doghouseStatsGames(int count) {
    return '$count partidos';
  }

  @override
  String doghouseStatsEscapes(int count) {
    return '$count escapados';
  }

  @override
  String get btnAdd => 'Añadir';

  @override
  String get btnStop => 'Detener';

  @override
  String get btnUndo => 'Deshacer';

  @override
  String get labelOptions => 'Opciones';

  @override
  String get labelGotIt => 'Entendido';

  @override
  String get labelTime => 'Tiempo';

  @override
  String get labelAssignment => 'Asignación';

  @override
  String get labelEscapePoints => 'Puntos de escape';

  @override
  String get labelLossLimit => 'Límite de pérdidas';

  @override
  String get hintPlayerName => 'Nombre del jugador';

  @override
  String get doghouseScoreboard => 'Marcador';

  @override
  String get doghouseTimeUp => 'Tiempo agotado';

  @override
  String get doghouseTimerEndedBody =>
      'El temporizador ha terminado. ¿Completar el torneo ahora?';

  @override
  String get doghouseCompleteTournament => 'Completar torneo';

  @override
  String get doghouseContinueScoring => 'Continuar puntuando';

  @override
  String doghouseSubstitute(String name) {
    return 'Sustituir a $name';
  }

  @override
  String doghouseReturnToQueue(String name) {
    return '$name volverá a la cola.';
  }

  @override
  String get doghouseAddPlayersToQueue => 'Añadir jugadores a la cola';

  @override
  String doghouseNAdded(int count) {
    return '$count añadidos';
  }

  @override
  String get doghouseLateTagInfo =>
      'Todos los jugadores añadidos aquí se marcarán como \"Tarde\" en las estadísticas.';

  @override
  String get doghouseNoPlayersMatch => 'Ningún jugador coincide.';

  @override
  String get doghouseAdd4Random => 'Añadir 4 aleatorios';

  @override
  String get doghouseNoLatePlayersYet =>
      'Aún no hay jugadores tardíos añadidos.';

  @override
  String get doghouseEscapedExcl => '¡Escapado!';

  @override
  String doghouseEscapedScoreMsg(String names, int points) {
    return '¡$names anotó $points puntos!';
  }

  @override
  String get doghouseEscapeDesc => 'Escapan del doghouse y regresan a la cola.';

  @override
  String get doghouseEscapeBtn => '¡Escapar!';

  @override
  String get doghouseEjectedExcl => '¡Expulsado!';

  @override
  String doghouseEjectedScoreMsg(String names, int count) {
    return '¡$names perdió $count partidos!';
  }

  @override
  String get doghouseEjectDesc =>
      'Son expulsados del doghouse y regresan a la cola.';

  @override
  String get doghouseEjectTeam => 'Expulsar equipo';

  @override
  String get doghouseLeaveTitle => '¿Salir sin terminar el partido?';

  @override
  String doghouseLeaveBodyPts(int count) {
    return 'El equipo actual tiene $count punto(s) sin registrar. Al salir se perderán.';
  }

  @override
  String get doghouseLeaveBodyEmpty =>
      'Los datos no guardados del equipo actual se perderán.';

  @override
  String get doghouseLeaveAnyway => 'Salir de todas formas';

  @override
  String get doghouseTournamentComplete => 'Torneo completado';

  @override
  String doghouseSummaryStats(int games, int escapes) {
    return '$games partido(s) · $escapes escapados';
  }

  @override
  String get doghouseFinalStandings => 'Clasificación final';

  @override
  String doghousePairStat(int escapes, int losses) {
    return '$escapes escapados · $losses perdidos';
  }

  @override
  String get doghousePlayerStats => 'Estadísticas de jugadores';

  @override
  String get doghouseSessionTimer => 'TEMPORIZADOR';

  @override
  String get doghouseGameplayControls => 'Controles';

  @override
  String get doghouseMatchControls => 'Controles de partido';

  @override
  String get doghouseStartRestart => 'Iniciar / Reiniciar';

  @override
  String get doghouseTournamentCompleted => 'Torneo completado';

  @override
  String get doghouseNotEnoughInQueue =>
      'No hay suficientes jugadores en la cola.';

  @override
  String get doghouseSuggestedTeam => 'Equipo sugerido';

  @override
  String doghouseSelectPlayers(int needed, int selected) {
    return 'Seleccionar $needed jugadores ($selected / $needed)';
  }

  @override
  String get doghouseQueueTapToAdd => 'Cola — toca para añadir';

  @override
  String get doghouseEnterDoghouse => 'Entrar al Doghouse';

  @override
  String get doghouseViewAllGames => 'Ver todos los partidos completados';

  @override
  String doghouseEscapePointsLabel(int count) {
    return '$count pts escape';
  }

  @override
  String doghouseLossLimitLabel(int count) {
    return 'límite de $count pérdidas';
  }

  @override
  String get doghouseAddPlayerToQueue => 'Añadir jugador a la cola';

  @override
  String get doghouseUndoCompletion => 'Deshacer finalización';

  @override
  String get doghouseSaveAndReturn => 'Guardar y volver';

  @override
  String get doghouseGameLost => 'Partido\nPerdido';

  @override
  String get doghouseUndoGame => 'Deshacer\nPartido';

  @override
  String get doghouseUndoLastGame => 'Deshacer último partido';

  @override
  String get doghouseTournamentSetup => 'Configuración del torneo';

  @override
  String get doghouseTapToAddPlayers => 'Toca para añadir jugadores';

  @override
  String doghouseNPlayersAdded(int count) {
    return '$count jugadores añadidos';
  }

  @override
  String doghouseNeedAtLeastN(int count, int min) {
    return '$count añadidos · se necesitan al menos $min';
  }

  @override
  String get doghouseClearAll => 'Borrar todo';

  @override
  String doghouseFillNRandom(int count) {
    return 'Completar con $count aleatorios';
  }

  @override
  String get doghouseSetupNoPlayers => 'Aún no hay jugadores añadidos.';

  @override
  String get doghouseSourceExisting => 'Jugador existente';

  @override
  String get doghouseSourceNew => 'Jugador nuevo';

  @override
  String get doghouseSourceRandom => 'Marcador aleatorio';

  @override
  String get doghouseTournamentName => 'Nombre del torneo';

  @override
  String get doghouseSetupGood => '¡La configuración está lista!';

  @override
  String get doghouseSetupIncomplete => 'Configuración incompleta';

  @override
  String get doghouseRemoveAllTitle => '¿Eliminar todos los jugadores?';

  @override
  String get doghouseRemoveAllBody =>
      'Esto eliminará todos los jugadores añadidos de la lista.';

  @override
  String get doghouseRemoveAll => 'Eliminar todos';

  @override
  String get doghouseAssignmentManual => 'Manual';

  @override
  String get doghouseAssignmentAutomated => 'Automatizado';

  @override
  String doghouseAddedCount(int added, int total) {
    return 'Añadidos ($added/$total)';
  }
}

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
  String get navTournaments => 'TournaQ Arena';

  @override
  String get navTeams => 'Equipos';

  @override
  String get navClubs => 'Grupos';

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
  String get pageTournaments => 'TournaQ Arena';

  @override
  String get pageClubs => 'Grupos';

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
  String get btnCreateClub => 'Crear Grupo';

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
    return 'Grupos ($count)';
  }

  @override
  String get hintSearchTeams => 'Buscar equipos...';

  @override
  String get hintSearchPlayers => 'Buscar jugadores...';

  @override
  String get hintSearchTournaments => 'Buscar torneos...';

  @override
  String get hintSearchClubs => 'Buscar grupos...';

  @override
  String get filterPlayer => 'Jugador';

  @override
  String get filterTeam => 'Equipo';

  @override
  String get filterTournament => 'Torneo';

  @override
  String get filterClub => 'Grupo';

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
  String get comingSoonLearnMore => 'Más información en el sitio web';

  @override
  String get landingTournamentsSubtitle => 'Gestiona torneos y scrambles';

  @override
  String get landingAdminSubtitle => 'Gestiona jugadores, equipos y grupos';

  @override
  String get btnGotIt => 'Entendido';

  @override
  String get btnLearnMore => 'Más información';

  @override
  String get tournamentsSectionQuickGames => 'Juegos Rápidos';

  @override
  String get tournamentsSectionSingle =>
      'Competiciones Individuales y Sociales';

  @override
  String get tournamentsSectionTeam => 'Competiciones por Equipos';

  @override
  String get tournamentsSectionHistory => 'Historial de Torneos';

  @override
  String get modeQuickGamesDesc => 'Partidos al instante';

  @override
  String get modeSocialScramblesDesc => 'Mixer rotativo';

  @override
  String get modeKotcDesc => 'Domina la cancha';

  @override
  String get modeDoghouseDesc => 'Escapa del Doghouse';

  @override
  String get modeLeagueDesc => 'Clasificación por puntos';

  @override
  String get modeSingleElimDesc => 'Bracket de eliminación clásico';

  @override
  String get modeDoubleElimDesc => 'Bracket con segunda oportunidad';

  @override
  String get modeGroupSeDesc => 'Fase de grupos · Eliminación simple';

  @override
  String get modeGroupDeDesc => 'Fase de grupos · Eliminación doble';

  @override
  String get modeSwissDesc => 'Emparejamientos por puntuación';

  @override
  String get modeLeagueShortDesc =>
      'Sigue la clasificación de una temporada completa de round-robin con puntos, victorias y diferencia de goles.';

  @override
  String get modeDoubleElimShortDesc =>
      'Brackets de ganadores y perdedores — necesitas dos derrotas para ser eliminado.';

  @override
  String get modeGroupSeShortDesc =>
      'Los equipos avanzan de una fase de grupos a un bracket de eliminación simple.';

  @override
  String get modeGroupDeShortDesc =>
      'Los equipos avanzan de una fase de grupos a un bracket de eliminación doble.';

  @override
  String get modeSwissShortDesc =>
      'Los jugadores se emparejan cada ronda según su puntuación — sin eliminaciones, calendario completo.';

  @override
  String get tournamentsDeleteTitle => '¿Eliminar todo el historial?';

  @override
  String tournamentsDeleteBody(int count) {
    return 'Se eliminarán permanentemente los $count torneos. Esta acción no se puede deshacer.';
  }

  @override
  String get tournamentsDeleteAll => 'Eliminar todo';

  @override
  String get tournamentsAllLabel => 'Todos los torneos';

  @override
  String get tournamentsInfoContent =>
      'Inicia un partido o gestiona un torneo completo — todo en un solo lugar.\n\nQuick Games — Partidos puntuados al instante. Configuración mínima, elige dos equipos y empieza.\n\nCompeticiones Individuales y Sociales — Formatos individuales donde los jugadores compiten y se clasifican por sí mismos, rotando durante la sesión.\n\nCompeticiones por Equipos — Formatos por equipos donde equipos preformados se enfrentan en un bracket o tabla de clasificación.\n\nToca Info en cualquier tarjeta para saber más antes de comenzar.';

  @override
  String get landingQuickStartSubtitle => 'Partido de Vóley Playa';

  @override
  String get landingMatchHistoryTitle => 'Historial de Partidos';

  @override
  String get landingMatchHistorySubtitle => 'Ver y revisar partidos anteriores';

  @override
  String get landingMoreTournamentTitle => 'Más funciones de torneo';

  @override
  String get landingMoreTournamentSub =>
      'Formatos adicionales, cuadros y estructuras competitivas.';

  @override
  String get landingDeviceScalabilityTitle =>
      'Adaptabilidad de dispositivos y pantallas';

  @override
  String get landingDeviceScalabilitySub =>
      'Diseños optimizados para tablets, web y todos los tamaños de pantalla.';

  @override
  String get landingScorecardSharingTitle =>
      'Compartir marcadores y escalar torneos';

  @override
  String get landingScorecardSharingSub =>
      'Comparte resultados y da soporte a eventos y grupos más grandes.';

  @override
  String get landingLiveTournamentTitle => 'Funciones de torneo en vivo';

  @override
  String get landingLiveTournamentSub =>
      'Puntuación en tiempo real, clasificaciones y actualizaciones del evento.';

  @override
  String get landingAdvancedAdminTitle => 'Administración avanzada de usuarios';

  @override
  String get landingAdvancedAdminSub =>
      'Gestiona jugadores, equipos, grupos y roles de organizador.';

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
      'Futuros socios, grupos y organizaciones podrían aparecer aquí.';

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
  String get contactUserGuide => 'Descripción de Funciones';

  @override
  String get contactUserGuideSub =>
      'Explora todos los modos y funciones en el sitio web';

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
  String get dialogRemoveFromClub => 'Eliminar del Grupo';

  @override
  String get dialogRemoveFromClubBody => '¿Eliminar este equipo del grupo?';

  @override
  String get menuEditPlayers => 'Editar Jugadores';

  @override
  String get menuAssignToTournament => 'Añadir a Torneo';

  @override
  String get menuAssignToClub => 'Añadir a Grupo';

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
  String get menuAddToClub => 'Añadir a Grupo';

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
  String get noClubsYet => 'Aún no hay grupos.';

  @override
  String get noClubsFiltered =>
      'Ningún grupo coincide con los filtros actuales.';

  @override
  String get noScoringHistoryYet => 'Aún no hay historial de puntuación';

  @override
  String get noPlayersInTeam => 'Aún no hay jugadores.';

  @override
  String get noTournamentsInTeam => 'Aún no está en ningún torneo.';

  @override
  String get noClubsInTeam => 'Aún no está en ningún grupo.';

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
  String get pageClubDetails => 'Detalles del grupo';

  @override
  String get playerNotFound => 'Jugador no encontrado.';

  @override
  String get clubNotFound => 'Grupo no encontrado.';

  @override
  String get dialogRemoveFromTeam => 'Quitar del equipo';

  @override
  String get dialogRemoveFromTeamBody => '¿Quitar a este jugador del equipo?';

  @override
  String get dialogRemovePlayerFromClubBody =>
      '¿Quitar a este jugador del grupo?';

  @override
  String get dialogRemoveTournamentFromClub => 'Quitar torneo';

  @override
  String get dialogRemoveTournamentFromClubBody =>
      '¿Quitar este torneo del grupo?';

  @override
  String get notAssignedToTeams => 'No asignado a ningún equipo.';

  @override
  String get notAssignedToClubs => 'No asignado a ningún grupo.';

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
  String get hintClubName => 'Nombre del grupo';

  @override
  String get labelAssignToTeams => 'Asignar a equipos';

  @override
  String get labelAssignToClubs => 'Asignar a grupos';

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
  String get scopeClub => 'Grupo';

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
  String get filterAllClubs => 'Todos los grupos';

  @override
  String get noTeamsInClub => 'No hay equipos en este grupo.';

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
  String get labelClubForRandomTeams => 'Grupo para equipos aleatorios';

  @override
  String get radioNoClub => 'Sin grupo';

  @override
  String get radioAddToExistingClub => 'Añadir a grupo existente';

  @override
  String get hintSelectClub => 'Seleccionar un grupo';

  @override
  String get radioCreateNewClub => 'Crear nuevo grupo';

  @override
  String get hintClubNameRandom =>
      'Nombre del grupo (dejar en blanco para aleatorio)';

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
      'El torneo ya está en todos los grupos.';

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
  String get notInAnyClubsYet => 'Aún no pertenece a ningún grupo.';

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
  String get statusDue => 'En curso';

  @override
  String get statusOverdue => 'Retrasado';

  @override
  String get statusUpcoming => 'Próximo';

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

  @override
  String statsRounds(int count) {
    return '$count rondas';
  }

  @override
  String statsPtsScored(int total) {
    return '$total pts anotados';
  }

  @override
  String statsTeams(int count) {
    return '$count equipos';
  }

  @override
  String statsCourts(int count) {
    return '$count canchas';
  }

  @override
  String statsMatchesOf(int completed, int total) {
    return '$completed / $total partidos';
  }

  @override
  String statsGamesOf(int completed, int total) {
    return '$completed/$total partidos';
  }

  @override
  String get setupDuplicateNameTitle => 'Nombre duplicado';

  @override
  String setupDuplicateNameBody(String name) {
    return '\"$name\" ya está añadido al torneo. ¿Añadir de todas formas?';
  }

  @override
  String get btnAddAnyway => 'Añadir de todas formas';

  @override
  String get setupSectionPlayers => 'Jugadores';

  @override
  String get setupSectionCreatePlayer => 'Crear jugador';

  @override
  String setupAddExistingPlayers(int count) {
    return 'Añadir jugadores existentes ($count)';
  }

  @override
  String get setupSearchPlayersHint => 'Buscar jugadores…';

  @override
  String get setupPlayerNameHint => 'Nombre del jugador';

  @override
  String setupPlayersOf(int count, int target) {
    return '$count/$target jugadores añadidos';
  }

  @override
  String get setupTargetPlayers => 'Jugadores objetivo';

  @override
  String get setupAvailableTime => 'Tiempo disponible';

  @override
  String get setupMatchDuration => 'Duración del partido';

  @override
  String get setupCourts => 'Canchas';

  @override
  String get setupBreakBetweenRounds => 'Pausa entre rondas';

  @override
  String get setupFormat => 'Formato';

  @override
  String get setupPlannedStartTime => 'Hora de inicio prevista';

  @override
  String get setupPlannedEndTime => 'Hora de fin prevista';

  @override
  String get setupSchedulePreview => 'Vista previa del horario';

  @override
  String get setupRoundDuration => 'Duración de ronda';

  @override
  String get setupRoundsLabel => 'Rondas';

  @override
  String get setupScheduledDuration => 'Duración programada';

  @override
  String get setupScheduledEndTime => 'Hora de fin programada';

  @override
  String get setupSuggestions => 'Sugerencias';

  @override
  String get setupFormatAutoAllplay => 'Auto-Allplay';

  @override
  String get setupCourtsInfoBody =>
      'Actualmente fijado en 1 cancha.\n\nEl soporte multi-cancha — asignar y hacer seguimiento de varias canchas simultáneas con rotación óptima — está previsto para una versión futura.';

  @override
  String get setupSeedingRandom => 'Aleatorio';

  @override
  String get setupSeedingSeeded => 'Por clasificación';

  @override
  String get setupOddTeamsByes => 'Bye';

  @override
  String get setupOddTeamsPlayIn => 'Play-in';

  @override
  String get setupSectionTeams => 'Equipos';

  @override
  String get setupRemoveAllTeamsTitle => '¿Eliminar todos los equipos?';

  @override
  String get setupRemoveAllTeamsBody =>
      'Esto eliminará todos los equipos añadidos de la lista.';

  @override
  String get setupNoTeamsMatch => 'No se encontraron equipos.';

  @override
  String get setupNoTeamsAddedYet => 'Aún no hay equipos añadidos.';

  @override
  String get setupTeamNameHint => 'Nombre del equipo';

  @override
  String setupAddExistingTeams(int count) {
    return 'Añadir equipos existentes ($count)';
  }

  @override
  String get setupSearchTeamsHint => 'Buscar equipos…';

  @override
  String get setupCreateTeam => 'Crear equipo';

  @override
  String get setupGeneration => 'Generación';

  @override
  String get setupOddTeamsLabel => 'Equipos impares';

  @override
  String get setupEarlyRounds => 'Rondas previas';

  @override
  String get setupFinalRounds => 'Rondas finales';

  @override
  String get setupReadyToStart => '¡Listo para empezar!';

  @override
  String setupAddAllTeams(int count) {
    return 'Añade todos los $count equipos para continuar';
  }

  @override
  String get setupTapToAddTeams => 'Toca para añadir equipos';

  @override
  String setupTeamsOf(int count, int target) {
    return '$count/$target equipos añadidos';
  }

  @override
  String get overviewSectionOverview => 'Resumen';

  @override
  String get overviewSectionTimeline => 'Vista previa del horario';

  @override
  String timelineStart(String time) {
    return 'Inicio: $time';
  }

  @override
  String timelinePredictedEnd(String time) {
    return 'Fin previsto: $time';
  }

  @override
  String timelineRound(int number) {
    return 'Ronda $number';
  }

  @override
  String timelineBreakUntil(String time) {
    return 'Descanso hasta $time';
  }

  @override
  String get timelineScheduleTitle => 'Programación del torneo';

  @override
  String get timelineTournamentStart => 'Inicio del torneo';

  @override
  String get timelineGameDuration => 'Duración del juego (rondas pendientes)';

  @override
  String get timelineBreakDurationPending =>
      'Duración del descanso (rondas pendientes)';

  @override
  String get timelinePaceAlertsTitle => 'Alertas de ritmo';

  @override
  String get timelinePaceAlertsSubtitle =>
      'Marcar rondas como al día, pendientes o atrasadas';

  @override
  String get timelineEditStartTime => 'Hora de inicio';

  @override
  String get timelineMatchDuration => 'Duración del partido';

  @override
  String get timelineBreakAfterRound => 'Descanso después de la ronda';

  @override
  String get overviewSectionSchedule => 'Horario';

  @override
  String overviewGamesCompleted(int completed, int total) {
    return '$completed / $total juegos completados';
  }

  @override
  String overviewStatsSummary(int rounds, int courts, int players) {
    return '$rounds rondas  ·  $courts canchas  ·  $players jugadores';
  }

  @override
  String overviewFinished(String time) {
    return 'Finalizado: $time';
  }

  @override
  String overviewEstFinish(String time) {
    return 'Est. fin: $time';
  }

  @override
  String overviewSectionPlayers(int count) {
    return 'Jugadores ($count)';
  }

  @override
  String get overviewAddPlayerSubtitle =>
      'Los jugadores añadidos se unen tarde.';

  @override
  String overviewAddConfirm(String name) {
    return '¿Añadir a $name?';
  }

  @override
  String overviewAddLateBody(String name) {
    return '$name se unirá tarde. Los emparejamientos restantes se reorganizarán — algunos jugadores pueden tener un número desigual de partidos.';
  }

  @override
  String overviewSwapTitle(String name) {
    return 'Cambiar a $name';
  }

  @override
  String overviewSwapSubtitle(String name) {
    return '$name será eliminado de las rondas siguientes.';
  }

  @override
  String overviewEjectTitle(String name) {
    return '¿Expulsar a $name?';
  }

  @override
  String overviewEjectBody(String name) {
    return '$name será eliminado de todas las rondas siguientes. Los emparejamientos restantes se reorganizarán — algunos jugadores pueden tener un número desigual de partidos. Los partidos completados permanecen en las estadísticas.';
  }

  @override
  String get overviewEjectBtn => 'Expulsar';

  @override
  String get overviewEditPlayer => 'Editar jugador';

  @override
  String get overviewAllPlayersAlready =>
      'Todos los jugadores existentes ya están en este torneo.';

  @override
  String overviewRound(int number) {
    return 'Ronda $number';
  }

  @override
  String get overviewActual => 'real';

  @override
  String overviewBreakUntil(String time) {
    return '· Descanso hasta $time';
  }

  @override
  String get scrambleStatusSwappedOut => 'reemplazado';

  @override
  String get scrambleStatusSwappedIn => 'suplente';

  @override
  String get scrambleStatusLate => 'tarde';

  @override
  String get tooltipEdit => 'Editar';

  @override
  String get tooltipEject => 'Expulsar';

  @override
  String get tooltipSwap => 'Cambiar';

  @override
  String get tooltipRankings => 'Clasificación de jugadores';

  @override
  String get scorecardSwapSides => 'Cambiar lados';

  @override
  String get scorecardSwapSidesSubtitle =>
      'Intercambiar visualización izquierda/derecha';

  @override
  String get scorecardMatchHistory => 'Historial del partido';

  @override
  String get scorecardMatchHistorySubtitle => 'Historial punto a punto';

  @override
  String get scorecardPlannedStart => 'Inicio planificado';

  @override
  String get scorecardPlannedEnd => 'Fin planificado';

  @override
  String get scorecardEnd => 'Fin';

  @override
  String get scorecardOverSchedule => '¡Fuera de horario!';

  @override
  String get scorecardOverScheduleHurry => '¡Fuera de horario · Date prisa!';

  @override
  String scorecardStartsServing(String name) {
    return '$name saca primero';
  }

  @override
  String get scorecardUndoCompletion => 'Deshacer finalización';

  @override
  String get scorecardStartMatch => 'Iniciar partido';

  @override
  String get scorecardCompleteGame => 'Finalizar juego';

  @override
  String get scorecardManualScore => 'Introducir resultado manualmente';

  @override
  String get scorecardBackToSchedule => 'Volver al horario';

  @override
  String get scorecardManualScoreBlockedTitle =>
      'Resultado manual no disponible';

  @override
  String get scorecardManualScoreBlockedBody =>
      'La entrada manual solo está disponible antes de que haya comenzado la puntuación en vivo. Esto evita sobrescribir accidentalmente los puntos ya registrados.';

  @override
  String get scorecardManualScoreDescription =>
      'Úsalo cuando el juego fue jugado sin puntuación en vivo. Introduce el marcador final para ambos lados y completa el juego.';

  @override
  String get btnOK => 'OK';

  @override
  String get btnAdjustFinalScore => 'Ajustar resultado final';

  @override
  String get btnRestart => 'Reiniciar';

  @override
  String get btnResume => 'Reanudar';

  @override
  String get btnApply => 'Aplicar';

  @override
  String labelMinutes(int n) {
    return '$n min';
  }

  @override
  String get matchScorecard => 'Marcador';

  @override
  String get matchOptions => 'Opciones del partido';

  @override
  String get matchViewHistory => 'Ver historial punto a punto';

  @override
  String get matchComplete => 'Partido completado';

  @override
  String get matchSetCompleteBanner => 'Set completado';

  @override
  String matchSuggestedToServe(String name) {
    return '$name sugerido para sacar';
  }

  @override
  String matchSuggestedReferee(String name) {
    return '$name sugerido como árbitro';
  }

  @override
  String get matchAssignRefereeManually => 'Asignar árbitro manualmente';

  @override
  String get matchScoresTiedSet =>
      'Empate — un set no puede terminar en tablas.';

  @override
  String get matchScoresTiedMatch =>
      'Empate — se debe determinar un ganador antes de completar.';

  @override
  String get matchSetsTied =>
      'Los sets están empatados — se debe determinar un ganador.';

  @override
  String get matchUndoSet => 'Deshacer set';

  @override
  String get matchCompleteSet => 'Completar set';

  @override
  String get matchUndoMatchCompletion => 'Deshacer finalización del partido';

  @override
  String get matchCompleteMatch => 'Completar partido';

  @override
  String get matchSetScoreManually => 'Introducir resultado manualmente';

  @override
  String get matchBackToBracket => 'Volver al bracket';

  @override
  String matchCourtLabel(int court) {
    return 'Pista $court';
  }

  @override
  String matchStartsAt(String time) {
    return 'Empieza $time';
  }

  @override
  String matchSetNScore(int n) {
    return 'Resultado del set $n';
  }

  @override
  String get matchSetScore => 'Introducir resultado';

  @override
  String get bracketWithdrawTitle => '¿Retirar equipo?';

  @override
  String bracketWithdrawBody(String name) {
    return '¿Retirar a \"$name\"? Sus partidos pendientes se resolverán como walkover.';
  }

  @override
  String get bracketWithdrawBtn => 'Retirar';

  @override
  String get bracketFinalRoundsFormat => 'Formato: rondas finales';

  @override
  String get bracketEarlyRoundsFormat => 'Formato: rondas iniciales';

  @override
  String bracketFinalRoundsAppliesTo(int n) {
    return 'Se aplica a las últimas $n rondas';
  }

  @override
  String get bracketEarlyRoundsAppliesTo =>
      'Se aplica a todas las rondas iniciales';

  @override
  String get setupSetsPerGame => 'Sets por partido';

  @override
  String get setupPointsPerSet => 'Puntos por set';

  @override
  String get bracketBreakFinalRounds => 'Descanso — Rondas finales';

  @override
  String get bracketBreakEarlyRounds => 'Descanso — Rondas iniciales';

  @override
  String get bracketNoBreak => 'Sin descanso';

  @override
  String get bracketNoStartTime => 'Sin hora de inicio';

  @override
  String bracketStartsLabel(String label) {
    return 'Inicio: $label';
  }

  @override
  String get bracketTournamentWinner => 'Ganador del torneo';

  @override
  String get bracketRunnerUp => 'Finalista';

  @override
  String get bracketThirdPlace => '3.er lugar';

  @override
  String bracketSectionTeams(int count) {
    return 'Equipos ($count)';
  }

  @override
  String get bracketSwapTeamTitle => 'Cambiar equipo';

  @override
  String bracketSwapTeamSubtitle(String name) {
    return 'Sustituyendo a \"$name\" en todos los partidos pendientes.';
  }

  @override
  String get bracketSearchTeams => 'Buscar equipos…';

  @override
  String get bracketNoTeamsInHub =>
      'Aún no hay equipos en el centro de equipos.';

  @override
  String get bracketAllTeamsInTournament =>
      'Todos los equipos del hub ya están en este torneo.';

  @override
  String get scorecardMatchTimerLabel => 'Temporizador';

  @override
  String get scorecardUpcomingGames => 'Próximos juegos';

  @override
  String scorecardPlayerCount(int n) {
    return '$n jugadores';
  }

  @override
  String get scorecardGameCompletedLock =>
      'Juego completado — deshacer para editar';

  @override
  String get kotcTimeIsUp => 'Se acabó el tiempo';

  @override
  String get kotcSessionEndedBody =>
      'El temporizador ha terminado. ¿Completar el torneo ahora?';

  @override
  String kotcSubstituteTitle(String name) {
    return 'Sustituir a $name';
  }

  @override
  String kotcSubstituteBody(String name) {
    return '$name volverá a la cola.';
  }

  @override
  String get kotcAddLateTitle => '¿Añadir jugador tardío?';

  @override
  String get kotcAddLateBody =>
      'Este jugador se une tarde y no ha tenido las mismas oportunidades que los jugadores que empezaron desde el principio. Sus estadísticas se marcarán como \"Tarde\".';

  @override
  String get btnContinue => 'Continuar';

  @override
  String get kotcLateTag => 'TARDE';

  @override
  String get kotcAdminTag => 'ADMIN';

  @override
  String get kotcChangeAdmin => 'Cambiar admin';

  @override
  String get kotcChangeAdminSubtitle =>
      'Selecciona quién lleva el marcador. El admin actual vuelve a la cola.';

  @override
  String get kotcNextAdmin => 'PRÓXIMO ADMIN';

  @override
  String get kotcNextAdminNote => 'Sugerido del equipo actual en pista.';

  @override
  String get kotcGameWon => '¡Juego ganado!';

  @override
  String kotcReachedPoints(String names, int points) {
    return '¡$names alcanzó $points puntos!';
  }

  @override
  String get kotcEjectReturn => 'Serán expulsados y volverán a la cola.';

  @override
  String get kotcEjectTeamTitle => '¿Expulsar equipo?';

  @override
  String kotcEjectTeamBodyPoints(int pts) {
    return 'El equipo actual será expulsado. Sus $pts pts serán registrados.';
  }

  @override
  String get kotcEjectTeamBodyNoPoints =>
      'El equipo actual será expulsado y volverá a la cola.';

  @override
  String get kotcLeaveTitle => '¿Salir sin expulsar?';

  @override
  String kotcLeaveBodyPoints(int pts) {
    return 'El equipo tiene $pts puntos sin guardar. Salir ahora los descartará. Expulsa primero el equipo para guardar su puntuación.';
  }

  @override
  String get kotcTournamentComplete => 'Torneo completado';

  @override
  String kotcGamesSummary(int games, int pts) {
    return '$games juegos · $pts pts en total';
  }

  @override
  String get kotcStatGames => 'Juegos';

  @override
  String get kotcStatWins => 'Victorias';

  @override
  String get kotcStatPts => 'Pts';

  @override
  String get kotcOptions => 'Opciones';

  @override
  String get kotcHistorySubtitle => 'Ver todos los juegos completados';

  @override
  String get kotcTeamEjected => 'Equipo\nExpulsado';

  @override
  String get kotcUndoEject => 'Deshacer\nExpulsión';

  @override
  String get kotcUndoLastEjection => 'Deshacer última expulsión';

  @override
  String get kotcUpNext => 'A continuación';

  @override
  String get kotcChallengers => 'Retadores';

  @override
  String get kotcWaitingForPlayers => 'Esperando jugadores...';

  @override
  String kotcStrikePoints(int n) {
    return '$n pts strike';
  }

  @override
  String get kotcAdd4Random => 'Añadir 4 aleatorios';

  @override
  String kotcExistingPlayers(int n) {
    return 'Jugadores existentes ($n)';
  }

  @override
  String get kotcPlayerNameHint => 'Nombre del jugador';

  @override
  String get labelEject => 'Expulsar';

  @override
  String get kotcSetupStyleLabel => 'Estilo';

  @override
  String get kotcSetupStyleHelp =>
      'El formato de cada juego — 2vs2, 3vs3, etc. Define cuántos jugadores forman cada equipo en pista.';

  @override
  String get kotcSetupAssignmentLabel => 'Asignación';

  @override
  String get kotcSetupAssignmentHelp =>
      'Cómo se elige el siguiente equipo de pista.\n\nManual — el entrenador selecciona jugadores de la cola tocándolos.\n\nAutomático — TournaQ sugiere el mejor equipo, priorizando a los jugadores que han esperado más tiempo y no han sido emparejados recientemente.\n\nAutomático — Todos juegan — como Automático pero sin entrenador dedicado. Un admin rotativo lleva el marcador mientras todos los demás juegan.';

  @override
  String get kotcSetupPlayersHelp =>
      'Número objetivo de jugadores para la sesión. Se usa al rellenar con jugadores aleatorios. Los participantes reales se añaden en la sección Jugadores.';

  @override
  String get kotcSetupTimeHelp =>
      'Duración total de la sesión. El temporizador cuenta regresivamente desde este valor. Cuando se acabe el tiempo, se te pedirá completar el torneo o seguir jugando.';

  @override
  String get kotcSetupStrikeLabel => 'Puntos de strike (0 = off)';

  @override
  String get kotcSetupStrikeHelp =>
      'Puntos que un equipo debe marcar para ganar el juego y ser expulsado como ganadores. Ponlo en 0 para desactivar — los equipos permanecen en pista hasta que el entrenador los expulse manualmente.';

  @override
  String get kotcHistoryWon => 'Ganado';

  @override
  String get kotcHistoryNoGames => 'Aún no hay juegos.';

  @override
  String get kotcHistoryNoGamesSubtitle =>
      'Los juegos aparecerán aquí cuando se expulse un equipo.';

  @override
  String get setupPlayersPerSide => 'Jugadores por lado';

  @override
  String get setupAppliesToLast => 'Se aplica a las últimas';

  @override
  String get setupScheduleLabel => 'Horario';

  @override
  String get setupScheduleSoft => 'Horario flexible';

  @override
  String get setupScheduleForced => 'Horario fijo';

  @override
  String get setupAddBreak => 'Añadir pausa';

  @override
  String setupBreakMins(int mins) {
    return '$mins min pausa';
  }

  @override
  String setupStartsAt(String date) {
    return 'Empieza: $date';
  }

  @override
  String setupMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos',
      one: '1 partido',
    );
    return '$_temp0';
  }

  @override
  String get setupRoundPlayIn => 'Play-in';

  @override
  String get setupRoundFinal => 'Final';

  @override
  String get setupRoundSemiFinal => 'Semifinal';

  @override
  String get setupRoundQuarterFinal => 'Cuartos de final';

  @override
  String setupRoundN(int n) {
    return 'Ronda $n';
  }

  @override
  String setupPlayerN(int n) {
    return 'Jugador $n';
  }

  @override
  String get koEditTeam => 'Editar equipo';

  @override
  String get koTeamSetupSubtitle => '¿Cómo quieres configurar este equipo?';

  @override
  String get koCreateNew => 'Editar manualmente';

  @override
  String get koCreateNewSubtitle =>
      'Establece un nombre personalizado y asigna jugadores manualmente';

  @override
  String get koImportFromHub => 'Importar desde el Hub de Equipos';

  @override
  String get koImportFromHubSubtitle =>
      'Elige un equipo existente — nombre y jugadores se completan automáticamente';

  @override
  String get koNoTeamsInHub =>
      'Aún no hay equipos en el Hub de Equipos.\nCrea equipos primero en la sección de Equipos.';

  @override
  String get koPlayersSection => 'Jugadores';

  @override
  String koSkillRating(Object rating) {
    return 'Habilidad: $rating';
  }

  @override
  String get koUnrated => 'Sin calificación';

  @override
  String get koTapToAssign => 'Toca para asignar';

  @override
  String get koImportTitle => 'Importar desde el Hub de Equipos';

  @override
  String get koNoTeamsFound => 'No se encontraron equipos.';

  @override
  String koPlayerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '1 jugador',
    );
    return '$_temp0';
  }

  @override
  String koAddTeamN(int n) {
    return 'Añadir equipo $n';
  }

  @override
  String get koAddTeamSubtitle => '¿Cómo quieres añadir este equipo?';

  @override
  String get koFromTeamsHub => 'Desde el Hub de Equipos';

  @override
  String get koFromTeamsHubSubtitle => 'Elige un equipo existente de tu hub';

  @override
  String get koNoTeamsInHubYet => 'Aún no hay equipos en el hub.';

  @override
  String get koNoTeamsInHubYetShort => 'Aún no hay equipos en el hub';

  @override
  String get koCreateNewTeamTitle => 'Crear nuevo equipo';

  @override
  String get koAddTeamBtn => 'Añadir equipo';

  @override
  String get koFromPlayersHub => 'B — Desde el Hub de Jugadores';

  @override
  String get koNoPlayersInHub => 'Aún no hay jugadores en el hub.';

  @override
  String get koNoPlayersFound => 'No se encontraron jugadores.';

  @override
  String get koEditPlayer => 'Editar jugador';

  @override
  String get koPlayerNameLabel => 'Nombre';

  @override
  String get koSkillRatingOptional => 'Calificación de habilidad (opcional)';

  @override
  String get koSectionAEditPlayer => 'A — Editar jugador';

  @override
  String get koSectionANewPlayer => 'A — Nuevo jugador';

  @override
  String get koSectionBNewPlayer => 'B — Nuevo jugador';

  @override
  String get koSectionCFromHub => 'C — Desde el Hub de Jugadores';

  @override
  String get quickGameSettingsTitle => 'Configuración del juego';

  @override
  String get quickGamePlayersPerSide => 'Jugadores por lado';

  @override
  String get quickGameFormatLabel => 'Formato';

  @override
  String get quickGameTeamsTitle => 'Equipos';

  @override
  String get quickGameTapToConfigure => 'Toca para configurar el equipo';

  @override
  String get adminHelpBody =>
      'Gestiona jugadores, equipos y grupos para configurar eficientemente tus juegos y torneos.';

  @override
  String get adminInfoTooltip => 'Acerca de la Administración';

  @override
  String get adminManagePlayers => 'Gestionar perfiles de jugadores';

  @override
  String get adminManageTeams => 'Gestionar equipos y plantillas';

  @override
  String get adminManageGroups => 'Gestionar grupos y afiliaciones';

  @override
  String get playerHubSubtitle => 'Tu pool global de jugadores';

  @override
  String get teamHubSubtitle => 'Tu pool global de equipos';

  @override
  String get groupHubSubtitle => 'Tu pool global de grupos';

  @override
  String get modeQuickGamesName => 'Quick Games';

  @override
  String get modeSocialScramblesName => 'Social Scrambles';

  @override
  String get modeKotcName => 'King of the Court';

  @override
  String get modeDoghouseName => 'Doghouse';

  @override
  String get modeLeagueName => 'Liga';

  @override
  String get modeLeagueFullName => 'Liga / Round Robin';

  @override
  String get modeSingleElimName => 'Eliminación Simple';

  @override
  String get modeDoubleElimName => 'Eliminación Doble';

  @override
  String get modeGroupSeName => 'Grupo + ES';

  @override
  String get modeGroupSeFullName => 'Grupo + Eliminación Simple';

  @override
  String get modeGroupDeName => 'Grupo + ED';

  @override
  String get modeGroupDeFullName => 'Grupo + Eliminación Doble';

  @override
  String get modeSwissName => 'Sistema Suizo';

  @override
  String get modeComingSoonHelp => 'Descripción detallada próximamente.';

  @override
  String get modeQuickGamesHelp =>
      'Quick Games te permite iniciar un partido puntuado al instante — sin configuración de torneo. Elige dos equipos, establece el formato y empieza a registrar el marcador de inmediato.\n\nIdeal para juego casual, sesiones de entrenamiento o cuando simplemente quieras disputar un partido sin bracket.';

  @override
  String get modeSocialScramblesHelp =>
      'Social Scrambles es un mixer rotativo cronometrado donde los equipos se redistribuyen aleatoriamente cada ronda. Nadie permanece como compañero mucho tiempo — el objetivo es jugar con y contra la mayor cantidad de personas posible.\n\nPerfecto para sesiones de playa, días abiertos o cualquier grupo que quiera juego competitivo sin la presión de un bracket fijo.\n\nJusto por diseño. TournaQ programa a cada jugador en el máximo número de rondas manteniendo los tiempos de espera lo más cortos posible.\n\nCómo funciona una ronda:\n• Los equipos se sortean aleatoriamente al inicio de cada ronda\n• Todas las pistas juegan simultáneamente durante la duración establecida\n• Un breve descanso precede a la siguiente ronda\n• Las victorias acumuladas se registran en todas las rondas\n\nAgrega tus jugadores, configura el temporizador — y a jugar.';

  @override
  String get modeKotcHelp =>
      'King of the Court es una competición individual rápida donde cada jugador lucha por la corona. Los jugadores rotan en grupos, ganando puntos por cada rally — el ranking es completamente personal.\n\nFormato corto, alta energía — perfecto como calentamiento o competición independiente.\n\nJusto por diseño. La asignación automática de TournaQ garantiza que todos jueguen con y contra personas distintas.\n\nCómo funciona un juego:\n• Ganar un rally → cada jugador de ese lado anota un punto\n• Alcanzar el objetivo de Strike Points → el grupo actual gana, todos vuelven a la cola\n• El coach expulsa manualmente → el turno termina, puntos registrados\n• Los siguientes jugadores entran inmediatamente\n\nAntes de empezar, acuerda:\n• Quién saca cada rally\n• Si usar Strike Points y cuál es el objetivo\n\nAgrega tus jugadores, configura el temporizador — y a jugar.';

  @override
  String get modeDoghouseHelp =>
      'Doghouse es un torneo competitivo rápido donde la acción nunca se detiene. Un equipo lucha desde el doghouse — anota suficientes puntos para escapar y abrir paso a los próximos retadores.\n\nFormato corto, alta intensidad — genial como calentamiento o competición independiente.\n\nJusto por diseño. La asignación automática de TournaQ garantiza que todos jueguen con y contra personas distintas.\n\nCómo funciona un juego:\n• Ganar un rally → anotar un punto\n• Perder un rally → juego perdido, puntos reiniciados\n• Alcanzar el objetivo de Escape Points → escapado, de vuelta a la cola\n• Alcanzar el Límite de Derrotas → expulsado, entra el siguiente equipo\n\nAntes de empezar, acuerda:\n• Qué equipo saca cada rally\n• Configuración de Escape Points y Límite de Derrotas\n\nAgrega tus jugadores, configura el temporizador — y a jugar.';
}

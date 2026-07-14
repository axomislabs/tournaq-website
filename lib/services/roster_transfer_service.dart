import 'package:excel/excel.dart';

import '../models/player.dart';
import '../state/app_state.dart';
import 'app_data_service.dart';
import 'device_id_service.dart';

/// The computed result of parsing a roster spreadsheet — a *plan* the UI can
/// summarize and confirm before it is applied. Nothing is persisted here; the
/// caller pushes [newState] through the normal `onAppStateChanged` chain.
class RosterImportPlan {
  final AppState newState;
  final int playersCreated;
  final int playersUpdated;

  /// Names of existing players that a mirror import would delete (populated
  /// only when [mirrorEligible]). Shown, and confirmed, before deletion.
  final List<String> playersToDelete;
  final int teamsCreated;
  final int groupsCreated;

  /// Rows that carried some data but no player name.
  final int rowsSkipped;

  /// True when the file is a full-roster export from *this* device, which is
  /// the only case where absent players are mirror-deleted.
  final bool mirrorEligible;
  final List<String> warnings;

  /// Non-null when the file could not be read as a roster spreadsheet.
  final String? error;

  const RosterImportPlan({
    required this.newState,
    this.playersCreated = 0,
    this.playersUpdated = 0,
    this.playersToDelete = const [],
    this.teamsCreated = 0,
    this.groupsCreated = 0,
    this.rowsSkipped = 0,
    this.mirrorEligible = false,
    this.warnings = const [],
    this.error,
  });

  factory RosterImportPlan.invalid(AppState state, String error) =>
      RosterImportPlan(newState: state, error: error);

  bool get isValid => error == null;
  int get playersDeleted => playersToDelete.length;
  bool get hasChanges =>
      playersCreated > 0 ||
      playersUpdated > 0 ||
      playersToDelete.isNotEmpty ||
      teamsCreated > 0 ||
      groupsCreated > 0;
}

/// Builds and parses the Excel roster template/export.
///
/// Format: a `Players` sheet (one row per player) plus an `Instructions` sheet
/// and a machine-only `_tournaq` marker sheet. Import keys on the immutable
/// [Player.id] carried in the `ID` column: blank ⇒ create, matched ⇒ edit
/// (rename-safe). Deletion is mirror-by-absence, enabled only for a
/// full-roster export from the same device (see [RosterImportPlan.mirrorEligible]).
class RosterTransferService {
  RosterTransferService._();

  static const _sheetPlayers = 'Players';
  static const _sheetInstructions = 'Instructions';
  static const _sheetMeta = '_tournaq';
  static const _token = 'tournaq.roster';
  static const _schemaVersion = 1;
  static const _multiSep = ';';

  static const _colId = 0;
  static const _colName = 1;
  static const _colEmail = 2;
  static const _colSkill = 3;
  static const _colTeams = 4;
  static const _colGroups = 5;

  /// Column headers, in order. English and stable — parsing keys on column
  /// position, not on these labels.
  static const List<String> headers = [
    'ID',
    'Player',
    'Email',
    'Skill (1-10)',
    'Teams',
    'Groups',
  ];

  // ── Build: template ────────────────────────────────────────────────────────

  /// A blank template: headers only, `scope: template` (so it can never trigger
  /// a mirror-delete), plus an Instructions sheet.
  static List<int> buildTemplate() {
    final excel = Excel.createExcel();
    excel[_sheetPlayers].appendRow(_headerRow());
    _writeInstructions(excel);
    _writeMeta(excel, scope: 'template', deviceId: '', playerCount: 0);
    _removeExtraSheets(excel);
    return excel.encode()!;
  }

  // ── Build: export ──────────────────────────────────────────────────────────

  /// The current roster as a filled, re-importable file. Writes each player's
  /// [Player.id] into the `ID` column and marks the file as a `full-roster`
  /// export from this device. [deviceId] overrides the recorded origin (tests).
  static List<int> export(AppState state, {String? deviceId}) {
    final excel = Excel.createExcel();
    final sheet = excel[_sheetPlayers];
    sheet.appendRow(_headerRow());
    for (final p in state.players) {
      final teamNames = p.teamIds
          .map((id) => state.getTeamById(id)?.name)
          .whereType<String>()
          .toList();
      final groupNames =
          state.getPlayerGroups(p.id).map((g) => g.name).toList();
      sheet.appendRow(<CellValue?>[
        TextCellValue(p.id),
        TextCellValue(p.name),
        TextCellValue(p.email ?? ''),
        p.skillRating != null ? IntCellValue(p.skillRating!) : null,
        TextCellValue(teamNames.join('$_multiSep ')),
        TextCellValue(groupNames.join('$_multiSep ')),
      ]);
    }
    _writeInstructions(excel);
    _writeMeta(
      excel,
      scope: 'full-roster',
      deviceId: deviceId ?? DeviceIdService.currentDeviceId,
      playerCount: state.players.length,
    );
    _removeExtraSheets(excel);
    return excel.encode()!;
  }

  // ── Parse: import ──────────────────────────────────────────────────────────

  /// [deviceId] overrides this device's id used for the same-device mirror gate
  /// (tests); production passes nothing and uses [DeviceIdService.currentDeviceId].
  static RosterImportPlan parse(AppState state, List<int> bytes, {String? deviceId}) {
    final Excel excel;
    final Sheet? players;
    final Map<String, String> meta;
    try {
      excel = Excel.decodeBytes(bytes);
      players = excel.tables[_sheetPlayers];
      meta = _readMeta(excel);
    } catch (_) {
      return RosterImportPlan.invalid(state,
          'Could not read the file. Please choose a TournaQ .xlsx template or export.');
    }
    if (players == null) {
      return RosterImportPlan.invalid(
          state, 'No "Players" sheet was found in the file.');
    }

    final currentDevice = deviceId ?? DeviceIdService.currentDeviceId;
    final mirrorEligible = meta['token'] == _token &&
        meta['scope'] == 'full-roster' &&
        (meta['deviceId'] ?? '').isNotEmpty &&
        meta['deviceId'] == currentDevice;

    var working = state;
    final warnings = <String>[];
    var created = 0, updated = 0, rowsSkipped = 0, teamsCreated = 0, groupsCreated = 0;

    // Case-insensitive name → id indexes, grown as new entities are created so
    // repeated names within the file collapse onto one entity.
    final teamByName = <String, String>{};
    for (final t in working.teams) {
      teamByName.putIfAbsent(t.name.toLowerCase(), () => t.id);
    }
    final groupByName = <String, String>{};
    for (final g in working.groups) {
      groupByName.putIfAbsent(g.name.toLowerCase(), () => g.id);
    }

    final existingIds = {for (final p in state.players) p.id};
    final seenIds = <String>{}; // every non-blank ID seen (for dedup + mirror)

    final rows = players.rows;
    for (var r = 0; r < rows.length; r++) {
      if (r == 0) continue; // header
      final row = rows[r];
      final name = _cell(row, _colName);
      if (name.isEmpty) {
        if (_rowHasData(row)) rowsSkipped++;
        continue;
      }
      final id = _cell(row, _colId);
      final email = _cell(row, _colEmail);
      final skill = _parseSkill(_cell(row, _colSkill));

      String playerId;
      if (id.isEmpty) {
        playerId = AppState.generateId();
        working = working.addPlayer(_newPlayer(playerId, name, email, skill));
        created++;
      } else if (seenIds.contains(id)) {
        warnings.add('Duplicate ID for "$name" — row ignored.');
        continue;
      } else if (existingIds.contains(id)) {
        seenIds.add(id);
        final existing = working.getPlayerById(id)!;
        working = working.updatePlayer(existing.copyWith(
          name: name,
          email: email.isEmpty ? null : email,
          skillRating: skill,
          clearSkillRating: skill == null,
        ));
        playerId = id;
        updated++;
      } else {
        seenIds.add(id);
        playerId = AppState.generateId();
        working = working.addPlayer(_newPlayer(playerId, name, email, skill));
        created++;
        warnings.add('Unrecognized ID for "$name" — added as a new player.');
      }

      // Resolve/create the row's teams and groups, then apply authoritatively.
      final teamIds = <String>{};
      for (final tn in _splitMulti(_cell(row, _colTeams))) {
        final key = tn.toLowerCase();
        var tid = teamByName[key];
        if (tid == null) {
          working = AppDataService.createTeam(working, name: tn);
          tid = working.teams.last.id;
          teamByName[key] = tid;
          teamsCreated++;
        }
        teamIds.add(tid);
      }
      final groupIds = <String>{};
      for (final gn in _splitMulti(_cell(row, _colGroups))) {
        final key = gn.toLowerCase();
        var gid = groupByName[key];
        if (gid == null) {
          working = AppDataService.createGroup(working, name: gn);
          gid = working.groups.last.id;
          groupByName[key] = gid;
          groupsCreated++;
        }
        groupIds.add(gid);
      }
      working = _applyMemberships(working, playerId, teamIds, groupIds);
    }

    // Mirror deletion: existing players whose ID never appeared in the sheet.
    final toDeleteNames = <String>[];
    if (mirrorEligible) {
      final deleteIds = <String>[];
      for (final p in state.players) {
        if (!seenIds.contains(p.id)) {
          deleteIds.add(p.id);
          toDeleteNames.add(p.name);
        }
      }
      for (final did in deleteIds) {
        working = AppDataService.deleteUser(working, did);
      }
    }

    return RosterImportPlan(
      newState: working,
      playersCreated: created,
      playersUpdated: updated,
      playersToDelete: toDeleteNames,
      teamsCreated: teamsCreated,
      groupsCreated: groupsCreated,
      rowsSkipped: rowsSkipped,
      mirrorEligible: mirrorEligible,
      warnings: warnings,
    );
  }

  // ── internals ──────────────────────────────────────────────────────────────

  static Player _newPlayer(String id, String name, String email, int? skill) =>
      Player(
        id: id,
        name: name,
        email: email.isEmpty ? null : email,
        skillRating: skill,
      );

  /// Sets [playerId]'s team and group membership to exactly [teamIds]/[groupIds]
  /// (authoritative): listed links are added, unlisted ones removed.
  static AppState _applyMemberships(
    AppState state,
    String playerId,
    Set<String> teamIds,
    Set<String> groupIds,
  ) {
    var s = state;
    final player = s.getPlayerById(playerId);
    if (player == null) return s;

    final currentTeams = player.teamIds.toSet();
    for (final tid in teamIds.difference(currentTeams)) {
      s = AppDataService.assignUserToTeam(s, userId: playerId, teamId: tid);
    }
    for (final tid in currentTeams.difference(teamIds)) {
      s = AppDataService.removeUserFromTeam(s, userId: playerId, teamId: tid);
    }

    final currentGroups = s.getPlayerGroups(playerId).map((g) => g.id).toSet();
    for (final gid in groupIds.difference(currentGroups)) {
      s = AppDataService.assignPlayerToGroup(s, playerId: playerId, groupId: gid);
    }
    for (final gid in currentGroups.difference(groupIds)) {
      s = AppDataService.removePlayerFromGroup(s, playerId: playerId, groupId: gid);
    }
    return s;
  }

  static List<CellValue?> _headerRow() =>
      headers.map<CellValue?>((h) => TextCellValue(h)).toList();

  static void _writeInstructions(Excel excel) {
    final s = excel[_sheetInstructions];
    const lines = <String>[
      'TournaQ — Roster import / export',
      '',
      'Edit the "Players" sheet. One row per player.',
      'Columns:',
      'ID — leave blank for a NEW player. Do NOT change the ID of an existing '
          'player; it identifies the record. Renaming a player is fine — just keep its ID.',
      'Player — the player name (required).',
      'Email — optional.',
      'Skill (1-10) — optional whole number from 1 to 10.',
      'Teams — optional. One or more team names separated by a semicolon (;). '
          'Teams that do not exist yet are created automatically.',
      'Groups — optional. One or more group names separated by a semicolon (;). '
          'Groups that do not exist yet are created automatically.',
      '',
      'To DELETE a player: delete their whole row before re-importing. This only '
          'takes effect when re-importing a full export made on this same device.',
      '',
      'Do not edit or remove the hidden "_tournaq" sheet.',
    ];
    for (final line in lines) {
      s.appendRow(<CellValue?>[TextCellValue(line)]);
    }
  }

  static void _writeMeta(
    Excel excel, {
    required String scope,
    required String deviceId,
    required int playerCount,
  }) {
    final s = excel[_sheetMeta];
    void kv(String k, String v) =>
        s.appendRow(<CellValue?>[TextCellValue(k), TextCellValue(v)]);
    kv('token', _token);
    kv('schemaVersion', '$_schemaVersion');
    kv('scope', scope);
    kv('deviceId', deviceId);
    kv('exportedAt', DateTime.now().toIso8601String());
    kv('playerCount', '$playerCount');
  }

  static Map<String, String> _readMeta(Excel excel) {
    final map = <String, String>{};
    final sheet = excel.tables[_sheetMeta];
    if (sheet == null) return map;
    for (final row in sheet.rows) {
      final k = _cell(row, 0);
      if (k.isEmpty) continue;
      map[k] = _cell(row, 1);
    }
    return map;
  }

  /// `createExcel()` seeds a default sheet; drop anything that is not one of ours.
  static void _removeExtraSheets(Excel excel) {
    const keep = {_sheetPlayers, _sheetInstructions, _sheetMeta};
    for (final name in excel.sheets.keys.toList()) {
      if (!keep.contains(name) && excel.sheets.length > 1) {
        excel.delete(name);
      }
    }
  }

  static String _cell(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final v = row[col]?.value;
    if (v == null) return '';
    return v.toString().trim();
  }

  static bool _rowHasData(List<Data?> row) {
    for (var c = 0; c < headers.length; c++) {
      if (_cell(row, c).isNotEmpty) return true;
    }
    return false;
  }

  static List<String> _splitMulti(String cell) {
    if (cell.trim().isEmpty) return const [];
    return cell
        .split(_multiSep)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int? _parseSkill(String s) {
    if (s.trim().isEmpty) return null;
    final d = double.tryParse(s.trim());
    if (d == null) return null;
    final i = d.round();
    if (i < 1 || i > 10) return null;
    return i;
  }
}

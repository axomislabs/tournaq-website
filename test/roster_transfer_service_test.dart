import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/services/app_data_service.dart';
import 'package:tournaq/services/roster_transfer_service.dart';
import 'package:tournaq/state/app_state.dart';

const _dev = 'device-A';

/// Builds a Players workbook with arbitrary rows + a `_tournaq` marker so we can
/// exercise import scenarios directly. `null` cells are left empty.
List<int> _buildImport(
  List<List<String?>> rows, {
  required String scope,
  String deviceId = _dev,
}) {
  final excel = Excel.createExcel();
  final players = excel['Players'];
  players.appendRow(
      RosterTransferService.headers.map<CellValue?>((h) => TextCellValue(h)).toList());
  for (final row in rows) {
    players.appendRow(
        row.map<CellValue?>((c) => c == null ? null : TextCellValue(c)).toList());
  }
  final meta = excel['_tournaq'];
  void kv(String k, String v) =>
      meta.appendRow(<CellValue?>[TextCellValue(k), TextCellValue(v)]);
  kv('token', 'tournaq.roster');
  kv('schemaVersion', '1');
  kv('scope', scope);
  kv('deviceId', deviceId);
  kv('exportedAt', DateTime(2026, 7, 13).toIso8601String());
  kv('playerCount', '${rows.length}');
  for (final name in excel.sheets.keys.toList()) {
    if (name != 'Players' && name != '_tournaq' && excel.sheets.length > 1) {
      excel.delete(name);
    }
  }
  return excel.encode()!;
}

/// A small roster: Anna (Falcons, U18) and Ben (Falcons).
({AppState state, String anna, String ben, String falcons, String u18}) _sample() {
  var s = const AppState();
  s = AppDataService.createUser(s, name: 'Anna');
  final anna = s.players.last.id;
  s = AppDataService.createUser(s, name: 'Ben');
  final ben = s.players.last.id;
  s = AppDataService.createTeam(s, name: 'Falcons');
  final falcons = s.teams.last.id;
  s = AppDataService.createGroup(s, name: 'U18');
  final u18 = s.groups.last.id;
  s = AppDataService.assignUserToTeam(s, userId: anna, teamId: falcons);
  s = AppDataService.assignUserToTeam(s, userId: ben, teamId: falcons);
  s = AppDataService.assignPlayerToGroup(s, playerId: anna, groupId: u18);
  return (state: s, anna: anna, ben: ben, falcons: falcons, u18: u18);
}

void main() {
  group('RosterTransferService', () {
    test('template import creates and deletes nothing', () {
      final sample = _sample();
      final plan = RosterTransferService.parse(
          sample.state, RosterTransferService.buildTemplate(),
          deviceId: _dev);

      expect(plan.isValid, isTrue);
      expect(plan.mirrorEligible, isFalse); // template scope never mirrors
      expect(plan.playersCreated, 0);
      expect(plan.playersToDelete, isEmpty);
      expect(plan.newState.players.length, 2);
    });

    test('export → import round-trip is a no-op (same device)', () {
      final sample = _sample();
      final bytes = RosterTransferService.export(sample.state, deviceId: _dev);
      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);

      expect(plan.mirrorEligible, isTrue);
      expect(plan.playersCreated, 0);
      expect(plan.playersToDelete, isEmpty);
      expect(plan.teamsCreated, 0);
      expect(plan.groupsCreated, 0);
      expect(plan.newState.players.length, 2);
      // Memberships preserved.
      final anna = plan.newState.getPlayerById(sample.anna)!;
      expect(anna.teamIds, contains(sample.falcons));
      expect(plan.newState.getPlayerGroups(sample.anna).map((g) => g.id),
          contains(sample.u18));
    });

    test('blank ID creates players; multi-value cells share entities', () {
      final bytes = _buildImport([
        [null, 'Anna', 'anna@x.de', '7', 'Falcons', 'U18;Regional'],
        [null, 'Ben', null, null, 'Falcons', 'Regional'],
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(const AppState(), bytes, deviceId: _dev);

      expect(plan.playersCreated, 2);
      expect(plan.teamsCreated, 1); // Falcons shared
      expect(plan.groupsCreated, 2); // U18 + Regional
      final s = plan.newState;
      expect(s.players.length, 2);
      final anna = s.players.firstWhere((p) => p.name == 'Anna');
      expect(anna.skillRating, 7);
      expect(anna.email, 'anna@x.de');
      final falcons = s.teams.firstWhere((t) => t.name == 'Falcons');
      expect(falcons.userIds.length, 2); // both players
      final regional = s.groups.firstWhere((g) => g.name == 'Regional');
      expect(regional.playerIds.length, 2);
      final u18 = s.groups.firstWhere((g) => g.name == 'U18');
      expect(u18.playerIds.length, 1); // Anna only
    });

    test('matched ID edits in place: rename keeps the id and memberships', () {
      final sample = _sample();
      final bytes = _buildImport([
        [sample.anna, 'Anna-Renamed', null, null, 'Falcons', 'U18'],
        [sample.ben, 'Ben', null, null, 'Falcons', null],
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);

      expect(plan.playersCreated, 0);
      expect(plan.playersUpdated, 2);
      expect(plan.playersToDelete, isEmpty);
      final anna = plan.newState.getPlayerById(sample.anna)!;
      expect(anna.name, 'Anna-Renamed'); // same id, new name
      expect(anna.teamIds, contains(sample.falcons));
      expect(plan.newState.getPlayerGroups(sample.anna).map((g) => g.id),
          contains(sample.u18));
    });

    test('authoritative membership removes an unlisted team', () {
      final sample = _sample();
      // Ben's row lists no teams → he should be removed from Falcons.
      final bytes = _buildImport([
        [sample.anna, 'Anna', null, null, 'Falcons', 'U18'],
        [sample.ben, 'Ben', null, null, null, null],
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);
      final ben = plan.newState.getPlayerById(sample.ben)!;
      expect(ben.teamIds, isNot(contains(sample.falcons)));
      final falcons = plan.newState.getTeamById(sample.falcons)!;
      expect(falcons.userIds, isNot(contains(sample.ben)));
    });

    test('mirror deletes an absent player (full export, same device)', () {
      final sample = _sample();
      final bytes = _buildImport([
        [sample.anna, 'Anna', null, null, 'Falcons', 'U18'],
        // Ben omitted
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);

      expect(plan.mirrorEligible, isTrue);
      expect(plan.playersToDelete, ['Ben']);
      expect(plan.newState.players.map((p) => p.id), isNot(contains(sample.ben)));
      expect(plan.newState.players.length, 1);
      // Ben also stripped from Falcons.
      expect(plan.newState.getTeamById(sample.falcons)!.userIds,
          isNot(contains(sample.ben)));
    });

    test('mirror is disabled for a foreign-device export', () {
      final sample = _sample();
      final bytes = _buildImport([
        [sample.anna, 'Anna', null, null, 'Falcons', 'U18'],
      ], scope: 'full-roster', deviceId: 'device-OTHER');

      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);

      expect(plan.mirrorEligible, isFalse);
      expect(plan.playersToDelete, isEmpty);
      expect(plan.newState.players.length, 2); // Ben survives
    });

    test('mirror is disabled for template scope even on same device', () {
      final sample = _sample();
      final bytes = _buildImport([
        [sample.anna, 'Anna', null, null, 'Falcons', 'U18'],
      ], scope: 'template');

      final plan = RosterTransferService.parse(sample.state, bytes, deviceId: _dev);

      expect(plan.mirrorEligible, isFalse);
      expect(plan.newState.players.length, 2);
    });

    test('unrecognized ID becomes a new player with a warning', () {
      final bytes = _buildImport([
        ['bogus-id', 'Zoe', null, null, null, null],
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(const AppState(), bytes, deviceId: _dev);

      expect(plan.playersCreated, 1);
      expect(plan.warnings, isNotEmpty);
      final zoe = plan.newState.players.single;
      expect(zoe.name, 'Zoe');
      expect(zoe.id, isNot('bogus-id')); // fresh UUID assigned
    });

    test('blank-name rows skipped and invalid skill ignored', () {
      final bytes = _buildImport([
        [null, 'Cara', null, '99', null, null], // skill out of range
        [null, null, null, '5', 'Falcons', null], // no name → skipped
      ], scope: 'full-roster');

      final plan = RosterTransferService.parse(const AppState(), bytes, deviceId: _dev);

      expect(plan.playersCreated, 1);
      expect(plan.rowsSkipped, 1);
      expect(plan.teamsCreated, 0); // skipped row didn't create Falcons
      expect(plan.newState.players.single.skillRating, isNull);
    });

    test('an unreadable file yields an invalid plan', () {
      final plan = RosterTransferService.parse(const AppState(), [1, 2, 3, 4],
          deviceId: _dev);
      expect(plan.isValid, isFalse);
      expect(plan.error, isNotNull);
    });
  });
}

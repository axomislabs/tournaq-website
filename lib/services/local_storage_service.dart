import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import 'device_id_service.dart';
import '../models/club.dart';
import '../models/game.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../state/app_state.dart';
import 'scramble_storage_service.dart';
import 'king_of_the_court_storage_service.dart';

/// Local persistence layer for TournaQ.
///
/// Wraps Hive key-value storage behind a typed interface so that the rest of
/// the app never imports Hive directly. This isolation means Hive can be
/// swapped out (or supplemented with a Firebase layer) without changing any
/// page or widget code.
///
/// Storage layout (v1):
///   games_v1        — [Game] objects, keyed by [Game.id]
///   teams_v1        — [Team] objects, keyed by [Team.id]
///   players_v1      — [Player] objects, keyed by [Player.id]
///   clubs_v1        — [Club] objects, keyed by [Club.id]
///   tournaments_v1  — [Tournament] objects, keyed by [Tournament.id]
///   prefs_v1        — Arbitrary string key→value preferences (e.g. rating counts)
///
/// Design decision — full-state save vs. granular ops:
///   [saveAppState] clears and rewrites all boxes on each change. This is
///   simple and correct for v1 data volumes (hundreds of records). If
///   write frequency or record counts grow, replace with the granular
///   [saveGame]/[saveTeam]/[savePlayer] calls instead.
///
/// Firebase readiness:
///   Introduce a Repository interface (e.g. GameRepository) above this class
///   before Firebase migration. The repository pattern lets you run Hive and
///   Firestore simultaneously during a transition period.
class LocalStorageService {
  static const _gamesBox = 'games_v1';
  static const _teamsBox = 'teams_v1';
  static const _playersBox = 'players_v1';
  static const _clubsBox = 'clubs_v1';
  static const _tournamentsBox = 'tournaments_v1';
  static const _prefsBox = 'prefs_v1';

  // ── Initialisation ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_gamesBox);
    await Hive.openBox<String>(_teamsBox);
    await Hive.openBox<String>(_playersBox);
    await Hive.openBox<String>(_clubsBox);
    await Hive.openBox<String>(_tournamentsBox);
    await Hive.openBox<String>(_prefsBox);
    await DeviceIdService.init();
    await ScrambleStorageService.init();
    await KingOfTheCourtStorageService.init();
  }

  // ── Box accessors ──────────────────────────────────────────────────────────

  static Box<String> get _games => Hive.box<String>(_gamesBox);
  static Box<String> get _teams => Hive.box<String>(_teamsBox);
  static Box<String> get _players => Hive.box<String>(_playersBox);
  static Box<String> get _clubs => Hive.box<String>(_clubsBox);
  static Box<String> get _tournaments => Hive.box<String>(_tournamentsBox);
  static Box<String> get _prefs => Hive.box<String>(_prefsBox);

  // ── Load ───────────────────────────────────────────────────────────────────

  static AppState loadAppState() {
    final games = _games.values
        .map((s) => _tryDecode(s, Game.fromJson))
        .whereType<Game>()
        .toList();
    final teams = _teams.values
        .map((s) => _tryDecode(s, Team.fromJson))
        .whereType<Team>()
        .toList();
    final players = _players.values
        .map((s) => _tryDecode(s, Player.fromJson))
        .whereType<Player>()
        .toList();
    final clubs = _clubs.values
        .map((s) => _tryDecode(s, Club.fromJson))
        .whereType<Club>()
        .toList();
    final tournaments = _tournaments.values
        .map((s) => _tryDecode(s, Tournament.fromJson))
        .whereType<Tournament>()
        .toList();

    return AppState(
      games: games,
      teams: teams,
      players: players,
      clubs: clubs,
      tournaments: tournaments,
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  static Future<void> saveAppState(AppState state) async {
    await _games.clear();
    for (final g in state.games) {
      await _games.put(g.id, jsonEncode(g.toJson()));
    }
    await _teams.clear();
    for (final t in state.teams) {
      await _teams.put(t.id, jsonEncode(t.toJson()));
    }
    await _players.clear();
    for (final u in state.players) {
      await _players.put(u.id, jsonEncode(u.toJson()));
    }
    await _clubs.clear();
    for (final c in state.clubs) {
      await _clubs.put(c.id, jsonEncode(c.toJson()));
    }
    await _tournaments.clear();
    for (final t in state.tournaments) {
      await _tournaments.put(t.id, jsonEncode(t.toJson()));
    }
  }

  // ── Granular ops ───────────────────────────────────────────────────────────

  static Future<void> saveGame(Game game) async =>
      _games.put(game.id, jsonEncode(game.toJson()));

  static Future<void> deleteGame(String id) async => _games.delete(id);

  static Future<void> saveTeam(Team team) async =>
      _teams.put(team.id, jsonEncode(team.toJson()));

  static Future<void> deleteTeam(String id) async => _teams.delete(id);

  static Future<void> savePlayer(Player player) async =>
      _players.put(player.id, jsonEncode(player.toJson()));

  static Future<void> deletePlayer(String id) async => _players.delete(id);

  static String? getPref(String key) => _prefs.get(key);
  static Future<void> setPref(String key, String value) => _prefs.put(key, value);

  static Future<void> clearHistoryData() async {
    await _games.clear();
    await _teams.clear();
    await _players.clear();
    await _clubs.clear();
    await _tournaments.clear();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static T? _tryDecode<T>(String raw, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

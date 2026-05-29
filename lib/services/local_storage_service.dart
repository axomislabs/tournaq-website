import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_user.dart';
import '../models/game.dart';
import '../models/team.dart';
import '../state/app_state.dart';

class LocalStorageService {
  static const _gamesBox = 'games_v1';
  static const _teamsBox = 'teams_v1';
  static const _playersBox = 'players_v1';
  static const _prefsBox = 'prefs_v1';

  // ── Initialisation ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_gamesBox);
    await Hive.openBox<String>(_teamsBox);
    await Hive.openBox<String>(_playersBox);
    await Hive.openBox<String>(_prefsBox);
  }

  // ── Box accessors ──────────────────────────────────────────────────────────

  static Box<String> get _games => Hive.box<String>(_gamesBox);
  static Box<String> get _teams => Hive.box<String>(_teamsBox);
  static Box<String> get _players => Hive.box<String>(_playersBox);
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
        .map((s) => _tryDecode(s, AppUser.fromJson))
        .whereType<AppUser>()
        .toList();

    return AppState(games: games, teams: teams, users: players);
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
    for (final u in state.users) {
      await _players.put(u.id, jsonEncode(u.toJson()));
    }
  }

  // ── Granular ops ───────────────────────────────────────────────────────────

  static Future<void> saveGame(Game game) async =>
      _games.put(game.id, jsonEncode(game.toJson()));

  static Future<void> deleteGame(String id) async => _games.delete(id);

  static Future<void> saveTeam(Team team) async =>
      _teams.put(team.id, jsonEncode(team.toJson()));

  static Future<void> deleteTeam(String id) async => _teams.delete(id);

  static Future<void> savePlayer(AppUser player) async =>
      _players.put(player.id, jsonEncode(player.toJson()));

  static Future<void> deletePlayer(String id) async => _players.delete(id);

  static String? getPref(String key) => _prefs.get(key);
  static Future<void> setPref(String key, String value) => _prefs.put(key, value);

  static Future<void> clearHistoryData() async {
    await _games.clear();
    await _teams.clear();
    await _players.clear();
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

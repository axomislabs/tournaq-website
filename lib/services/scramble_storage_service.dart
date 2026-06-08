import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scramble_tournament.dart';

/// Hive-backed persistence for [ScrambleTournament] objects.
///
/// Stored in the `scramble_v1` box — completely separate from the main
/// AppState boxes so the scramble feature never disrupts existing data.
class ScrambleStorageService {
  ScrambleStorageService._();

  static const _boxName = 'scramble_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static List<ScrambleTournament> loadAll() {
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<ScrambleTournament>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(ScrambleTournament tournament) async {
    await _box.put(tournament.id, jsonEncode(tournament.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static ScrambleTournament? _tryDecode(String raw) {
    try {
      return ScrambleTournament.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

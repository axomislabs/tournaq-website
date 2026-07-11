import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scramble_king_tournament.dart';

class ScrambleKingStorageService {
  ScrambleKingStorageService._();

  static const _boxName = 'scramble_king_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    try {
      await Hive.openBox<String>(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      await Hive.openBox<String>(_boxName);
    }
  }

  static List<ScrambleKingTournament> loadAll() {
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<ScrambleKingTournament>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(ScrambleKingTournament tournament) async {
    await _box.put(tournament.id, jsonEncode(tournament.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static ScrambleKingTournament? _tryDecode(String raw) {
    try {
      return ScrambleKingTournament.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ko_bracket_tournament.dart';

class KoBracketStorageService {
  KoBracketStorageService._();

  static const _boxName = 'ko_bracket_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static List<KoBracketTournament> loadAll() {
    return _box.values
        .map(_tryDecode)
        .whereType<KoBracketTournament>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(KoBracketTournament tournament) async {
    await _box.put(tournament.id, jsonEncode(tournament.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static KoBracketTournament? _tryDecode(String raw) {
    try {
      return KoBracketTournament.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/king_of_the_court_tournament.dart';

class KingOfTheCourtStorageService {
  KingOfTheCourtStorageService._();

  static const _boxName = 'kotc_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static List<KingOfTheCourtTournament> loadAll() {
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<KingOfTheCourtTournament>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(KingOfTheCourtTournament session) async {
    await _box.put(session.id, jsonEncode(session.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static KingOfTheCourtTournament? _tryDecode(String raw) {
    try {
      return KingOfTheCourtTournament.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

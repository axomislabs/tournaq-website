import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/doghouse_drill.dart';

class DoghouseStorageService {
  DoghouseStorageService._();

  static const _boxName = 'doghouse_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static List<DoghouseTournament> loadAll() {
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<DoghouseTournament>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(DoghouseTournament drill) async {
    await _box.put(drill.id, jsonEncode(drill.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static DoghouseTournament? _tryDecode(String raw) {
    try {
      return DoghouseTournament.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/imported_scorecard.dart';

/// Hive-backed persistence for [ImportedScorecard] objects — scorecards this
/// device received from another device via QR.
///
/// Stored in the `scramble_imported_v1` box, kept completely separate from this
/// device's own Social Scrambles (`scramble_v1`) so imports never mix into the
/// local tournament list.
class ImportedScorecardStorageService {
  ImportedScorecardStorageService._();

  static const _boxName = 'scramble_imported_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    try {
      await Hive.openBox<String>(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      await Hive.openBox<String>(_boxName);
    }
  }

  static List<ImportedScorecard> loadAll() {
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<ImportedScorecard>()
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  static Future<void> save(ImportedScorecard scorecard) async {
    await _box.put(scorecard.id, jsonEncode(scorecard.toJson()));
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
  }

  static ImportedScorecard? _tryDecode(String raw) {
    try {
      return ImportedScorecard.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

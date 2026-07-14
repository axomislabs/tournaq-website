import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/imported_scramble_king_court.dart';

/// Hive-backed persistence for [ImportedScrambleKingCourt] objects — courts this
/// device received from another device via QR.
///
/// Stored in the `scramble_king_imported_v1` box, kept completely separate from
/// this device's own Scramble King tournaments (`scramble_king_v1`) so imports
/// never mix into the local tournament list.
class ImportedScrambleKingCourtStorageService {
  ImportedScrambleKingCourtStorageService._();

  static const _boxName = 'scramble_king_imported_v1';

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> init() async {
    try {
      await Hive.openBox<String>(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      await Hive.openBox<String>(_boxName);
    }
  }

  /// The box, opening it on demand if [init] hasn't run yet (e.g. after a hot
  /// reload that didn't re-run app startup).
  static Future<Box<String>> _ensureBox() async =>
      Hive.isBoxOpen(_boxName) ? _box : await Hive.openBox<String>(_boxName);

  static List<ImportedScrambleKingCourt> loadAll() {
    // Synchronous read — if the box isn't open yet, treat as empty rather
    // than throwing; it will be populated once startup/init has run.
    if (!Hive.isBoxOpen(_boxName)) return const [];
    return _box.values
        .map((s) => _tryDecode(s))
        .whereType<ImportedScrambleKingCourt>()
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  static Future<void> save(ImportedScrambleKingCourt court) async {
    final box = await _ensureBox();
    await box.put(court.id, jsonEncode(court.toJson()));
  }

  static Future<void> delete(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
  }

  static ImportedScrambleKingCourt? _tryDecode(String raw) {
    try {
      return ImportedScrambleKingCourt.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Generates and persists a stable installation-scoped identifier.
///
/// The device ID is a UUID v4 created once on first launch and stored in the
/// prefs_v1 Hive box. Every record created on this device carries this ID so
/// that when data from multiple offline installs is later merged or published,
/// the origin of each record is unambiguous.
///
/// Call [init] once during app startup (after the prefs_v1 box is open).
/// After that, [currentDeviceId] is synchronously available everywhere.
class DeviceIdService {
  static const _key = 'device_id';
  static String _deviceId = '';

  static String get currentDeviceId => _deviceId;

  static Future<void> init() async {
    final box = Hive.box<String>('prefs_v1');
    var id = box.get(_key);
    if (id == null) {
      id = const Uuid().v4();
      await box.put(_key, id);
    }
    _deviceId = id;
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static const _deviceIdKey = 'device_id';
  final String deviceId;

  DeviceInfoService._(this.deviceId);

  factory DeviceInfoService.ephemeral() {
    return DeviceInfoService._(_generateId());
  }

  static Future<DeviceInfoService> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      return DeviceInfoService._(stored);
    }
    final deviceId = _generateId();
    await prefs.setString(_deviceIdKey, deviceId);
    return DeviceInfoService._(deviceId);
  }

  static String _generateId() {
    final uuid = const Uuid().v4();
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    return '$platform-$uuid';
  }
}

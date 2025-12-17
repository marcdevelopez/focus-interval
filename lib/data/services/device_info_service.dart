import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  final String deviceId;

  DeviceInfoService._(this.deviceId);

  factory DeviceInfoService() {
    final uuid = const Uuid().v4();
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    return DeviceInfoService._('$platform-$uuid');
  }
}

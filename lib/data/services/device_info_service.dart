import 'dart:io';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  final String deviceId;

  DeviceInfoService._(this.deviceId);

  factory DeviceInfoService() {
    final uuid = const Uuid();
    final platform = Platform.operatingSystem;
    final id = '$platform-${uuid.v4()}';
    return DeviceInfoService._(id);
  }
}

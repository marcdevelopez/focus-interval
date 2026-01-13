import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'data/services/device_info_service.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  final deviceInfo = await _loadDeviceInfo();
  final notifications = await _initNotifications();
  runApp(
    ProviderScope(
      overrides: [
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const FocusIntervalApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  if (_isLinux) {
    // Linux desktop doesn't register Firebase plugins here yet; skip init to avoid channel errors.
    return;
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<DeviceInfoService> _loadDeviceInfo() async {
  if (_isLinux) {
    // Linux: guard startup plugin calls to avoid blocking the first frame.
    try {
      return await DeviceInfoService.load();
    } catch (e) {
      debugPrint('Device info init failed: $e');
      return DeviceInfoService.ephemeral();
    }
  }
  return DeviceInfoService.load();
}

Future<NotificationService> _initNotifications() async {
  if (_isLinux) {
    // Linux: guard startup plugin calls to avoid blocking the first frame.
    try {
      return await NotificationService.init();
    } catch (e) {
      debugPrint('Notification init failed: $e');
      return NotificationService.disabled();
    }
  }
  return NotificationService.init();
}

bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

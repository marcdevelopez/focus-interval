import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'data/services/device_info_service.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final deviceInfo = await DeviceInfoService.load();
  final notifications = await NotificationService.init();
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

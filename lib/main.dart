import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/services/device_info_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/app_mode_service.dart';
import 'data/services/firebase_auth_service.dart';
import 'data/services/firestore_service.dart';
import 'firebase_options.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_BootstrapResult> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _initFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) {
          return const _BootScreen();
        }
        return ProviderScope(
          overrides: [
            deviceInfoServiceProvider.overrideWithValue(result.deviceInfo),
            notificationServiceProvider.overrideWithValue(result.notifications),
            appModeServiceProvider.overrideWithValue(result.appModeService),
            if (!result.firebaseReady)
              firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
            if (!result.firebaseReady)
              firestoreServiceProvider.overrideWithValue(
                StubFirestoreService(),
              ),
          ],
          child: const FocusIntervalApp(),
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Starting Focus Interval...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapResult {
  final bool firebaseReady;
  final DeviceInfoService deviceInfo;
  final NotificationService notifications;
  final AppModeService appModeService;

  const _BootstrapResult({
    required this.firebaseReady,
    required this.deviceInfo,
    required this.notifications,
    required this.appModeService,
  });
}

Future<_BootstrapResult> _bootstrap() async {
  final firebaseReady = await _initFirebaseSafe();
  final deviceInfo = await _loadDeviceInfoSafe();
  final notifications = await _initNotificationsSafe();
  final appModeService = await _initAppModeServiceSafe();

  return _BootstrapResult(
    firebaseReady: firebaseReady,
    deviceInfo: deviceInfo,
    notifications: notifications,
    appModeService: appModeService,
  );
}

Future<bool> _initFirebaseSafe() async {
  if (_isLinux) {
    // Linux desktop doesn't register Firebase plugins here yet; skip init to avoid channel errors.
    return false;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    return true;
  } catch (e) {
    debugPrint('Firebase init failed or timed out: $e');
    return false;
  }
}

Future<DeviceInfoService> _loadDeviceInfoSafe() async {
  try {
    if (_isLinux || _isMacos) {
      // Desktop: guard startup plugin calls to avoid blocking the first frame.
      return await DeviceInfoService.load()
          .timeout(const Duration(seconds: 3));
    }
    return await DeviceInfoService.load()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('Device info init failed or timed out: $e');
    return DeviceInfoService.ephemeral();
  }
}

Future<NotificationService> _initNotificationsSafe() async {
  try {
    if (_isLinux || _isMacos) {
      // Desktop: guard startup plugin calls to avoid blocking the first frame.
      return await NotificationService.init()
          .timeout(const Duration(seconds: 4));
    }
    return await NotificationService.init()
        .timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Notification init failed or timed out: $e');
    return NotificationService.disabled();
  }
}

Future<AppModeService> _initAppModeServiceSafe() async {
  try {
    final prefs = await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 3));
    return AppModeService(prefs);
  } catch (e) {
    debugPrint('App mode init failed or timed out: $e');
    return AppModeService.memory();
  }
}

bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
bool get _isMacos => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

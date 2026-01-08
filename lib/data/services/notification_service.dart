import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_backends/local_notifier_backend.dart'
    if (dart.library.html) 'notification_backends/local_notifier_backend_stub.dart';

class NotificationService {
  final _NotificationBackend _backend;
  final bool enabled;
  int _nextId = 0;
  bool _permissionsRequested = false;
  bool _permissionsGranted = true;

  static const MethodChannel _macosChannel =
      MethodChannel('focus_interval/macos_notifications');

  NotificationService._(this._backend, {required this.enabled});

  static NotificationService disabled() {
    return NotificationService._(_SilentNotificationBackend(), enabled: false);
  }

  static Future<NotificationService> init() async {
    if (kIsWeb) return NotificationService.disabled();

    final backend = _createBackend();
    final ok = await backend.init();
    if (!ok) {
      final message = backend.initErrorMessage;
      if (message.isNotEmpty) {
        debugPrint(message);
      }
      return NotificationService.disabled();
    }
    return NotificationService._(backend, enabled: true);
  }

  static _NotificationBackend _createBackend() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _LocalNotifierBackend(LocalNotifierBackend());
    }
    return _FlutterLocalNotificationsBackend(
      FlutterLocalNotificationsPlugin(),
      macosChannel: _macosChannel,
    );
  }

  Future<void> requestPermissions() async {
    await _ensurePermissions();
  }

  Future<bool> _ensurePermissions() async {
    if (!enabled) return false;
    if (_permissionsRequested && _permissionsGranted) return true;
    _permissionsRequested = true;
    _permissionsGranted = await _backend.requestPermissions();
    return _permissionsGranted;
  }

  Future<void> notifyPomodoroEnd({
    required String taskName,
    required int currentPomodoro,
    required int totalPomodoros,
  }) async {
    if (!await _ensurePermissions()) return;
    final title = taskName.isNotEmpty ? taskName : 'Pomodoro completed';
    final body = 'Pomodoro $currentPomodoro of $totalPomodoros finished.';
    await _backend.show(
      id: _consumeId(),
      title: title,
      body: body,
    );
  }

  Future<void> notifyTaskFinished({required String taskName}) async {
    if (!await _ensurePermissions()) return;
    final title = taskName.isNotEmpty ? taskName : 'Task completed';
    const body = 'All pomodoros are done.';
    await _backend.show(
      id: _consumeId(),
      title: title,
      body: body,
    );
  }

  int _consumeId() {
    _nextId = (_nextId + 1) % 100000;
    return _nextId;
  }
}

abstract class _NotificationBackend {
  String get initErrorMessage;
  Future<bool> init();
  Future<bool> requestPermissions();
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

class _SilentNotificationBackend implements _NotificationBackend {
  @override
  String get initErrorMessage => '';

  @override
  Future<bool> init() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}

class _FlutterLocalNotificationsBackend implements _NotificationBackend {
  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _macosChannel;
  String _initError = '';

  _FlutterLocalNotificationsBackend(
    this._plugin, {
    required MethodChannel macosChannel,
  }) : _macosChannel = macosChannel;

  @override
  String get initErrorMessage => _initError;

  @override
  Future<bool> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Open');
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      );
      await _plugin.initialize(settings);
      await _createAndroidChannel();
      return true;
    } catch (e) {
      _initError = 'Notification init failed: $e';
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return _requestMacOSPermissions();
    }
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macos = await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? true) && (ios ?? true) && (macos ?? true);
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _showMacOSNotification(title: title, body: body);
      return;
    }
    await _plugin.show(
      id,
      title,
      body,
      _details(),
    );
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    const channel = AndroidNotificationChannel(
      'pomodoro_updates',
      'Pomodoro updates',
      description: 'Notifications for pomodoro progress',
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'pomodoro_updates',
      'Pomodoro updates',
      channelDescription: 'Notifications for pomodoro progress',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );
    const linux = LinuxNotificationDetails(
      defaultActionName: 'Open',
    );
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );
  }

  Future<bool> _requestMacOSPermissions() async {
    try {
      final granted =
          await _macosChannel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('macOS permission request failed: $e');
      return false;
    }
  }

  Future<void> _showMacOSNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _macosChannel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('macOS notification failed: $e');
    }
  }
}

class _LocalNotifierBackend implements _NotificationBackend {
  final LocalNotifierBackend _backend;
  String _initError = '';

  _LocalNotifierBackend(this._backend);

  @override
  String get initErrorMessage => _initError;

  @override
  Future<bool> init() async {
    final ok = await _backend.init(appName: 'Focus Interval');
    if (!ok) {
      _initError =
          'Notification init failed on Windows (local_notifier setup failed).';
    }
    return ok;
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _backend.show(title: title, body: body);
    } catch (e) {
      debugPrint('Windows notification failed: $e');
    }
  }
}

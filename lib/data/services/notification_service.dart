import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final bool enabled;
  int _nextId = 0;
  bool _permissionsRequested = false;
  bool _permissionsGranted = true;

  static const MethodChannel _macosChannel =
      MethodChannel('focus_interval/macos_notifications');

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  NotificationService._(this._plugin, {required this.enabled});

  static NotificationService disabled() {
    return NotificationService._(FlutterLocalNotificationsPlugin(), enabled: false);
  }

  static Future<NotificationService> init() async {
    if (kIsWeb || _isWindows) {
      if (_isWindows) {
        debugPrint(
          'Notifications disabled on Windows (flutter_local_notifications has no Windows implementation).',
        );
      }
      return NotificationService.disabled();
    }
    final plugin = FlutterLocalNotificationsPlugin();
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
      await plugin.initialize(settings);
      await _createAndroidChannel(plugin);
      return NotificationService._(plugin, enabled: true);
    } catch (e) {
      debugPrint('Notification init failed: $e');
      return NotificationService._(plugin, enabled: false);
    }
  }

  Future<void> requestPermissions() async {
    await _ensurePermissions();
  }

  Future<bool> _ensurePermissions() async {
    if (!enabled) return false;
    if (_permissionsRequested && _permissionsGranted) return true;
    _permissionsRequested = true;
    _permissionsGranted = await _requestPermissions(_plugin);
    return _permissionsGranted;
  }

  static Future<bool> _requestPermissions(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return _requestMacOSPermissions();
    }
    final android = await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macos = await plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (android ?? true) && (ios ?? true) && (macos ?? true);
  }

  static Future<bool> _requestMacOSPermissions() async {
    try {
      final granted =
          await _macosChannel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('macOS permission request failed: $e');
      return false;
    }
  }

  static Future<void> _createAndroidChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidPlugin = plugin
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

  Future<void> notifyPomodoroEnd({
    required String taskName,
    required int currentPomodoro,
    required int totalPomodoros,
  }) async {
    if (!await _ensurePermissions()) return;
    final title = taskName.isNotEmpty ? taskName : 'Pomodoro completed';
    final body = 'Pomodoro $currentPomodoro of $totalPomodoros finished.';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _showMacOSNotification(title: title, body: body);
      return;
    }
    await _plugin.show(
      _consumeId(),
      title,
      body,
      _details(),
    );
  }

  Future<void> notifyTaskFinished({required String taskName}) async {
    if (!await _ensurePermissions()) return;
    final title = taskName.isNotEmpty ? taskName : 'Task completed';
    const body = 'All pomodoros are done.';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _showMacOSNotification(title: title, body: body);
      return;
    }
    await _plugin.show(
      _consumeId(),
      title,
      body,
      _details(),
    );
  }

  int _consumeId() {
    _nextId = (_nextId + 1) % 100000;
    return _nextId;
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

  static Future<void> _showMacOSNotification({
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

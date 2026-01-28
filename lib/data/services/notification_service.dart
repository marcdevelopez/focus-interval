import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_backends/local_notifier_backend.dart'
    if (dart.library.html) 'notification_backends/local_notifier_backend_stub.dart';
import 'notification_backends/web_notification_backend_stub.dart'
    if (dart.library.html) 'notification_backends/web_notification_backend.dart';

class NotificationService {
  final _NotificationBackend _backend;
  final bool enabled;
  int _nextId = 0;
  bool _permissionsRequested = false;
  bool _permissionsGranted = true;

  static const MethodChannel _macosChannel = MethodChannel(
    'focus_interval/macos_notifications',
  );

  NotificationService._(this._backend, {required this.enabled});

  static NotificationService disabled() {
    return NotificationService._(_SilentNotificationBackend(), enabled: false);
  }

  static Future<NotificationService> init() async {
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
    if (kIsWeb) {
      return _WebNotificationBackend(WebNotificationBackend());
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
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
    await _backend.show(id: _consumeId(), title: title, body: body);
  }

  Future<void> notifyTaskFinished({required String taskName}) async {
    if (!await _ensurePermissions()) return;
    final title = taskName.isNotEmpty ? taskName : 'Task completed';
    const body = 'All pomodoros are done.';
    await _backend.show(id: _consumeId(), title: title, body: body);
  }

  Future<void> notifyGroupPreAlert({
    required String groupName,
    required int remainingSeconds,
  }) async {
    if (!await _ensurePermissions()) return;
    final title = groupName.isNotEmpty ? groupName : 'Upcoming group';
    final body = _formatGroupPreAlertBody(remainingSeconds);
    await _backend.show(id: _consumeId(), title: title, body: body);
  }

  Future<bool> scheduleGroupPreAlert({
    required String groupId,
    required String groupName,
    required DateTime scheduledFor,
    required int remainingSeconds,
  }) async {
    if (!enabled) return false;
    final now = DateTime.now();
    if (!scheduledFor.isAfter(now)) return false;
    final title = groupName.isNotEmpty ? groupName : 'Upcoming group';
    final body = _formatGroupPreAlertBody(remainingSeconds);
    final id = _notificationIdForGroup(groupId);
    return _backend.schedule(
      id: id,
      title: title,
      body: body,
      scheduledFor: scheduledFor,
    );
  }

  Future<void> cancelGroupPreAlert(String groupId) async {
    final id = _notificationIdForGroup(groupId);
    await _backend.cancel(id);
  }

  String _formatGroupPreAlertBody(int remainingSeconds) {
    if (remainingSeconds <= 0) {
      return 'Starting soon.';
    }
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    if (minutes <= 0) {
      final secondLabel =
          remainingSeconds == 1 ? '1 second' : '$remainingSeconds seconds';
      return 'Group starts in $secondLabel.';
    }
    if (seconds == 0) {
      final minuteLabel = minutes == 1 ? '1 minute' : '$minutes minutes';
      return 'Group starts in $minuteLabel.';
    }
    final secondLabel = seconds.toString().padLeft(2, '0');
    return 'Group starts in $minutes:$secondLabel.';
  }

  int _notificationIdForGroup(String groupId) {
    const int offset = 0x20000000;
    return offset + _stableHash(groupId);
  }

  int _stableHash(String value) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash & 0x0fffffff;
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
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  });
  Future<void> cancel(int id);
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

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async => false;

  @override
  Future<void> cancel(int id) async {}
}

class _FlutterLocalNotificationsBackend implements _NotificationBackend {
  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _macosChannel;
  String _initError = '';
  static bool _tzInitialized = false;

  // Use a dedicated silent channel because Android 8+ channel sound is immutable.
  static const String _androidSilentChannelId = 'pomodoro_updates_silent';
  static const String _androidSilentChannelName = 'Pomodoro updates';
  static const String _androidSilentChannelDescription =
      'Notifications for pomodoro progress';

  _FlutterLocalNotificationsBackend(
    this._plugin, {
    required MethodChannel macosChannel,
  }) : _macosChannel = macosChannel;

  @override
  String get initErrorMessage => _initError;

  @override
  Future<bool> init() async {
    try {
      _ensureTimeZones();
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: false);
    final macos = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: false);
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
    await _plugin.show(id, title, body, _details());
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    try {
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidPlugin?.requestExactAlarmsPermission();
        if (granted == false) {
          debugPrint('Exact alarm permission not granted. Using inexact mode.');
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }
      final scheduledUtc = scheduledFor.toUtc();
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledUtc, tz.UTC),
        _details(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
      return false;
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Notification cancel failed: $e');
    }
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;
    const channel = AndroidNotificationChannel(
      _androidSilentChannelId,
      _androidSilentChannelName,
      description: _androidSilentChannelDescription,
      importance: Importance.high,
      playSound: false,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _androidSilentChannelId,
      _androidSilentChannelName,
      channelDescription: _androidSilentChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentList: true,
      presentSound: false,
    );
    const linux = LinuxNotificationDetails(defaultActionName: 'Open');
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );
  }

  Future<bool> _requestMacOSPermissions() async {
    try {
      final granted = await _macosChannel.invokeMethod<bool>(
        'requestPermission',
      );
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

  void _ensureTimeZones() {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    _tzInitialized = true;
  }
}

class _WebNotificationBackend implements _NotificationBackend {
  final WebNotificationBackend _backend;

  _WebNotificationBackend(this._backend);

  @override
  String get initErrorMessage => _backend.initErrorMessage;

  @override
  Future<bool> init() => _backend.init();

  @override
  Future<bool> requestPermissions() => _backend.requestPermissions();

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    return _backend.show(title: title, body: body);
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    return false;
  }

  @override
  Future<void> cancel(int id) async {}
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
      _initError = 'Notification init failed (local_notifier setup failed).';
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
      debugPrint('Desktop notification failed: $e');
    }
  }

  @override
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    return false;
  }

  @override
  Future<void> cancel(int id) async {}
}

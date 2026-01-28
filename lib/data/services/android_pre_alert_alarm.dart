import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _payloadKey = 'android_pre_alert_payload';

class AndroidPreAlertAlarm {
  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await AndroidAlarmManager.initialize();
  }

  static Future<bool> schedule({
    required int id,
    required DateTime scheduledFor,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'id': id,
      'title': title,
      'body': body,
      'scheduledForMs': scheduledFor.millisecondsSinceEpoch,
    });
    await prefs.setString(_payloadKey, payload);
    final ok = await AndroidAlarmManager.oneShotAt(
      scheduledFor,
      id,
      _preAlertAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
    return ok;
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await AndroidAlarmManager.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_payloadKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if ((data['id'] as num?)?.toInt() == id) {
      await prefs.remove(_payloadKey);
    }
  }
}

@pragma('vm:entry-point')
Future<void> _preAlertAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_payloadKey);
  if (raw == null) return;
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final id = (data['id'] as num?)?.toInt() ?? 99001;
  final title = (data['title'] as String?) ?? 'Upcoming group';
  final body = (data['body'] as String?) ?? '';
  final scheduledMs = (data['scheduledForMs'] as num?)?.toInt();
  if (scheduledMs == null) return;
  final scheduledFor = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
  if (DateTime.now().isBefore(scheduledFor)) return;

  const channelId = 'pomodoro_updates_silent';
  const channelName = 'Pomodoro updates';
  const channelDescription = 'Notifications for pomodoro progress';
  const android = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: false,
  );
  const details = NotificationDetails(android: android);
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: false,
      ),
    );
  }
  await plugin.show(id, title, body, details);
}

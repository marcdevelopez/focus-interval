import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel =
      MethodChannel('focus_interval/foreground_service');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<void> start({
    required String title,
    required String text,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('start', {
        'title': title,
        'text': text,
      });
    } catch (e) {
      debugPrint('Foreground service start failed: $e');
    }
  }

  static Future<void> update({
    required String title,
    required String text,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('update', {
        'title': title,
        'text': text,
      });
    } catch (e) {
      debugPrint('Foreground service update failed: $e');
    }
  }

  static Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('Foreground service stop failed: $e');
    }
  }
}

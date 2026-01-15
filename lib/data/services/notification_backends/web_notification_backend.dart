// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js' as js;

class WebNotificationBackend {
  String _initError = '';

  String get initErrorMessage => _initError;

  Future<bool> init() async {
    if (!html.Notification.supported) {
      _initError = 'Web notifications are not supported in this browser.';
      return false;
    }
    return true;
  }

  Future<bool> requestPermissions() async {
    if (!html.Notification.supported) return false;
    final permission = html.Notification.permission;
    if (permission == 'granted') return true;
    if (permission == 'denied') return false;
    final result = await html.Notification.requestPermission();
    return result == 'granted';
  }

  Future<void> show({required String title, required String body}) async {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;
    final options = js.JsObject.jsify({
      'body': body,
      'icon': 'icons/Icon-192.png',
      'silent': true,
    });
    final constructor = js.context['Notification'];
    if (constructor is! js.JsFunction) return;
    js.JsObject(constructor, [title, options]);
  }
}

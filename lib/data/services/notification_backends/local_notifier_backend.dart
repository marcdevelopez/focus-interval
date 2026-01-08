import 'package:local_notifier/local_notifier.dart';

/// Internal backend for Windows notifications using local_notifier.
class LocalNotifierBackend {
  bool _initialized = false;

  Future<bool> init({required String appName}) async {
    try {
      await localNotifier.setup(appName: appName);
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isInitialized => _initialized;

  Future<void> show({
    required String title,
    required String body,
  }) async {
    final notification = LocalNotification(title: title, body: body);
    await notification.show();
  }
}

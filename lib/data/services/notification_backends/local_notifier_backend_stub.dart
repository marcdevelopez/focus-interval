/// Stub backend for platforms that cannot import local_notifier (e.g. web).
class LocalNotifierBackend {
  Future<bool> init({required String appName}) async => false;

  bool get isInitialized => false;

  Future<void> show({
    required String title,
    required String body,
  }) async {}
}

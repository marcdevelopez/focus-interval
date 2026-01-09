class WebNotificationBackend {
  String get initErrorMessage =>
      'Web notifications are not supported on this platform.';

  Future<bool> init() async => false;

  Future<bool> requestPermissions() async => false;

  Future<void> show({required String title, required String body}) async {}
}

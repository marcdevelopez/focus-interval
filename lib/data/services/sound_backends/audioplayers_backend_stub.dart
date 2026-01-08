/// Stub backend for platforms that cannot import audioplayers (e.g. web).
class AudioPlayersBackend {
  Future<void> playAsset(String assetPath) async {}

  Future<void> dispose() async {}
}

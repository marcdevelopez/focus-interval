import 'package:audioplayers/audioplayers.dart';

/// Internal backend for desktop audio playback using audioplayers.
class AudioPlayersBackend {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAsset(String assetPath) async {
    final normalized = _normalizeAssetPath(assetPath);
    await _player.play(
      AssetSource(normalized),
      position: Duration.zero,
    );
  }

  Future<void> dispose() => _player.dispose();

  String _normalizeAssetPath(String assetPath) {
    const prefix = 'assets/';
    if (assetPath.startsWith(prefix)) {
      return assetPath.substring(prefix.length);
    }
    return assetPath;
  }
}

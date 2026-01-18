import 'package:audioplayers/audioplayers.dart';

/// Internal backend for desktop audio playback using audioplayers.
class AudioPlayersBackend {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAsset(String assetPath) async {
    final normalized = _normalizeAssetPath(assetPath);
    await _player.play(AssetSource(normalized));
  }

  Future<void> playFile(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  String _normalizeAssetPath(String path) {
    // audioplayers prepends the assets/ prefix internally; strip it to avoid
    // resolving to assets/assets/... on desktop builds.
    if (path.startsWith('assets/')) {
      return path.substring('assets/'.length);
    }
    return path;
  }
}

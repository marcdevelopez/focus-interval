import 'package:audioplayers/audioplayers.dart';

/// Internal backend for Windows audio playback using audioplayers.
class AudioPlayersBackend {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAsset(String assetPath) async {
    await _player.play(
      AssetSource(assetPath),
      position: Duration.zero,
    );
  }

  Future<void> dispose() => _player.dispose();
}

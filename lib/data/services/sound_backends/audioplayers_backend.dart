import 'package:audioplayers/audioplayers.dart';

/// Internal backend for desktop audio playback using audioplayers.
class AudioPlayersBackend {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAsset(String assetPath) async {
    await _player.play(AssetSource(assetPath));
  }

  Future<void> playFile(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

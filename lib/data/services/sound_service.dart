import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Simple service to play sounds from assets.
class SoundService {
  final AudioPlayer? _player;
  final bool _enabled;
  bool _loggedUnsupported = false;

  SoundService()
      : _enabled = _isSupportedPlatform,
        _player = _isSupportedPlatform ? AudioPlayer() : null;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.windows:
        return false;
      default:
        return false;
    }
  }

  /// Logical ID map → asset path.
  final Map<String, String> _assetById = const {
    'default_chime': 'assets/sounds/default_chime.mp3',
    'default_chime_break': 'assets/sounds/default_chime_break.mp3',
    'default_chime_finish': 'assets/sounds/default_chime_finish.mp3',
    // Simple aliases for selector options (reuse the same assets)
    'bell_soft': 'assets/sounds/default_chime.mp3',
    'digital_beep': 'assets/sounds/default_chime.mp3',
    'bell_soft_break': 'assets/sounds/default_chime_break.mp3',
    'digital_beep_break': 'assets/sounds/default_chime_break.mp3',
  };

  Future<void> play(String id, {String? fallbackId}) async {
    if (!_enabled) {
      _logUnsupportedOnce();
      return;
    }
    final asset = _assetById[id];
    if (asset == null) return;

    // Verify the asset exists; if missing, stay silent.
    try {
      await rootBundle.load(asset);
    } catch (_) {
      if (fallbackId != null) {
        await play(fallbackId);
      }
      return;
    }

    final player = _player;
    if (player == null) return;

    try {
      await player.setAsset(asset);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      if (fallbackId != null) {
        await play(fallbackId);
      }
    }
  }

  void _logUnsupportedOnce() {
    if (_loggedUnsupported) return;
    _loggedUnsupported = true;
    debugPrint(
      'Sound playback disabled on Windows (just_audio has no Windows implementation).',
    );
  }

  Future<void> dispose() => _player?.dispose() ?? Future.value();
}

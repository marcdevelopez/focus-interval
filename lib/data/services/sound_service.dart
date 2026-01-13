import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'sound_backends/audioplayers_backend.dart'
    if (dart.library.html) 'sound_backends/audioplayers_backend_stub.dart';

/// Simple service to play sounds from assets.
class SoundService {
  final _SoundBackend _backend;
  bool _loggedUnsupported = false;
  bool _loggedPlaybackError = false;

  SoundService() : _backend = _createBackend();

  static _SoundBackend _createBackend() {
    if (kIsWeb) {
      return _JustAudioBackend();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _AudioPlayersBackend();
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _JustAudioBackend();
      default:
        return _SilentSoundBackend(
          'Sound playback is not supported on this platform.',
        );
    }
  }

  /// Logical ID map - asset path.
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
    final asset = _assetById[id];
    if (asset == null) return;

    if (!_backend.isAvailable) {
      _logUnsupportedOnce(_backend.unavailableReason);
      return;
    }

    // Verify the asset exists; if missing, stay silent.
    try {
      await rootBundle.load(asset);
    } catch (_) {
      if (fallbackId != null) {
        await play(fallbackId);
      }
      return;
    }

    try {
      await _backend.playAsset(asset);
    } catch (e) {
      _logPlaybackErrorOnce(e);
      if (fallbackId != null) {
        await play(fallbackId);
      }
    }
  }

  void _logUnsupportedOnce(String reason) {
    if (_loggedUnsupported || reason.isEmpty) return;
    _loggedUnsupported = true;
    debugPrint(reason);
  }

  void _logPlaybackErrorOnce(Object error) {
    if (_loggedPlaybackError) return;
    _loggedPlaybackError = true;
    debugPrint('Sound playback failed: $error');
  }

  Future<void> dispose() => _backend.dispose();
}

abstract class _SoundBackend {
  bool get isAvailable;
  String get unavailableReason;
  Future<void> playAsset(String assetPath);
  Future<void> dispose();
}

class _JustAudioBackend implements _SoundBackend {
  final AudioPlayer _player = AudioPlayer();

  @override
  bool get isAvailable => true;

  @override
  String get unavailableReason => '';

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.setAsset(assetPath);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> dispose() => _player.dispose();
}

class _AudioPlayersBackend implements _SoundBackend {
  final AudioPlayersBackend _backend = AudioPlayersBackend();

  @override
  bool get isAvailable => true;

  @override
  String get unavailableReason => '';

  @override
  Future<void> playAsset(String assetPath) => _backend.playAsset(assetPath);

  @override
  Future<void> dispose() => _backend.dispose();
}

class _SilentSoundBackend implements _SoundBackend {
  final String _reason;

  _SilentSoundBackend(this._reason);

  @override
  bool get isAvailable => false;

  @override
  String get unavailableReason => _reason;

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> dispose() async {}
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../models/selected_sound.dart';
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

  Future<void> play(SelectedSound sound, {SelectedSound? fallback}) async {
    if (!_backend.isAvailable) {
      _logUnsupportedOnce(_backend.unavailableReason);
      return;
    }

    final candidates = _buildCandidateSounds(sound, fallback);
    for (final candidate in candidates) {
      if (candidate.type == SoundType.builtIn) {
        final asset = _assetById[candidate.value];
        if (asset == null) continue;
        if (!await _assetExists(asset)) continue;

        try {
          await _backend.playAsset(asset);
          return;
        } catch (e) {
          _logPlaybackErrorOnce(e);
        }
      } else {
        if (!_backend.supportsFile) continue;
        try {
          await _backend.playFile(candidate.value);
          return;
        } catch (e) {
          _logPlaybackErrorOnce(e);
        }
      }
    }
  }

  List<SelectedSound> _buildCandidateSounds(
    SelectedSound sound,
    SelectedSound? fallback,
  ) {
    final candidates = <SelectedSound>[];

    void add(SelectedSound? value) {
      if (value == null) return;
      if (value.value.trim().isEmpty) return;
      if (candidates.any(
        (c) => c.type == value.type && c.value == value.value,
      )) {
        return;
      }
      candidates.add(value);
    }

    add(sound);
    add(fallback);
    add(_defaultSoundFor(sound));
    add(_defaultSoundFor(fallback));

    return candidates;
  }

  SelectedSound _defaultSoundFor(SelectedSound? sound) {
    if (sound == null) return const SelectedSound.builtIn('default_chime');
    if (sound.type == SoundType.custom) {
      return const SelectedSound.builtIn('default_chime');
    }
    final lowered = sound.value.toLowerCase();
    if (lowered.contains('break')) {
      return const SelectedSound.builtIn('default_chime_break');
    }
    if (lowered.contains('finish')) {
      return const SelectedSound.builtIn('default_chime_finish');
    }
    return const SelectedSound.builtIn('default_chime');
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
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
  bool get supportsFile;
  String get unavailableReason;
  Future<void> playAsset(String assetPath);
  Future<void> playFile(String filePath);
  Future<void> dispose();
}

class _JustAudioBackend implements _SoundBackend {
  final AudioPlayer _player = AudioPlayer();

  @override
  bool get isAvailable => true;

  @override
  bool get supportsFile => true;

  @override
  String get unavailableReason => '';

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.setAsset(assetPath);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> playFile(String filePath) async {
    await _player.setFilePath(filePath);
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
  bool get supportsFile => true;

  @override
  String get unavailableReason => '';

  @override
  Future<void> playAsset(String assetPath) => _backend.playAsset(assetPath);

  @override
  Future<void> playFile(String filePath) => _backend.playFile(filePath);

  @override
  Future<void> dispose() => _backend.dispose();
}

class _SilentSoundBackend implements _SoundBackend {
  final String _reason;

  _SilentSoundBackend(this._reason);

  @override
  bool get isAvailable => false;

  @override
  bool get supportsFile => false;

  @override
  String get unavailableReason => _reason;

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> playFile(String filePath) async {}

  @override
  Future<void> dispose() async {}
}

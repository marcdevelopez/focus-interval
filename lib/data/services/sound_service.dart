import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Servicio simple para reproducir sonidos desde assets.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  /// Mapa ID lógico → ruta de asset.
  final Map<String, String> _assetById = const {
    'default_chime': 'assets/sounds/default_chime.mp3',
    'default_chime_break': 'assets/sounds/default_chime_break.mp3',
    'default_chime_finish': 'assets/sounds/default_chime_finish.mp3',
    // Alias simples para opciones del selector (reutilizan los mismos assets)
    'bell_soft': 'assets/sounds/default_chime.mp3',
    'digital_beep': 'assets/sounds/default_chime.mp3',
    'bell_soft_break': 'assets/sounds/default_chime_break.mp3',
    'digital_beep_break': 'assets/sounds/default_chime_break.mp3',
  };

  Future<void> play(String id, {String? fallbackId}) async {
    final asset = _assetById[id];
    if (asset == null) return;

    // Verificamos que el asset exista; si falta, silencioso.
    try {
      await rootBundle.load(asset);
    } catch (_) {
      if (fallbackId != null) {
        await play(fallbackId);
      }
      return;
    }

    try {
      await _player.setAsset(asset);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      if (fallbackId != null) {
        await play(fallbackId);
      }
    }
  }

  Future<void> dispose() => _player.dispose();
}

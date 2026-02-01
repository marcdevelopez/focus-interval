import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/pomodoro_preset.dart';
import '../services/preset_integrity_service.dart';
import 'pomodoro_preset_repository.dart';

class LocalPomodoroPresetRepository implements PomodoroPresetRepository {
  static const String _defaultPrefsKey = 'local_presets_v1';

  final Map<String, PomodoroPreset> _store = {};
  final StreamController<List<PomodoroPreset>> _controller;
  final String _prefsKey;
  bool _loaded = false;
  Future<void>? _loadFuture;

  LocalPomodoroPresetRepository({String prefsKey = _defaultPrefsKey})
      : _prefsKey = prefsKey,
        _controller = StreamController<List<PomodoroPreset>>.broadcast(
        sync: true,
        onListen: () {},
      ) {
    _controller.onListen = _handleListen;
  }

  @override
  Future<List<PomodoroPreset>> getAll() async {
    await _ensureLoaded();
    await _ensureIntegrity();
    return _store.values.toList();
  }

  @override
  Future<PomodoroPreset?> getById(String id) async {
    await _ensureLoaded();
    return _store[id];
  }

  @override
  Future<void> save(PomodoroPreset preset) async {
    await _ensureLoaded();
    _store[preset.id] = preset;
    _normalizePresetsSync(DateTime.now());
    await _persist();
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    _store.remove(id);
    await _ensureIntegrity();
    _emit();
  }

  @override
  Stream<List<PomodoroPreset>> watchAll() => _controller.stream;

  void _handleListen() {
    _ensureLoaded().then((_) async {
      await _ensureIntegrity();
      _emit();
    });
  }

  Future<void> _ensureLoaded() {
    if (_loaded) return Future.value();
    return _loadFuture ??= _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _loaded = true;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      var hasChanges = false;
      if (decoded is List) {
        for (final entry in decoded) {
          if (entry is Map) {
            final map = Map<String, dynamic>.from(entry);
            if (map['id'] == null ||
                (map['id'] is String && map['id'].isEmpty)) {
              map['id'] = const Uuid().v4();
              hasChanges = true;
            }
            final preset = PomodoroPreset.fromMap(map);
            final hasCreated = map['createdAt'] != null;
            final hasUpdated = map['updatedAt'] != null;
            if (!hasCreated || !hasUpdated) {
              map['createdAt'] = preset.createdAt.toIso8601String();
              map['updatedAt'] = preset.updatedAt.toIso8601String();
              hasChanges = true;
            }
            _store[preset.id] = preset;
          }
        }
      }
      if (hasChanges) {
        await _persist();
      }
    } catch (e) {
      debugPrint('Local preset load failed: $e');
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _store.values.map((preset) => preset.toMap()).toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  Future<void> _ensureIntegrity({bool persist = true}) async {
    var changed = false;
    final now = DateTime.now();
    if (_store.isEmpty) {
      final preset = PomodoroPreset.classicDefault(
        id: const Uuid().v4(),
        now: now,
      );
      _store[preset.id] = preset;
      changed = true;
    }
    if (_normalizePresetsSync(now)) {
      changed = true;
    }
    if (changed && persist) {
      await _persist();
    }
  }

  bool _normalizePresetsSync(DateTime now) {
    if (_store.isEmpty) return false;
    final result = normalizePresets(
      presets: _store.values.toList(),
      now: now,
    );
    if (!result.changed) return false;
    _store
      ..clear()
      ..addAll({for (final preset in result.presets) preset.id: preset});
    return true;
  }

  void _emit() {
    _controller.add(_store.values.toList());
  }
}

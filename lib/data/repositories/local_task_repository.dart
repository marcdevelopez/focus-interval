import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_task.dart';
import 'task_repository.dart';

/// Local disk-backed repository for Linux when auth is unavailable.
class LocalTaskRepository implements TaskRepository {
  static const String _prefsKey = 'local_tasks_v1';

  final Map<String, PomodoroTask> _store = {};
  final StreamController<List<PomodoroTask>> _controller;
  bool _loaded = false;
  Future<void>? _loadFuture;

  LocalTaskRepository()
    : _controller = StreamController<List<PomodoroTask>>.broadcast(
        sync: true,
        onListen: () {
          // Emit the current state as soon as someone subscribes.
        },
      ) {
    _controller.onListen = _handleListen;
  }

  @override
  Future<List<PomodoroTask>> getAll() async {
    await _ensureLoaded();
    return _store.values.toList();
  }

  @override
  Future<PomodoroTask?> getById(String id) async {
    await _ensureLoaded();
    return _store[id];
  }

  @override
  Future<void> save(PomodoroTask task) async {
    await _ensureLoaded();
    _store[task.id] = task;
    await _persist();
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    _store.remove(id);
    await _persist();
    _emit();
  }

  @override
  Stream<List<PomodoroTask>> watchAll() => _controller.stream;

  void _handleListen() {
    _ensureLoaded().then((_) => _emit());
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
            final task = PomodoroTask.fromMap(map);
            final hasCreated = map['createdAt'] != null;
            final hasUpdated = map['updatedAt'] != null;
            if (!hasCreated || !hasUpdated) {
              map['createdAt'] = task.createdAt.toIso8601String();
              map['updatedAt'] = task.updatedAt.toIso8601String();
              hasChanges = true;
            }
            _store[task.id] = task;
          }
        }
      }
      if (hasChanges) {
        await _persist();
      }
    } catch (e) {
      debugPrint('Local task load failed: $e');
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _store.values.map((task) => task.toMap()).toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  void _emit() {
    _controller.add(_store.values.toList());
  }
}

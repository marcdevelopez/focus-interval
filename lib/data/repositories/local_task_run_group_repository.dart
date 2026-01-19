import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_run_group.dart';
import '../services/task_run_retention_service.dart';
import 'task_run_group_repository.dart';

/// Local disk-backed repository for TaskRunGroups (Linux local-only mode).
class LocalTaskRunGroupRepository implements TaskRunGroupRepository {
  static const String _prefsKey = 'local_task_run_groups_v1';

  final TaskRunRetentionService retentionService;
  final Map<String, TaskRunGroup> _store = {};
  final StreamController<List<TaskRunGroup>> _controller;
  bool _loaded = false;
  Future<void>? _loadFuture;

  LocalTaskRunGroupRepository({required this.retentionService})
    : _controller = StreamController<List<TaskRunGroup>>.broadcast(
        sync: true,
        onListen: () {
          // Emit after load.
        },
      ) {
    _controller.onListen = _handleListen;
  }

  @override
  Stream<List<TaskRunGroup>> watchAll() async* {
    await _ensureLoaded();
    yield* _controller.stream;
  }

  @override
  Future<List<TaskRunGroup>> getAll() async {
    await _ensureLoaded();
    await _normalizeExpiredRunningGroups(DateTime.now());
    return _store.values.toList();
  }

  @override
  Future<TaskRunGroup?> getById(String id) async {
    await _ensureLoaded();
    return _store[id];
  }

  @override
  Future<void> save(TaskRunGroup group) async {
    await _ensureLoaded();
    _store[group.id] = group;
    await _pruneInMemory();
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
  Future<void> prune({int? keepCompleted}) async {
    await _ensureLoaded();
    await _pruneInMemory(keepCompleted: keepCompleted);
    await _persist();
    _emit();
  }

  Future<void> _handleListen() async {
    await _ensureLoaded();
    await _normalizeExpiredRunningGroups(DateTime.now());
    _emit();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded.whereType<Map>()) {
            final map = Map<String, dynamic>.from(entry);
            final group = TaskRunGroup.fromMap(map);
            _store[group.id] = group;
          }
        }
      }
    } catch (e) {
      debugPrint('Local task run group load failed: $e');
    }
    await _normalizeExpiredRunningGroups(DateTime.now());
    _loaded = true;
    _emit();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _store.values.map((group) => group.toMap()).toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  Future<void> _pruneInMemory({int? keepCompleted}) async {
    final retention =
        keepCompleted ?? await retentionService.getRetentionCount();
    final groups = _store.values.toList();
    if (groups.isEmpty) return;

    final active = <TaskRunGroup>[];
    final completed = <TaskRunGroup>[];

    for (final group in groups) {
      switch (group.status) {
        case TaskRunStatus.scheduled:
        case TaskRunStatus.running:
          active.add(group);
          break;
        case TaskRunStatus.completed:
        case TaskRunStatus.canceled:
          completed.add(group);
          break;
      }
    }

    completed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final keep = completed.take(retention).map((g) => g.id).toSet();
    final activeIds = active.map((g) => g.id).toSet();

    for (final group in completed) {
      if (keep.contains(group.id)) continue;
      if (activeIds.contains(group.id)) continue;
      _store.remove(group.id);
    }
  }

  void _emit() {
    final changed = _normalizeExpiredRunningGroupsSync(DateTime.now());
    if (changed) {
      unawaited(_persist());
    }
    _controller.add(_store.values.toList());
  }

  Future<void> _normalizeExpiredRunningGroups(DateTime now) async {
    final changed = _normalizeExpiredRunningGroupsSync(now);
    if (changed) {
      await _persist();
    }
  }

  bool _normalizeExpiredRunningGroupsSync(DateTime now) {
    var changed = false;
    for (final entry in _store.entries) {
      final group = entry.value;
      if (group.status != TaskRunStatus.running) continue;
      final endTime = _resolveTheoreticalEndTime(group);
      if (endTime != null && endTime.isBefore(now)) {
        _store[entry.key] = group.copyWith(
          status: TaskRunStatus.completed,
          updatedAt: now,
        );
        changed = true;
      }
    }
    return changed;
  }

  DateTime? _resolveTheoreticalEndTime(TaskRunGroup group) {
    final start = group.scheduledStartTime ?? group.createdAt;
    final end = group.theoreticalEndTime;
    if (end.isBefore(start)) {
      final totalSeconds =
          group.totalDurationSeconds ??
          group.tasks.fold<int>(
            0,
            (total, item) => total + item.totalDurationSeconds,
          );
      if (totalSeconds > 0) {
        return start.add(Duration(seconds: totalSeconds));
      }
    }
    return end;
  }
}

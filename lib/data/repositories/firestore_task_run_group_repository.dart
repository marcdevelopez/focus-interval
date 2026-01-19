import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_run_group.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/task_run_retention_service.dart';
import 'task_run_group_repository.dart';

class FirestoreTaskRunGroupRepository implements TaskRunGroupRepository {
  final FirestoreService firestoreService;
  final AuthService authService;
  final TaskRunRetentionService retentionService;

  FirestoreTaskRunGroupRepository({
    required this.firestoreService,
    required this.authService,
    required this.retentionService,
  });

  FirebaseFirestore get _db => firestoreService.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('taskRunGroups');

  Future<String> _uidOrThrow() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  @override
  Stream<List<TaskRunGroup>> watchAll() async* {
    final uid = await _uidOrThrow();
    yield* _collection(uid).snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((doc) {
            final normalized = _normalizeMap(
              uid: uid,
              docId: doc.id,
              raw: doc.data(),
              now: now,
            );
            return _tryFromMap(normalized);
          })
          .whereType<TaskRunGroup>()
          .toList();
    });
  }

  @override
  Future<List<TaskRunGroup>> getAll() async {
    final uid = await _uidOrThrow();
    final snap = await _collection(uid).get();
    if (snap.docs.isEmpty) return const [];
    final now = DateTime.now();
    return snap.docs
        .map((doc) {
          final normalized = _normalizeMap(
            uid: uid,
            docId: doc.id,
            raw: doc.data(),
            now: now,
          );
          return _tryFromMap(normalized);
        })
        .whereType<TaskRunGroup>()
        .toList();
  }

  @override
  Future<TaskRunGroup?> getById(String id) async {
    final uid = await _uidOrThrow();
    final doc = await _collection(uid).doc(id).get();
    if (!doc.exists) return null;
    final normalized = _normalizeMap(
      uid: uid,
      docId: doc.id,
      raw: doc.data()!,
      now: DateTime.now(),
    );
    return _tryFromMap(normalized);
  }

  @override
  Future<void> save(TaskRunGroup group) async {
    final uid = await _uidOrThrow();
    final now = DateTime.now();
    final normalized = _normalizeGroup(group, now: now);
    await _collection(uid).doc(group.id).set(normalized.toMap());
    await prune();
  }

  @override
  Future<void> delete(String id) async {
    final uid = await _uidOrThrow();
    await _collection(uid).doc(id).delete();
  }

  @override
  Future<void> prune({int? keepCompleted}) async {
    final uid = await _uidOrThrow();
    final retention =
        keepCompleted ?? await retentionService.getRetentionCount();
    final snap = await _collection(uid).get();
    if (snap.docs.isEmpty) return;

    final now = DateTime.now();
    final groups = snap.docs
        .map((doc) {
          final normalized = _normalizeMap(
            uid: uid,
            docId: doc.id,
            raw: doc.data(),
            now: now,
          );
          return _tryFromMap(normalized);
        })
        .whereType<TaskRunGroup>()
        .toList();

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

    final toDelete = <String>[];
    for (final group in completed) {
      if (keep.contains(group.id)) continue;
      if (activeIds.contains(group.id)) continue;
      toDelete.add(group.id);
    }

    for (final id in toDelete) {
      await _collection(uid).doc(id).delete();
    }
  }

  TaskRunGroup _normalizeGroup(TaskRunGroup group, {required DateTime now}) {
    final tasks = group.tasks;
    final totalTasks = group.totalTasks ?? tasks.length;
    final totalPomodoros =
        group.totalPomodoros ??
        tasks.fold<int>(0, (total, item) => total + item.totalPomodoros);
    final totalDurationSeconds =
        group.totalDurationSeconds ??
        tasks.fold<int>(0, (total, item) => total + item.totalDurationSeconds);

    return group.copyWith(
      totalTasks: totalTasks,
      totalPomodoros: totalPomodoros,
      totalDurationSeconds: totalDurationSeconds,
      updatedAt: now,
    );
  }

  Map<String, dynamic> _normalizeMap({
    required String uid,
    required String docId,
    required Map<String, dynamic> raw,
    required DateTime now,
  }) {
    final normalized = Map<String, dynamic>.from(raw);
    final hasCreated = normalized['createdAt'] != null;
    final hasUpdated = normalized['updatedAt'] != null;
    final hasId =
        normalized['id'] is String &&
        (normalized['id'] as String).trim().isNotEmpty;
    final hasOwner =
        normalized['ownerUid'] is String &&
        (normalized['ownerUid'] as String).trim().isNotEmpty;
    if (!hasCreated || !hasUpdated) {
      final createdAt = hasCreated
          ? normalized['createdAt']
          : now.toIso8601String();
      final updatedAt = hasUpdated ? normalized['updatedAt'] : createdAt;
      normalized['createdAt'] = createdAt;
      normalized['updatedAt'] = updatedAt;
      unawaited(
        _collection(uid).doc(docId).set({
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        }, SetOptions(merge: true)),
      );
    }

    if (!hasId || !hasOwner) {
      final id = hasId ? normalized['id'] : docId;
      final ownerUid = hasOwner ? normalized['ownerUid'] : uid;
      normalized['id'] = id;
      normalized['ownerUid'] = ownerUid;
      unawaited(
        _collection(uid).doc(docId).set({
          'id': id,
          'ownerUid': ownerUid,
        }, SetOptions(merge: true)),
      );
    }

    final status = normalized['status'] as String?;
    if (status == TaskRunStatus.running.name) {
      final endTime = _resolveTheoreticalEndTime(normalized);
      if (endTime != null && endTime.isBefore(now)) {
        normalized['status'] = TaskRunStatus.completed.name;
        normalized['updatedAt'] = now.toIso8601String();
        unawaited(
          _collection(uid).doc(docId).set({
            'status': TaskRunStatus.completed.name,
            'updatedAt': now.toIso8601String(),
          }, SetOptions(merge: true)),
        );
      }
    }
    return normalized;
  }

  DateTime? _resolveTheoreticalEndTime(Map<String, dynamic> raw) {
    final start =
      _parseDateTime(raw['actualStartTime']) ??
      _parseDateTime(raw['scheduledStartTime']) ??
      _parseDateTime(raw['createdAt']);
    final rawEnd = _parseDateTime(raw['theoreticalEndTime']);
    if (start != null && rawEnd != null && rawEnd.isBefore(start)) {
      final totalSeconds = _readInt(raw, 'totalDurationSeconds', 0);
      if (totalSeconds > 0) {
        return start.add(Duration(seconds: totalSeconds));
      }
    }
    return rawEnd;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  TaskRunGroup? _tryFromMap(Map<String, dynamic> map) {
    try {
      return TaskRunGroup.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}

int _readInt(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

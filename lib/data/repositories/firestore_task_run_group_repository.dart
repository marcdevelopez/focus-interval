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
      return snap.docs.map((doc) {
        final normalized = _normalizeMap(
          uid: uid,
          docId: doc.id,
          raw: doc.data(),
          now: now,
        );
        return TaskRunGroup.fromMap(normalized);
      }).toList();
    });
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
    return TaskRunGroup.fromMap(normalized);
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
    final groups = snap.docs.map((doc) {
      final normalized = _normalizeMap(
        uid: uid,
        docId: doc.id,
        raw: doc.data(),
        now: now,
      );
      return TaskRunGroup.fromMap(normalized);
    }).toList();

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
    return normalized;
  }
}

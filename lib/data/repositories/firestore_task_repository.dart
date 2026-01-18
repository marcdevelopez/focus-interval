import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pomodoro_task.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  final FirestoreService firestoreService;
  final AuthService authService;

  FirestoreTaskRepository({
    required this.firestoreService,
    required this.authService,
  });

  FirebaseFirestore get _db => firestoreService.instance;

  CollectionReference<Map<String, dynamic>> _taskCollection(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  Future<String> _uidOrThrow() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  @override
  Future<List<PomodoroTask>> getAll() async {
    final uid = await _uidOrThrow();
    final snap = await _taskCollection(uid).get();
    final now = DateTime.now();
    return snap.docs.map((doc) {
      final normalized = _normalizeTaskMap(
        uid: uid,
        docId: doc.id,
        raw: doc.data(),
        now: now,
      );
      return PomodoroTask.fromMap(normalized);
    }).toList();
  }

  @override
  Future<PomodoroTask?> getById(String id) async {
    final uid = await _uidOrThrow();
    final doc = await _taskCollection(uid).doc(id).get();
    if (!doc.exists) return null;
    final normalized = _normalizeTaskMap(
      uid: uid,
      docId: doc.id,
      raw: doc.data()!,
      now: DateTime.now(),
    );
    return PomodoroTask.fromMap(normalized);
  }

  @override
  Future<void> save(PomodoroTask task) async {
    final uid = await _uidOrThrow();
    await _taskCollection(uid).doc(task.id).set(task.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final uid = await _uidOrThrow();
    await _taskCollection(uid).doc(id).delete();
  }

  @override
  Stream<List<PomodoroTask>> watchAll() async* {
    final uid = await _uidOrThrow();
    yield* _taskCollection(uid).snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs.map((doc) {
        final normalized = _normalizeTaskMap(
          uid: uid,
          docId: doc.id,
          raw: doc.data(),
          now: now,
        );
        return PomodoroTask.fromMap(normalized);
      }).toList();
    });
  }

  Map<String, dynamic> _normalizeTaskMap({
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
        _taskCollection(uid).doc(docId).set({
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        }, SetOptions(merge: true)),
      );
    }
    return normalized;
  }

  /// Optional stream helper.
  Stream<List<PomodoroTask>> watchTasks() {
    final uid = authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return watchAll();
  }
}

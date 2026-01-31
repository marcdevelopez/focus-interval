import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pomodoro_preset.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'pomodoro_preset_repository.dart';

class FirestorePomodoroPresetRepository implements PomodoroPresetRepository {
  final FirestoreService firestoreService;
  final AuthService authService;

  FirestorePomodoroPresetRepository({
    required this.firestoreService,
    required this.authService,
  });

  FirebaseFirestore get _db => firestoreService.instance;

  CollectionReference<Map<String, dynamic>> _presetCollection(String uid) =>
      _db.collection('users').doc(uid).collection('pomodoroPresets');

  Future<String> _uidOrThrow() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  @override
  Future<List<PomodoroPreset>> getAll() async {
    final uid = await _uidOrThrow();
    final snap = await _presetCollection(uid).get();
    final now = DateTime.now();
    return snap.docs.map((doc) {
      final normalized = _normalizePresetMap(
        uid: uid,
        docId: doc.id,
        raw: doc.data(),
        now: now,
      );
      return PomodoroPreset.fromMap(normalized);
    }).toList();
  }

  @override
  Future<PomodoroPreset?> getById(String id) async {
    final uid = await _uidOrThrow();
    final doc = await _presetCollection(uid).doc(id).get();
    if (!doc.exists) return null;
    final normalized = _normalizePresetMap(
      uid: uid,
      docId: doc.id,
      raw: doc.data()!,
      now: DateTime.now(),
    );
    return PomodoroPreset.fromMap(normalized);
  }

  @override
  Future<void> save(PomodoroPreset preset) async {
    final uid = await _uidOrThrow();
    await _presetCollection(uid).doc(preset.id).set(preset.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final uid = await _uidOrThrow();
    await _presetCollection(uid).doc(id).delete();
  }

  @override
  Stream<List<PomodoroPreset>> watchAll() async* {
    final uid = await _uidOrThrow();
    yield* _presetCollection(uid).snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs.map((doc) {
        final normalized = _normalizePresetMap(
          uid: uid,
          docId: doc.id,
          raw: doc.data(),
          now: now,
        );
        return PomodoroPreset.fromMap(normalized);
      }).toList();
    });
  }

  Map<String, dynamic> _normalizePresetMap({
    required String uid,
    required String docId,
    required Map<String, dynamic> raw,
    required DateTime now,
  }) {
    final normalized = Map<String, dynamic>.from(raw);
    final hasId =
        normalized['id'] is String &&
        (normalized['id'] as String).trim().isNotEmpty;
    final hasCreated = normalized['createdAt'] != null;
    final hasUpdated = normalized['updatedAt'] != null;
    if (!hasId || !hasCreated || !hasUpdated) {
      final id = hasId ? normalized['id'] : docId;
      final createdAt = hasCreated
          ? normalized['createdAt']
          : now.toIso8601String();
      final updatedAt = hasUpdated ? normalized['updatedAt'] : createdAt;
      normalized['id'] = id;
      normalized['createdAt'] = createdAt;
      normalized['updatedAt'] = updatedAt;
      unawaited(
        _presetCollection(uid).doc(docId).set({
          'id': id,
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        }, SetOptions(merge: true)),
      );
    }
    return normalized;
  }
}

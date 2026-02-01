import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/pomodoro_preset.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'pomodoro_preset_repository.dart';

class FirestorePomodoroPresetRepository implements PomodoroPresetRepository {
  final FirestoreService firestoreService;
  final AuthService authService;
  final _uuid = const Uuid();
  bool _seeded = false;

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
    if (snap.docs.isEmpty) {
      final seeded = await _seedDefault(uid, now: now);
      return [seeded];
    }
    final presets = snap.docs.map((doc) {
      final normalized = _normalizePresetMap(
        uid: uid,
        docId: doc.id,
        raw: doc.data(),
        now: now,
      );
      return PomodoroPreset.fromMap(normalized);
    }).toList();
    return _ensureDefaultFlag(uid, presets);
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
    await _ensureDefaultExists(uid);
  }

  @override
  Stream<List<PomodoroPreset>> watchAll() async* {
    final uid = await _uidOrThrow();
    yield* _presetCollection(uid).snapshots().map((snap) {
      final now = DateTime.now();
      if (snap.docs.isEmpty && !_seeded) {
        _seeded = true;
        final seeded = PomodoroPreset.classicDefault(
          id: _uuid.v4(),
          now: now,
        );
        unawaited(_presetCollection(uid).doc(seeded.id).set(seeded.toMap()));
        return [seeded];
      }
      final presets = snap.docs.map((doc) {
        final normalized = _normalizePresetMap(
          uid: uid,
          docId: doc.id,
          raw: doc.data(),
          now: now,
        );
        return PomodoroPreset.fromMap(normalized);
      }).toList();
      return _ensureDefaultFlag(uid, presets);
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

  Future<PomodoroPreset> _seedDefault(
    String uid, {
    required DateTime now,
  }) async {
    final preset = PomodoroPreset.classicDefault(
      id: _uuid.v4(),
      now: now,
    );
    await _presetCollection(uid).doc(preset.id).set(preset.toMap());
    return preset;
  }

  Future<void> _ensureDefaultExists(String uid) async {
    final snap = await _presetCollection(uid).get();
    if (snap.docs.isEmpty) {
      await _seedDefault(uid, now: DateTime.now());
      return;
    }
    final presets = snap.docs.map((doc) {
      final normalized = _normalizePresetMap(
        uid: uid,
        docId: doc.id,
        raw: doc.data(),
        now: DateTime.now(),
      );
      return PomodoroPreset.fromMap(normalized);
    }).toList();
    _ensureDefaultFlag(uid, presets);
  }

  List<PomodoroPreset> _ensureDefaultFlag(
    String uid,
    List<PomodoroPreset> presets,
  ) {
    if (presets.isEmpty) return presets;
    final hasDefault = presets.any((preset) => preset.isDefault);
    if (hasDefault) return presets;
    final first = presets.first;
    final updated = [
      first.copyWith(isDefault: true),
      ...presets.skip(1),
    ];
    unawaited(
      _presetCollection(uid)
          .doc(first.id)
          .set(updated.first.toMap()),
    );
    return updated;
  }
}

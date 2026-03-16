import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../domain/pomodoro_machine.dart';

import '../models/pomodoro_session.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'pomodoro_session_repository.dart';

class FirestorePomodoroSessionRepository implements PomodoroSessionRepository {
  final FirestoreService firestoreService;
  final AuthService authService;
  final String deviceId;
  static const Duration _ownerStaleThreshold = Duration(seconds: 45);

  FirestorePomodoroSessionRepository({
    required this.firestoreService,
    required this.authService,
    required this.deviceId,
  });

  FirebaseFirestore get _db => firestoreService.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('activeSession').doc('current');

  Future<String> _uidOrThrow() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  @override
  Future<void> publishSession(PomodoroSession session) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    final data = {
      ...session.toMap(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (session.status == PomodoroStatus.finished && session.finishedAt == null) {
      data['finishedAt'] = FieldValue.serverTimestamp();
    }
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists || snap.data() == null) {
        tx.set(docRef, data, SetOptions(merge: true));
        return;
      }
      final currentOwner = snap.data()!['ownerDeviceId'] as String?;
      if (currentOwner != null && currentOwner != session.ownerDeviceId) {
        return;
      }
      tx.set(docRef, data, SetOptions(merge: true));
    });
  }

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists && snap.data() != null) {
        return false;
      }
      final data = {
        ...session.toMap(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };
      tx.set(docRef, data);
      return true;
    });
  }

  @override
  Stream<PomodoroSession?> watchSession() async* {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      yield null;
      return;
    }
    yield* _doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PomodoroSession.fromMap(doc.data()!);
    });
  }

  @override
  Future<PomodoroSession?> fetchSession({bool preferServer = false}) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) return null;
    final docRef = _doc(uid);
    DocumentSnapshot<Map<String, dynamic>> snap;
    if (preferServer) {
      try {
        snap = await docRef.get(const GetOptions(source: Source.server));
      } catch (_) {
        if (kDebugMode) {
          debugPrint('[ActiveSession] Server fetch failed. Falling back to cache.');
        }
        snap = await docRef.get(const GetOptions(source: Source.cache));
      }
    } else {
      snap = await docRef.get();
    }
    if (!snap.exists || snap.data() == null) return null;
    return PomodoroSession.fromMap(snap.data()!);
  }

  @override
  Future<void> clearSessionAsOwner() async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final currentOwner = data['ownerDeviceId'] as String?;
      if (currentOwner != deviceId) return;
      tx.delete(docRef);
    });
  }

  @override
  Future<void> clearSessionIfStale({required DateTime now}) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final statusRaw = data['status'] as String?;
      final status = PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      );
      if (!status.isActiveExecution) {
        tx.delete(docRef);
        return;
      }
      final updatedAt = (data['lastUpdatedAt'] as Timestamp?)?.toDate();
      if (updatedAt == null) return;
      final isStale = now.difference(updatedAt) >= _ownerStaleThreshold;
      if (!isStale) return;
      tx.delete(docRef);
    });
  }

  @override
  Future<void> clearSessionIfGroupNotRunning() async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      tx.delete(docRef);
    });
  }

  @override
  Future<void> requestOwnership({
    required String requesterDeviceId,
    required String requestId,
  }) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final ownerDeviceId = data['ownerDeviceId'] as String?;
      if (ownerDeviceId == null || ownerDeviceId == requesterDeviceId) return;
      final statusRaw = data['status'] as String?;
      final status = PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      );
      if (!status.isActiveExecution) return;
      final rawRequest = data['ownershipRequest'];
      final requestMap = rawRequest is Map<String, dynamic>
          ? rawRequest
          : rawRequest is Map
              ? Map<String, dynamic>.from(rawRequest)
              : null;
      final requestStatus = requestMap?['status'] as String?;
      final requester = requestMap?['requesterDeviceId'] as String?;
      if (requestStatus == 'pending' && requester != requesterDeviceId) {
        return;
      }
      tx.set(
        docRef,
        {
          'ownershipRequest': {
            'requestId': requestId,
            'requesterDeviceId': requesterDeviceId,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'respondedAt': null,
            'respondedByDeviceId': null,
          },
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<bool> tryAutoClaimStaleOwner({
    required String requesterDeviceId,
  }) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    final now = DateTime.now();
    return _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final ownerDeviceId = data['ownerDeviceId'] as String?;
      if (ownerDeviceId == null || ownerDeviceId == requesterDeviceId) {
        return false;
      }
      final statusRaw = data['status'] as String?;
      final status = PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      );
      if (!status.isActiveExecution) return false;
      final updatedAt = (data['lastUpdatedAt'] as Timestamp?)?.toDate();
      if (updatedAt == null) return false;
      final isStale = now.difference(updatedAt) >= _ownerStaleThreshold;
      if (!isStale) return false;
      final currentRevision = (data['sessionRevision'] as num?)?.toInt() ?? 0;
      final nextRevision = currentRevision + 1;
      final rawRequest = data['ownershipRequest'];
      final requestMap = rawRequest is Map<String, dynamic>
          ? rawRequest
          : rawRequest is Map
              ? Map<String, dynamic>.from(rawRequest)
              : null;
      final requester = requestMap?['requesterDeviceId'] as String?;
      final requestStatus = requestMap?['status'] as String?;
      final hasPending = requestStatus == 'pending' && requester != null;
      if (status == PomodoroStatus.paused) {
        if (!hasPending || requester != requesterDeviceId) {
          return false;
        }
      } else {
        if (hasPending && requester != requesterDeviceId) {
          return false;
        }
      }
      tx.set(
        docRef,
        {
          'ownerDeviceId': requesterDeviceId,
          'ownershipRequest': FieldValue.delete(),
          'sessionRevision': nextRevision,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  @override
  Future<void> respondToOwnershipRequest({
    required String ownerDeviceId,
    required String requesterDeviceId,
    required bool approved,
  }) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final currentOwner = data['ownerDeviceId'] as String?;
      if (currentOwner != ownerDeviceId) return;
      final rawRequest = data['ownershipRequest'];
      final requestMap = rawRequest is Map<String, dynamic>
          ? rawRequest
          : rawRequest is Map
              ? Map<String, dynamic>.from(rawRequest)
              : null;
      final status = requestMap?['status'] as String?;
      final requester = requestMap?['requesterDeviceId'] as String?;
      if (status != 'pending' || requester != requesterDeviceId) return;
      final currentRevision = (data['sessionRevision'] as num?)?.toInt() ?? 0;
      final nextRevision = currentRevision + 1;
      if (approved) {
        tx.set(
          docRef,
          {
            'ownerDeviceId': requesterDeviceId,
            'ownershipRequest': FieldValue.delete(),
            'sessionRevision': nextRevision,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
      tx.set(
        docRef,
        {
          'ownershipRequest': {
            'requestId': requestMap?['requestId'],
            'requesterDeviceId': requesterDeviceId,
            'status': 'rejected',
            'requestedAt': requestMap?['requestedAt'],
            'respondedAt': FieldValue.serverTimestamp(),
            'respondedByDeviceId': ownerDeviceId,
          },
          'sessionRevision': nextRevision,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}

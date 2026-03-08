import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;

import '../../domain/pomodoro_machine.dart';

import '../models/pomodoro_session.dart';
import '../models/task_run_group.dart';
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

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('activeSession')
      .doc('current');

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
    if (session.status == PomodoroStatus.finished &&
        session.finishedAt == null) {
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
      final currentData = snap.data()!;
      final currentHasRevision = currentData.containsKey('sessionRevision');
      final currentRevision = (currentData['sessionRevision'] as num?)?.toInt();
      final decision = evaluateSessionWrite(
        incomingRevision: session.sessionRevision,
        currentRevision: currentRevision,
        currentHasRevision: currentHasRevision,
      );
      if (decision == SessionWriteDecision.ignore) {
        return;
      }
      if (decision == SessionWriteDecision.idempotent) {
        final isSamePayload = _isSameSessionPayloadForRevision(
          currentData,
          session,
        );
        if (!isSamePayload) {
          tx.set(docRef, data, SetOptions(merge: true));
          return;
        }
        tx.set(docRef, {
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }
      tx.set(docRef, data, SetOptions(merge: true));
    });
  }

  bool _isSameSessionPayloadForRevision(
    Map<String, dynamic> currentData,
    PomodoroSession incoming,
  ) {
    final current = PomodoroSession.fromMap(currentData);
    return current.taskId == incoming.taskId &&
        current.groupId == incoming.groupId &&
        current.currentTaskId == incoming.currentTaskId &&
        current.currentTaskIndex == incoming.currentTaskIndex &&
        current.totalTasks == incoming.totalTasks &&
        current.dataVersion == incoming.dataVersion &&
        current.sessionRevision == incoming.sessionRevision &&
        current.ownerDeviceId == incoming.ownerDeviceId &&
        current.status == incoming.status &&
        current.phase == incoming.phase &&
        current.currentPomodoro == incoming.currentPomodoro &&
        current.totalPomodoros == incoming.totalPomodoros &&
        current.phaseDurationSeconds == incoming.phaseDurationSeconds &&
        current.remainingSeconds == incoming.remainingSeconds &&
        current.accumulatedPausedSeconds == incoming.accumulatedPausedSeconds &&
        current.phaseStartedAt == incoming.phaseStartedAt &&
        current.currentTaskStartedAt == incoming.currentTaskStartedAt &&
        current.pausedAt == incoming.pausedAt &&
        current.finishedAt == incoming.finishedAt &&
        current.pauseReason == incoming.pauseReason;
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
          debugPrint(
            '[ActiveSession] Server fetch failed. Falling back to cache.',
          );
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
    final groupsCollection = _db
        .collection('users')
        .doc(uid)
        .collection('taskRunGroups');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final statusRaw = data['status'] as String?;
      final sessionStatus = PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      );
      if (!sessionStatus.isActiveExecution) {
        tx.delete(docRef);
        return;
      }

      final groupId = (data['groupId'] as String?)?.trim();
      if (groupId == null || groupId.isEmpty) {
        // Missing group linkage can be transient during reconnect/resume windows.
        return;
      }
      final groupSnap = await tx.get(groupsCollection.doc(groupId));
      if (!groupSnap.exists) {
        // Group does not exist: the session is orphaned. Delete only if the
        // session is stale (no recent heartbeat), to avoid clearing during
        // transient reconnect windows when the group write hasn't arrived yet.
        final updatedAt =
            (data['lastUpdatedAt'] as Timestamp?)?.toDate();
        if (updatedAt != null &&
            DateTime.now().difference(updatedAt) >=
                const Duration(seconds: 45)) {
          tx.delete(docRef);
        }
        return;
      }
      final groupData = groupSnap.data();
      if (groupData == null) return;
      final groupStatusRaw = groupData['status'] as String?;
      final groupStatus = TaskRunStatus.values.firstWhere(
        (e) => e.name == groupStatusRaw,
        orElse: () => TaskRunStatus.scheduled,
      );
      if (groupStatus != TaskRunStatus.running) {
        tx.delete(docRef);
      }
    });
  }

  @override
  Future<void> clearSessionIfInactive({String? expectedGroupId}) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      if (expectedGroupId != null) {
        final groupId = data['groupId'] as String?;
        if (groupId != expectedGroupId) return;
      }
      final statusRaw = data['status'] as String?;
      final status = PomodoroStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => PomodoroStatus.idle,
      );
      if (status.isActiveExecution) return;
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
      tx.set(docRef, {
        'ownershipRequest': {
          'requestId': requestId,
          'requesterDeviceId': requesterDeviceId,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'respondedAt': null,
          'respondedByDeviceId': null,
        },
      }, SetOptions(merge: true));
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
      tx.set(docRef, {
        'ownerDeviceId': requesterDeviceId,
        'ownershipRequest': FieldValue.delete(),
        'sessionRevision': nextRevision,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        tx.set(docRef, {
          'ownerDeviceId': requesterDeviceId,
          'ownershipRequest': FieldValue.delete(),
          'sessionRevision': nextRevision,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }
      tx.set(docRef, {
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
      }, SetOptions(merge: true));
    });
  }
}

enum SessionWriteDecision { ignore, idempotent, apply }

@visibleForTesting
SessionWriteDecision evaluateSessionWrite({
  required int incomingRevision,
  required int? currentRevision,
  required bool currentHasRevision,
}) {
  if (!currentHasRevision) {
    return SessionWriteDecision.apply;
  }
  final current = currentRevision ?? 0;
  if (incomingRevision < current) {
    return SessionWriteDecision.ignore;
  }
  if (incomingRevision == current) {
    return SessionWriteDecision.idempotent;
  }
  return SessionWriteDecision.apply;
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/pomodoro_machine.dart';

import '../models/pomodoro_session.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'pomodoro_session_repository.dart';

class FirestorePomodoroSessionRepository implements PomodoroSessionRepository {
  final FirestoreService firestoreService;
  final AuthService authService;
  final String deviceId;
  static const Duration _ownerStaleThreshold = Duration(seconds: 90);

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
    final data = {
      ...session.toMap(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (session.status == PomodoroStatus.finished && session.finishedAt == null) {
      data['finishedAt'] = FieldValue.serverTimestamp();
    }
    await _doc(uid).set(data, SetOptions(merge: true));
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
  Future<void> clearSession() async {
    final uid = await _uidOrThrow();
    await _doc(uid).delete();
  }

  @override
  Future<void> requestOwnership({required String requesterDeviceId}) async {
    final uid = await _uidOrThrow();
    final docRef = _doc(uid);
    final now = DateTime.now();
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
      final updatedAt = (data['lastUpdatedAt'] as Timestamp?)?.toDate();
      if (updatedAt != null &&
          now.difference(updatedAt) >= _ownerStaleThreshold) {
        tx.set(
          docRef,
          {
            'ownerDeviceId': requesterDeviceId,
            'ownershipRequest': FieldValue.delete(),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
      final rawRequest = data['ownershipRequest'];
      final requestMap = rawRequest is Map<String, dynamic>
          ? rawRequest
          : rawRequest is Map
              ? Map<String, dynamic>.from(rawRequest)
              : null;
      final status = requestMap?['status'] as String?;
      final requester = requestMap?['requesterDeviceId'] as String?;
      if (status == 'pending' && requester != requesterDeviceId) {
        return;
      }
      tx.set(
        docRef,
        {
          'ownershipRequest': {
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
      if (approved) {
        tx.set(
          docRef,
          {
            'ownerDeviceId': requesterDeviceId,
            'ownershipRequest': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
        return;
      }
      tx.set(
        docRef,
        {
          'ownershipRequest': {
            'requesterDeviceId': requesterDeviceId,
            'status': 'rejected',
            'requestedAt': requestMap?['requestedAt'],
            'respondedAt': FieldValue.serverTimestamp(),
            'respondedByDeviceId': ownerDeviceId,
          },
        },
        SetOptions(merge: true),
      );
    });
  }
}

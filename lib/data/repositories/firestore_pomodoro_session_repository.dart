import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pomodoro_session.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'pomodoro_session_repository.dart';

class FirestorePomodoroSessionRepository implements PomodoroSessionRepository {
  final FirestoreService firestoreService;
  final AuthService authService;
  final String deviceId;

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
    await _doc(uid).set(data, SetOptions(merge: true));
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
}

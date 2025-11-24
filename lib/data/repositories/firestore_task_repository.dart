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
    if (uid == null) throw Exception('No hay usuario autenticado');
    return uid;
  }

  @override
  Future<List<PomodoroTask>> getAll() async {
    final uid = await _uidOrThrow();
    final snap = await _taskCollection(uid).get();
    return snap.docs.map((d) => PomodoroTask.fromMap(d.data())).toList();
  }

  @override
  Future<PomodoroTask?> getById(String id) async {
    final uid = await _uidOrThrow();
    final doc = await _taskCollection(uid).doc(id).get();
    if (!doc.exists) return null;
    return PomodoroTask.fromMap(doc.data()!);
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

  /// Si quieres stream (opcional)
  Stream<List<PomodoroTask>> watchTasks() {
    final uid = authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _taskCollection(uid).snapshots().map(
      (snap) => snap.docs.map((d) => PomodoroTask.fromMap(d.data())).toList(),
    );
  }
}

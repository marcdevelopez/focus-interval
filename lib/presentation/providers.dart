import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_machine.dart';
import '../data/models/pomodoro_task.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/firestore_task_repository.dart';
import '../data/services/sound_service.dart';
import '../data/services/device_info_service.dart';
import '../data/repositories/pomodoro_session_repository.dart';
import '../data/repositories/firestore_pomodoro_session_repository.dart';

// VIEWMODELS
import 'viewmodels/pomodoro_view_model.dart';
import 'viewmodels/task_list_view_model.dart';
import 'viewmodels/task_editor_view_model.dart';

//
// ==============================================================
//  REPO GLOBAL (MVP LOCAL)
// ==============================================================
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthServiceProvider).authStateChanges,
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState != null) return ref.watch(firestoreTaskRepositoryProvider);
  return InMemoryTaskRepository();
});

//
// ==============================================================
//  MÁQUINA DE ESTADOS DEL POMODORO
// ==============================================================
final pomodoroMachineProvider = Provider.autoDispose<PomodoroMachine>((ref) {
  final machine = PomodoroMachine();
  ref.onDispose(machine.dispose);
  return machine;
});

//
// ==============================================================
//  SERVICIOS FIREBASE (FASE 6 — real configurable)
// ==============================================================
final firebaseAuthServiceProvider =
    Provider<AuthService>((_) => FirebaseAuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirebaseFirestoreService());

// Repositorio Firestore de tareas
final firestoreTaskRepositoryProvider =
    Provider<FirestoreTaskRepository>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  return FirestoreTaskRepository(
    firestoreService: firestore,
    authService: auth,
  );
});

// Servicio de sonidos
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

// Device info (id único por ejecución)
final deviceInfoServiceProvider = Provider<DeviceInfoService>((_) {
  return DeviceInfoService();
});

// Repositorio de sesión Pomodoro
final pomodoroSessionRepositoryProvider =
    Provider<PomodoroSessionRepository>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  return FirestorePomodoroSessionRepository(
    firestoreService: firestore,
    authService: auth,
    deviceId: deviceInfo.deviceId,
  );
});

//
// ==============================================================
//  VIEWMODEL PRINCIPAL — POMODORO
// ==============================================================
final pomodoroViewModelProvider =
    NotifierProvider.autoDispose<PomodoroViewModel, PomodoroState>(
      PomodoroViewModel.new,
    );

//
// ==============================================================
//  LISTA DE TAREAS — AsyncNotifier<List<PomodoroTask>>
// ==============================================================
final taskListProvider =
    AsyncNotifierProvider<TaskListViewModel, List<PomodoroTask>>(
      TaskListViewModel.new,
    );

//
// ==============================================================
//  EDITOR DE TAREA — Notifier<PomodoroTask?>
// ==============================================================
final taskEditorProvider = NotifierProvider<TaskEditorViewModel, PomodoroTask?>(
  TaskEditorViewModel.new,
);

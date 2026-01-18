import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_machine.dart';
import '../data/models/pomodoro_task.dart';
import '../data/models/pomodoro_session.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/local_task_repository.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/firestore_task_repository.dart';
import '../data/services/sound_service.dart';
import '../data/services/device_info_service.dart';
import '../data/services/notification_service.dart';
import '../data/repositories/pomodoro_session_repository.dart';
import '../data/repositories/firestore_pomodoro_session_repository.dart';
import '../data/repositories/task_run_group_repository.dart';
import '../data/repositories/firestore_task_run_group_repository.dart';
import '../data/services/local_sound_storage.dart';
import '../data/services/local_sound_overrides.dart';
import '../data/services/task_run_retention_service.dart';

// VIEWMODELS
import 'viewmodels/pomodoro_view_model.dart';
import 'viewmodels/task_list_view_model.dart';
import 'viewmodels/task_editor_view_model.dart';
import 'viewmodels/task_selection_view_model.dart';

//
// ==============================================================
//  GLOBAL REPO (LOCAL MVP)
// ==============================================================
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthServiceProvider).authStateChanges,
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState != null) return ref.watch(firestoreTaskRepositoryProvider);
  if (!_supportsFirebase) return LocalTaskRepository();
  return InMemoryTaskRepository();
});

//
// ==============================================================
//  POMODORO STATE MACHINE
// ==============================================================
final pomodoroMachineProvider = Provider.autoDispose<PomodoroMachine>((ref) {
  final machine = PomodoroMachine();
  ref.onDispose(machine.dispose);
  return machine;
});

//
// ==============================================================
//  FIREBASE SERVICES (PHASE 6 — configurable real services)
// ==============================================================
final firebaseAuthServiceProvider = Provider<AuthService>((_) {
  if (!_supportsFirebase) return StubAuthService();
  return FirebaseAuthService();
});
final firestoreServiceProvider = Provider<FirestoreService>((_) {
  if (!_supportsFirebase) return StubFirestoreService();
  return FirebaseFirestoreService();
});

// Firestore task repository
final firestoreTaskRepositoryProvider = Provider<FirestoreTaskRepository>((
  ref,
) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  return FirestoreTaskRepository(
    firestoreService: firestore,
    authService: auth,
  );
});

// Sound service
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

// Notifications (overridden in main with initialized service)
final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationService.disabled();
});

// Device info (overridden in main with persisted id)
final deviceInfoServiceProvider = Provider<DeviceInfoService>((_) {
  return DeviceInfoService.ephemeral();
});

// Pomodoro session repository
final pomodoroSessionRepositoryProvider = Provider<PomodoroSessionRepository>((
  ref,
) {
  final authState = ref.watch(authStateProvider).value;
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  if (authState == null) {
    return NoopPomodoroSessionRepository();
  }
  return FirestorePomodoroSessionRepository(
    firestoreService: firestore,
    authService: auth,
    deviceId: deviceInfo.deviceId,
  );
});

// Task run group retention settings
final taskRunRetentionServiceProvider = Provider<TaskRunRetentionService>((_) {
  return TaskRunRetentionService();
});

// Task run group repository
final taskRunGroupRepositoryProvider = Provider<TaskRunGroupRepository>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return NoopTaskRunGroupRepository();
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  final retention = ref.watch(taskRunRetentionServiceProvider);
  return FirestoreTaskRunGroupRepository(
    firestoreService: firestore,
    authService: auth,
    retentionService: retention,
  );
});

// Active session stream (used for global execution guards).
final pomodoroSessionStreamProvider = StreamProvider<PomodoroSession?>((ref) {
  final repo = ref.watch(pomodoroSessionRepositoryProvider);
  return repo.watchSession();
});

final activePomodoroSessionProvider = Provider<PomodoroSession?>((ref) {
  final session = ref.watch(pomodoroSessionStreamProvider).value;
  if (session == null) return null;
  return session.status.isActiveExecution ? session : null;
});

//
// ==============================================================
//  MAIN VIEWMODEL — POMODORO
// ==============================================================
final pomodoroViewModelProvider =
    NotifierProvider.autoDispose<PomodoroViewModel, PomodoroState>(
      PomodoroViewModel.new,
    );

//
// ==============================================================
//  TASK LIST — AsyncNotifier<List<PomodoroTask>>
// ==============================================================
final taskListProvider =
    AsyncNotifierProvider<TaskListViewModel, List<PomodoroTask>>(
      TaskListViewModel.new,
    );

//
// ==============================================================
//  TASK EDITOR — Notifier<PomodoroTask?>
// ==============================================================
final taskEditorProvider = NotifierProvider<TaskEditorViewModel, PomodoroTask?>(
  TaskEditorViewModel.new,
);

final taskSelectionProvider =
    NotifierProvider.autoDispose<TaskSelectionViewModel, Set<String>>(
      TaskSelectionViewModel.new,
    );

final localSoundStorageProvider = Provider<LocalSoundStorage>((_) {
  return createLocalSoundStorage();
});

final localSoundOverridesProvider = Provider<LocalSoundOverrides>((_) {
  return LocalSoundOverrides();
});

bool get _supportsFirebase {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

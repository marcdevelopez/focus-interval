import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../domain/pomodoro_machine.dart';
import '../domain/task_weighting.dart';
import '../data/models/pomodoro_task.dart';
import '../data/models/pomodoro_preset.dart';
import '../data/models/pomodoro_session.dart';
import '../data/models/task_run_group.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/local_task_repository.dart';
import '../data/repositories/pomodoro_preset_repository.dart';
import '../data/repositories/local_pomodoro_preset_repository.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/firestore_task_repository.dart';
import '../data/repositories/firestore_pomodoro_preset_repository.dart';
import '../data/services/sound_service.dart';
import '../data/services/device_info_service.dart';
import '../data/services/notification_service.dart';
import '../data/repositories/pomodoro_session_repository.dart';
import '../data/repositories/firestore_pomodoro_session_repository.dart';
import '../data/repositories/task_run_group_repository.dart';
import '../data/repositories/firestore_task_run_group_repository.dart';
import '../data/repositories/local_task_run_group_repository.dart';
import '../data/services/local_sound_storage.dart';
import '../data/services/local_sound_overrides.dart';
import '../data/services/task_run_retention_service.dart';
import '../data/services/task_run_notice_service.dart';
import '../data/services/app_mode_service.dart';

// VIEWMODELS
import 'viewmodels/pomodoro_view_model.dart';
import 'viewmodels/task_list_view_model.dart';
import 'viewmodels/task_editor_view_model.dart';
import 'viewmodels/task_selection_view_model.dart';
import 'viewmodels/preset_list_view_model.dart';
import 'viewmodels/preset_editor_view_model.dart';

//
// ==============================================================
//  GLOBAL REPO (LOCAL MVP)
// ==============================================================
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthServiceProvider).userChanges,
);

final appModeServiceProvider = Provider<AppModeService>((_) {
  throw UnimplementedError('AppModeService must be initialized in main.dart');
});

class AppModeController extends Notifier<AppMode> {
  late AppModeService _service;

  @override
  AppMode build() {
    _service = ref.watch(appModeServiceProvider);
    return _service.readMode();
  }

  Future<void> setMode(AppMode mode) async {
    if (state == mode) return;
    state = mode;
    await _service.saveMode(mode);
  }

  Future<void> setLocal() => setMode(AppMode.local);

  Future<void> setAccount() => setMode(AppMode.account);
}

final appModeProvider = NotifierProvider<AppModeController, AppMode>(
  AppModeController.new,
);

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(firebaseAuthServiceProvider);
  final authState = ref.watch(authStateProvider).value;
  return authState ?? auth.currentUser;
});

final emailVerificationRequiredProvider = Provider<bool>((ref) {
  final auth = ref.watch(firebaseAuthServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return auth.requiresEmailVerification;
});

final accountSyncEnabledProvider = Provider<bool>((ref) {
  final appMode = ref.watch(appModeProvider);
  if (appMode != AppMode.account) return false;
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final auth = ref.watch(firebaseAuthServiceProvider);
  return !auth.requiresEmailVerification;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final appMode = ref.watch(appModeProvider);
  final authState = ref.watch(authStateProvider).value;
  if (appMode == AppMode.local) {
    return LocalTaskRepository();
  }
  final syncEnabled = ref.watch(accountSyncEnabledProvider);
  if (authState == null || !syncEnabled) return NoopTaskRepository();
  return ref.watch(firestoreTaskRepositoryProvider);
});

final presetRepositoryProvider = Provider<PomodoroPresetRepository>((ref) {
  final appMode = ref.watch(appModeProvider);
  final authState = ref.watch(authStateProvider).value;
  final user = ref.watch(currentUserProvider);
  if (appMode == AppMode.local) {
    return LocalPomodoroPresetRepository();
  }
  final syncEnabled = ref.watch(accountSyncEnabledProvider);
  if (authState == null || user == null) return NoopPomodoroPresetRepository();
  if (!syncEnabled) {
    return LocalPomodoroPresetRepository(
      prefsKey: 'account_presets_v1_${user.uid}',
    );
  }
  return ref.watch(firestorePresetRepositoryProvider);
});

final accountLocalPresetRepositoryProvider =
    Provider<LocalPomodoroPresetRepository>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return LocalPomodoroPresetRepository(
          prefsKey: 'account_presets_v1_unknown',
        );
      }
      return LocalPomodoroPresetRepository(
        prefsKey: 'account_presets_v1_${user.uid}',
      );
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

final firestorePresetRepositoryProvider =
    Provider<FirestorePomodoroPresetRepository>((ref) {
      final firestore = ref.watch(firestoreServiceProvider);
      final auth = ref.watch(firebaseAuthServiceProvider);
      return FirestorePomodoroPresetRepository(
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
  final appMode = ref.watch(appModeProvider);
  if (appMode == AppMode.local) {
    return NoopPomodoroSessionRepository();
  }
  final authState = ref.watch(authStateProvider).value;
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(firebaseAuthServiceProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  final syncEnabled = ref.watch(accountSyncEnabledProvider);
  if (authState == null || !syncEnabled) {
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

final taskRunNoticeServiceProvider = Provider<TaskRunNoticeService>((ref) {
  final appMode = ref.watch(appModeProvider);
  final syncEnabled = ref.watch(accountSyncEnabledProvider);
  final useAccount = appMode == AppMode.account && syncEnabled;
  if (!useAccount) {
    return TaskRunNoticeService();
  }
  final auth = ref.watch(firebaseAuthServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return TaskRunNoticeService(
    authService: auth,
    firestoreService: firestore,
    useAccount: true,
  );
});

// Task run group repository
final taskRunGroupRepositoryProvider = Provider<TaskRunGroupRepository>((ref) {
  final appMode = ref.watch(appModeProvider);
  if (appMode == AppMode.local) {
    final retention = ref.watch(taskRunRetentionServiceProvider);
    return LocalTaskRunGroupRepository(retentionService: retention);
  }
  final authState = ref.watch(authStateProvider).value;
  final auth = ref.watch(firebaseAuthServiceProvider);
  final user = authState ?? auth.currentUser;
  final syncEnabled = ref.watch(accountSyncEnabledProvider);
  if (user == null || !syncEnabled) return NoopTaskRunGroupRepository();
  final firestore = ref.watch(firestoreServiceProvider);
  final retention = ref.watch(taskRunRetentionServiceProvider);
  return FirestoreTaskRunGroupRepository(
    firestoreService: firestore,
    authService: auth,
    retentionService: retention,
  );
});

final taskRunGroupStreamProvider = StreamProvider<List<TaskRunGroup>>((ref) {
  final repo = ref.watch(taskRunGroupRepositoryProvider);
  return repo.watchAll();
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

class RunningOverlapDecision {
  final String runningGroupId;
  final String scheduledGroupId;
  final int token;

  const RunningOverlapDecision({
    required this.runningGroupId,
    required this.scheduledGroupId,
    required this.token,
  });
}

final scheduledAutoStartGroupIdProvider = StateProvider<String?>((_) => null);
final runningOverlapDecisionProvider =
    StateProvider<RunningOverlapDecision?>((_) => null);
final completionDialogVisibleProvider = StateProvider<bool>((_) => false);


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

final presetListProvider =
    AsyncNotifierProvider<PresetListViewModel, List<PomodoroPreset>>(
      PresetListViewModel.new,
    );

//
// ==============================================================
//  TASK EDITOR — Notifier<PomodoroTask?>
// ==============================================================
final taskEditorProvider = NotifierProvider<TaskEditorViewModel, PomodoroTask?>(
  TaskEditorViewModel.new,
);

final presetEditorProvider =
    NotifierProvider<PresetEditorViewModel, PomodoroPreset?>(
      PresetEditorViewModel.new,
    );

final taskSelectionProvider =
    NotifierProvider.autoDispose<TaskSelectionViewModel, Set<String>>(
      TaskSelectionViewModel.new,
    );

final selectedTasksProvider = Provider<List<PomodoroTask>>((ref) {
  final selectedIds = ref.watch(taskSelectionProvider);
  final tasks = ref.watch(taskListProvider).asData?.value ?? const [];
  if (selectedIds.isEmpty || tasks.isEmpty) return const [];
  return [
    for (final task in tasks)
      if (selectedIds.contains(task.id)) task,
  ];
});

final selectedTaskWeightPercentsProvider =
    Provider<Map<String, int>>((ref) {
      final selectedTasks = ref.watch(selectedTasksProvider);
      return normalizeTaskWeightPercents(selectedTasks);
    });

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

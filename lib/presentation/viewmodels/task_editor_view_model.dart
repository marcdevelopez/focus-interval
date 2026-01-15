import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_task.dart';
import '../../data/models/pomodoro_session.dart';
import '../../domain/pomodoro_machine.dart';
import '../providers.dart';

enum TaskEditorLoadResult {
  loaded,
  notFound,
  blockedByActiveSession,
}

class TaskEditorViewModel extends Notifier<PomodoroTask?> {
  final _uuid = const Uuid();

  @override
  PomodoroTask? build() => null;

  // Create a new task with defaults.
  void createNew() {
    state = PomodoroTask(
      id: _uuid.v4(),
      name: "",
      pomodoroMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      totalPomodoros: 4,
      longBreakInterval: 4,
      startSound: 'default_chime',
      startBreakSound: 'default_chime_break',
      finishTaskSound: 'default_chime_finish',
    );
  }

  // Load existing by id. Returns a result to handle active-session guards.
  Future<TaskEditorLoadResult> load(String id) async {
    final session = await _readCurrentSession();
    if (session != null &&
        session.status.isActiveExecution &&
        session.taskId == id) {
      return TaskEditorLoadResult.blockedByActiveSession;
    }
    final repo = ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    state = task;
    return task == null
        ? TaskEditorLoadResult.notFound
        : TaskEditorLoadResult.loaded;
  }

  void update(PomodoroTask task) {
    state = task;
  }

  Future<bool> save() async {
    if (state == null) return false;
    final session = await _readCurrentSession();
    if (session != null &&
        session.status.isActiveExecution &&
        session.taskId == state!.id) {
      return false;
    }
    final repo = ref.read(taskRepositoryProvider);
    await repo.save(state!);
    return true;
  }

  Future<PomodoroSession?> _readCurrentSession() async {
    final repo = ref.read(pomodoroSessionRepositoryProvider);
    try {
      return await repo.watchSession().first;
    } on StateError {
      return null;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pomodoro_task.dart';
import '../providers.dart';

class TaskEditorViewModel extends Notifier<PomodoroTask?> {
  final _uuid = const Uuid();

  @override
  PomodoroTask? build() => null;

  // Crear nueva tarea con defaults
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

  // Cargar existente por id. Devuelve false si no se encuentra.
  Future<bool> load(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    state = task;
    return task != null;
  }

  void update(PomodoroTask task) {
    state = task;
  }

  Future<void> save() async {
    if (state == null) return;
    final repo = ref.read(taskRepositoryProvider);
    await repo.save(state!);
  }
}

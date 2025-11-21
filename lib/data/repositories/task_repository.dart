import '../models/pomodoro_task.dart';

abstract class TaskRepository {
  Future<List<PomodoroTask>> getAll();
  Future<PomodoroTask?> getById(String id);
  Future<void> save(PomodoroTask task);
  Future<void> delete(String id);
}

/// Implementación temporal (MVP local)
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, PomodoroTask> _store = {};

  @override
  Future<List<PomodoroTask>> getAll() async {
    return _store.values.toList();
  }

  @override
  Future<PomodoroTask?> getById(String id) async {
    return _store[id];
  }

  @override
  Future<void> save(PomodoroTask task) async {
    _store[task.id] = task;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }
}

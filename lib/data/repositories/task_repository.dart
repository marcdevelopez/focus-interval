import 'dart:async';

import '../models/pomodoro_task.dart';

abstract class TaskRepository {
  Future<List<PomodoroTask>> getAll();
  Future<PomodoroTask?> getById(String id);
  Future<void> save(PomodoroTask task);
  Future<void> delete(String id);
  Stream<List<PomodoroTask>> watchAll();
}

/// Implementación temporal (MVP local)
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, PomodoroTask> _store = {};
  final StreamController<List<PomodoroTask>> _controller;

  InMemoryTaskRepository()
      : _controller = StreamController<List<PomodoroTask>>.broadcast(
          sync: true,
          onListen: () {
            // Emit el estado actual en cuanto alguien se suscribe.
          },
        ) {
    _controller.onListen = _emit;
  }

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
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Stream<List<PomodoroTask>> watchAll() => _controller.stream;

  void _emit() {
    _controller.add(_store.values.toList());
  }
}

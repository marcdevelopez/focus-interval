import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pomodoro_task.dart';
import '../../data/repositories/task_repository.dart';
import '../providers.dart';

class TaskListViewModel extends AsyncNotifier<List<PomodoroTask>> {
  StreamSubscription<List<PomodoroTask>>? _sub;

  @override
  Future<List<PomodoroTask>> build() async {
    final repo = ref.watch(taskRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());
    return _listenToRepo(repo);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(taskRepositoryProvider);
    await _sub?.cancel();
    await _listenToRepo(repo);
  }

  Future<void> deleteTask(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.delete(id);
  }

  Future<List<PomodoroTask>> _listenToRepo(TaskRepository repo) async {
    await _sub?.cancel();
    final completer = Completer<List<PomodoroTask>>();

    _sub = repo.watchAll().listen(
      (tasks) {
        state = AsyncData(tasks);
        if (!completer.isCompleted) {
          completer.complete(tasks);
        }
      },
      onError: (error, stack) {
        state = AsyncError(error, stack);
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
    );

    return completer.future;
  }
}

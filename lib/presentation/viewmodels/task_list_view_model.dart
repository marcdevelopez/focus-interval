import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pomodoro_task.dart';
import '../../data/repositories/task_repository.dart';
import '../providers.dart';

class TaskListViewModel extends AsyncNotifier<List<PomodoroTask>> {
  StreamSubscription<List<PomodoroTask>>? _sub;
  List<PomodoroTask> _last = const [];

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

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final repo = ref.read(taskRepositoryProvider);
    final current = [..._last];
    if (current.isEmpty) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);

    final updated = <PomodoroTask>[];
    final now = DateTime.now();
    for (var i = 0; i < current.length; i += 1) {
      updated.add(current[i].copyWith(order: i, updatedAt: now));
    }
    _last = updated;
    state = AsyncData(updated);
    await Future.wait(updated.map(repo.save));
  }

  Future<List<PomodoroTask>> _listenToRepo(TaskRepository repo) async {
    await _sub?.cancel();
    final completer = Completer<List<PomodoroTask>>();

    _sub = repo.watchAll().listen(
      (tasks) {
        final ordered = [...tasks]
          ..sort((a, b) {
            final order = a.order.compareTo(b.order);
            if (order != 0) return order;
            return a.createdAt.compareTo(b.createdAt);
          });
        _last = ordered;
        state = AsyncData(ordered);
        if (!completer.isCompleted) {
          completer.complete(ordered);
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

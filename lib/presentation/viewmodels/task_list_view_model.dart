import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pomodoro_task.dart';
import '../providers.dart';

class TaskListViewModel extends AsyncNotifier<List<PomodoroTask>> {
  @override
  Future<List<PomodoroTask>> build() async {
    // Si cambia el usuario autenticado (login/logout), recargamos la lista desde el repo activo.
    ref.listen(authStateProvider, (prev, next) {
      final prevUid = prev?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        refresh();
      }
    });

    final repo = ref.watch(taskRepositoryProvider);
    return repo.getAll();
    }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  Future<void> deleteTask(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.delete(id);
    await refresh();
  }
}

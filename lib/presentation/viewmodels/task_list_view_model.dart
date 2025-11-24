import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pomodoro_task.dart';
import '../providers.dart';

class TaskListViewModel extends AsyncNotifier<List<PomodoroTask>> {
  @override
  Future<List<PomodoroTask>> build() async {
    // Si cambia el usuario autenticado, recargamos la lista desde el repo activo.
    ref.listen(firebaseAuthServiceProvider, (prev, next) {
      final prevUid = prev?.currentUser?.uid;
      final nextUid = next.currentUser?.uid;
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

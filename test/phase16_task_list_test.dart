import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_interval/data/models/pomodoro_task.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/repositories/task_repository.dart';
import 'package:focus_interval/presentation/providers.dart';

PomodoroTask _task({required String id, required int order}) {
  final now = DateTime(2026, 1, 18, 12, 0, 0).add(Duration(minutes: order));
  return PomodoroTask(
    id: id,
    name: 'Task $id',
    dataVersion: kCurrentDataVersion,
    pomodoroMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    totalPomodoros: 2,
    longBreakInterval: 2,
    order: order,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('TaskSelectionViewModel toggles and syncs', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final selection = container.read(taskSelectionProvider.notifier);

    expect(container.read(taskSelectionProvider), isEmpty);
    selection.toggle('a');
    expect(container.read(taskSelectionProvider), {'a'});

    selection.toggle('a');
    expect(container.read(taskSelectionProvider), isEmpty);

    selection.toggle('a');
    selection.toggle('b');
    selection.syncWithIds(['b']);
    expect(container.read(taskSelectionProvider), {'b'});
  });

  test('TaskListViewModel reorder persists order', () async {
    final repo = InMemoryTaskRepository();
    final container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await repo.save(_task(id: 't1', order: 0));
    await repo.save(_task(id: 't2', order: 1));
    await repo.save(_task(id: 't3', order: 2));

    await container.read(taskListProvider.future);

    await container.read(taskListProvider.notifier).reorderTasks(0, 3);

    final tasks = await repo.getAll();
    final byId = {for (final task in tasks) task.id: task.order};
    expect(byId['t2'], 0);
    expect(byId['t3'], 1);
    expect(byId['t1'], 2);
  });
}

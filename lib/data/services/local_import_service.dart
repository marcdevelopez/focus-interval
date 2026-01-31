import '../repositories/firestore_task_repository.dart';
import '../repositories/firestore_task_run_group_repository.dart';
import '../repositories/firestore_pomodoro_preset_repository.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/local_task_run_group_repository.dart';
import '../repositories/local_pomodoro_preset_repository.dart';

class LocalImportSummary {
  final int tasksImported;
  final int groupsImported;
  final int presetsImported;

  const LocalImportSummary({
    required this.tasksImported,
    required this.groupsImported,
    required this.presetsImported,
  });
}

class LocalImportService {
  final LocalTaskRepository localTasks;
  final LocalTaskRunGroupRepository localGroups;
  final LocalPomodoroPresetRepository localPresets;
  final FirestoreTaskRepository remoteTasks;
  final FirestoreTaskRunGroupRepository remoteGroups;
  final FirestorePomodoroPresetRepository remotePresets;

  LocalImportService({
    required this.localTasks,
    required this.localGroups,
    required this.localPresets,
    required this.remoteTasks,
    required this.remoteGroups,
    required this.remotePresets,
  });

  Future<bool> hasLocalData() async {
    final tasks = await localTasks.getAll();
    if (tasks.isNotEmpty) return true;
    final groups = await localGroups.getAll();
    if (groups.isNotEmpty) return true;
    final presets = await localPresets.getAll();
    return presets.isNotEmpty;
  }

  Future<LocalImportSummary> importAll() async {
    final tasks = await localTasks.getAll();
    final groups = await localGroups.getAll();
    final presets = await localPresets.getAll();

    for (final task in tasks) {
      await remoteTasks.save(task);
    }

    for (final group in groups) {
      await remoteGroups.save(group);
    }

    for (final preset in presets) {
      await remotePresets.save(preset);
    }

    return LocalImportSummary(
      tasksImported: tasks.length,
      groupsImported: groups.length,
      presetsImported: presets.length,
    );
  }
}

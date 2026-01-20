import '../repositories/firestore_task_repository.dart';
import '../repositories/firestore_task_run_group_repository.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/local_task_run_group_repository.dart';

class LocalImportSummary {
  final int tasksImported;
  final int groupsImported;

  const LocalImportSummary({
    required this.tasksImported,
    required this.groupsImported,
  });
}

class LocalImportService {
  final LocalTaskRepository localTasks;
  final LocalTaskRunGroupRepository localGroups;
  final FirestoreTaskRepository remoteTasks;
  final FirestoreTaskRunGroupRepository remoteGroups;

  LocalImportService({
    required this.localTasks,
    required this.localGroups,
    required this.remoteTasks,
    required this.remoteGroups,
  });

  Future<bool> hasLocalData() async {
    final tasks = await localTasks.getAll();
    if (tasks.isNotEmpty) return true;
    final groups = await localGroups.getAll();
    return groups.isNotEmpty;
  }

  Future<LocalImportSummary> importAll() async {
    final tasks = await localTasks.getAll();
    final groups = await localGroups.getAll();

    for (final task in tasks) {
      await remoteTasks.save(task);
    }

    for (final group in groups) {
      await remoteGroups.save(group);
    }

    return LocalImportSummary(
      tasksImported: tasks.length,
      groupsImported: groups.length,
    );
  }
}

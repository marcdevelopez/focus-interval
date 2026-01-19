import '../models/task_run_group.dart';

abstract class TaskRunGroupRepository {
  Stream<List<TaskRunGroup>> watchAll();
  Future<List<TaskRunGroup>> getAll();
  Future<TaskRunGroup?> getById(String id);
  Future<void> save(TaskRunGroup group);
  Future<void> delete(String id);
  Future<void> prune({int? keepCompleted});
}

class NoopTaskRunGroupRepository implements TaskRunGroupRepository {
  @override
  Stream<List<TaskRunGroup>> watchAll() => const Stream.empty();

  @override
  Future<List<TaskRunGroup>> getAll() async => const [];

  @override
  Future<TaskRunGroup?> getById(String id) async => null;

  @override
  Future<void> save(TaskRunGroup group) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> prune({int? keepCompleted}) async {}
}

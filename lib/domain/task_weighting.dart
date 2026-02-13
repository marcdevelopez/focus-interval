import '../data/models/pomodoro_task.dart';

int taskWorkMinutes(PomodoroTask task) {
  return task.totalPomodoros * task.pomodoroMinutes;
}

Map<String, int> normalizeTaskWeightPercents(List<PomodoroTask> tasks) {
  if (tasks.isEmpty) return const {};
  final workById = <String, int>{};
  var totalWork = 0;
  for (final task in tasks) {
    final work = taskWorkMinutes(task);
    workById[task.id] = work;
    totalWork += work;
  }
  if (totalWork <= 0) return const {};
  final result = <String, int>{};
  workById.forEach((id, work) {
    result[id] = ((work / totalWork) * 100).round();
  });
  return result;
}

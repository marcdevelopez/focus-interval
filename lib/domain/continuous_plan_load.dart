import '../data/models/pomodoro_task.dart';
import '../data/models/task_run_group.dart';

enum ContinuousPlanLoadLevel { none, unusual, superhuman, machineLevel }

const int unusualThresholdSeconds = 11 * 60 * 60;
const int superhumanThresholdSeconds = 24 * 60 * 60;
const int machineLevelThresholdSeconds = 72 * 60 * 60;

ContinuousPlanLoadLevel continuousPlanLoadLevelForSeconds(int seconds) {
  if (seconds >= machineLevelThresholdSeconds) {
    return ContinuousPlanLoadLevel.machineLevel;
  }
  if (seconds >= superhumanThresholdSeconds) {
    return ContinuousPlanLoadLevel.superhuman;
  }
  if (seconds >= unusualThresholdSeconds) {
    return ContinuousPlanLoadLevel.unusual;
  }
  return ContinuousPlanLoadLevel.none;
}

String continuousPlanLoadLabel(ContinuousPlanLoadLevel level) {
  switch (level) {
    case ContinuousPlanLoadLevel.unusual:
      return 'Unusual';
    case ContinuousPlanLoadLevel.superhuman:
      return 'Superhuman';
    case ContinuousPlanLoadLevel.machineLevel:
      return 'Machine';
    case ContinuousPlanLoadLevel.none:
      return '';
  }
}

String? continuousPlanLoadMessage(ContinuousPlanLoadLevel level) {
  switch (level) {
    case ContinuousPlanLoadLevel.unusual:
      return 'Unusually high total focus time. Are you sure?';
    case ContinuousPlanLoadLevel.superhuman:
      return 'Superhuman plan detected. Double-check this is intentional.';
    case ContinuousPlanLoadLevel.machineLevel:
      return 'Machine-level schedule. Proceed only if this is really intended.';
    case ContinuousPlanLoadLevel.none:
      return null;
  }
}

TaskRunIntegrityMode resolvePreviewIntegrityMode(List<PomodoroTask> tasks) {
  if (_hasMixedStructure(tasks)) return TaskRunIntegrityMode.individual;
  return TaskRunIntegrityMode.shared;
}

int continuousGroupDurationSecondsForTasks(List<PomodoroTask> tasks) {
  if (tasks.isEmpty) return 0;
  final runItems = [for (final task in tasks) _runItemFromTask(task)];
  return groupDurationSecondsByMode(
    runItems,
    resolvePreviewIntegrityMode(tasks),
  );
}

List<int> continuousTaskDurationsSecondsForTasks(List<PomodoroTask> tasks) {
  if (tasks.isEmpty) return const [];
  final runItems = [for (final task in tasks) _runItemFromTask(task)];
  return taskDurationSecondsByMode(
    runItems,
    resolvePreviewIntegrityMode(tasks),
  );
}

TaskRunItem _runItemFromTask(PomodoroTask task) {
  return TaskRunItem(
    sourceTaskId: task.id,
    name: task.name,
    presetId: task.presetId,
    pomodoroMinutes: task.pomodoroMinutes,
    shortBreakMinutes: task.shortBreakMinutes,
    longBreakMinutes: task.longBreakMinutes,
    totalPomodoros: task.totalPomodoros,
    longBreakInterval: task.longBreakInterval,
    startSound: task.startSound,
    startBreakSound: task.startBreakSound,
    finishTaskSound: task.finishTaskSound,
  );
}

bool _hasMixedStructure(List<PomodoroTask> tasks) {
  if (tasks.length <= 1) return false;
  final first = tasks.first;
  for (final task in tasks.skip(1)) {
    final samePomodoro = task.pomodoroMinutes == first.pomodoroMinutes;
    final sameShort = task.shortBreakMinutes == first.shortBreakMinutes;
    final sameLong = task.longBreakMinutes == first.longBreakMinutes;
    final sameInterval = task.longBreakInterval == first.longBreakInterval;
    if (!samePomodoro || !sameShort || !sameLong || !sameInterval) {
      return true;
    }
  }
  return false;
}

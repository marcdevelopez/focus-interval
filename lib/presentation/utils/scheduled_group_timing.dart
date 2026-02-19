import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../domain/pomodoro_machine.dart';

TaskRunGroup? findGroupById(List<TaskRunGroup> groups, String id) {
  for (final group in groups) {
    if (group.id == id) return group;
  }
  return null;
}

int resolveNoticeMinutes(TaskRunGroup group) {
  return group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
}

int resolveGroupDurationSeconds(TaskRunGroup group) {
  return group.totalDurationSeconds ??
      groupDurationSecondsByMode(group.tasks, group.integrityMode);
}

DateTime? resolveGroupBaseEnd(TaskRunGroup group) {
  final start = group.actualStartTime;
  if (start == null) return null;
  final end = group.theoreticalEndTime;
  if (end.isBefore(start)) {
    final totalSeconds = resolveGroupDurationSeconds(group);
    if (totalSeconds > 0) {
      return start.add(Duration(seconds: totalSeconds));
    }
  }
  return end;
}

DateTime? resolveProjectedRunningEnd({
  required TaskRunGroup runningGroup,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final baseEnd = resolveGroupBaseEnd(runningGroup);
  if (baseEnd == null) return null;
  if (activeSession == null) return baseEnd;
  if (activeSession.groupId != runningGroup.id) return baseEnd;
  if (activeSession.status != PomodoroStatus.paused) return baseEnd;
  final pausedAt = activeSession.pausedAt;
  if (pausedAt == null) return baseEnd;
  final extra = now.difference(pausedAt);
  if (extra.inSeconds <= 0) return baseEnd;
  return baseEnd.add(extra);
}

DateTime? resolvePostponedAnchorEnd({
  required TaskRunGroup anchor,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  if (anchor.status == TaskRunStatus.running) {
    return resolveProjectedRunningEnd(
      runningGroup: anchor,
      activeSession: activeSession,
      now: now,
    );
  }
  final updatedAt = anchor.updatedAt;
  if (updatedAt.isAfter(anchor.createdAt)) return updatedAt;
  return resolveGroupBaseEnd(anchor) ?? updatedAt;
}

DateTime? resolveEffectiveScheduledStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = group.scheduledStartTime;
  if (scheduledStart == null) return null;
  final anchorId = group.postponedAfterGroupId;
  if (anchorId == null) return scheduledStart;
  final anchor = findGroupById(allGroups, anchorId);
  if (anchor == null) return scheduledStart;
  final anchorEnd = resolvePostponedAnchorEnd(
    anchor: anchor,
    activeSession: activeSession,
    now: now,
  );
  if (anchorEnd == null) return scheduledStart;
  final noticeMinutes = resolveNoticeMinutes(group);
  return anchorEnd.add(Duration(minutes: noticeMinutes));
}

DateTime? resolveEffectivePreRunStart({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (scheduledStart == null) return null;
  final noticeMinutes = resolveNoticeMinutes(group);
  if (noticeMinutes <= 0) return scheduledStart;
  return scheduledStart.subtract(Duration(minutes: noticeMinutes));
}

DateTime? resolveEffectiveScheduledEnd({
  required TaskRunGroup group,
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required DateTime now,
}) {
  final scheduledStart = resolveEffectiveScheduledStart(
    group: group,
    allGroups: allGroups,
    activeSession: activeSession,
    now: now,
  );
  if (scheduledStart == null) return null;
  final durationSeconds = resolveGroupDurationSeconds(group);
  return scheduledStart.add(Duration(seconds: durationSeconds));
}

bool isPostponedAfterGroup(TaskRunGroup group, String anchorId) {
  return group.postponedAfterGroupId == anchorId;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../viewmodels/task_editor_view_model.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/models/pomodoro_task.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  static const String _linuxSyncNoticeKey = 'linux_sync_notice_seen';
  final _timeFormat = DateFormat('HH:mm');
  bool _syncNoticeChecked = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLinuxSyncNotice();
    });
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowLinuxSyncNotice() async {
    if (_syncNoticeChecked) return;
    _syncNoticeChecked = true;
    final auth = ref.read(firebaseAuthServiceProvider);
    if (auth is! StubAuthService) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_linuxSyncNoticeKey) ?? false;
    if (seen) return;
    if (!mounted) return;
    await _showLinuxSyncInfoDialog();
    await prefs.setBool(_linuxSyncNoticeKey, true);
  }

  Future<void> _handleSyncInfoTap() async {
    await _showLinuxSyncInfoDialog();
    await _setSyncNoticeSeen();
  }

  Future<void> _setSyncNoticeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_linuxSyncNoticeKey, true);
  }

  Future<void> _showLinuxSyncInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sync across devices'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Linux desktop does not support sign-in yet, so tasks stay on '
                  'this machine.',
                ),
                SizedBox(height: 8),
                Text(
                  'Use the web app in Chrome to sign in and sync in real time '
                  'with other devices.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final auth = ref.watch(firebaseAuthServiceProvider);
    final authSupported = auth is! StubAuthService;
    final activeSession = ref.watch(activePomodoroSessionProvider);
    final selectedIds = ref.watch(taskSelectionProvider);
    final selection = ref.read(taskSelectionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Your tasks"),
        actions: [
          if (authSupported && auth.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  auth.currentUser!.email ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.signOut();
                // Clear the in-memory list and navigate to login
                ref.invalidate(taskListProvider);
                if (context.mounted) context.go('/login');
              },
            ),
          ] else if (authSupported)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.go('/login'),
            ),
          if (!authSupported)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _handleSyncInfoTap,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(taskEditorProvider.notifier).createNew();
          context.push("/tasks/new");
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedIds.isEmpty
                ? null
                : () => _handleConfirm(
                    context,
                    tasksAsync: tasksAsync,
                    activeSession: activeSession,
                  ),
            child: const Text('Confirmar'),
          ),
        ),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
        ),
        data: (tasks) {
          selection.syncWithIds(tasks.map((t) => t.id));
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                "Your tasks will appear here",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final ranges = _buildSelectedTimeRanges(tasks, selectedIds, _now);

          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(taskListProvider.notifier)
                  .reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, i) {
              final t = tasks[i];
              return TaskCard(
                key: ValueKey(t.id),
                task: t,
                selected: selectedIds.contains(t.id),
                onSelected: (_) => selection.toggle(t.id),
                onTap: () => selection.toggle(t.id),
                timeRange: ranges[t.id],
                reorderHandle: ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.drag_handle, color: Colors.white38),
                  ),
                ),
                onEdit: () async {
                  if (activeSession != null && activeSession.taskId == t.id) {
                    _showSnackBar(
                      context,
                      "This task is running. Stop it before editing.",
                    );
                    return;
                  }
                  final result = await ref
                      .read(taskEditorProvider.notifier)
                      .load(t.id);
                  if (!context.mounted) return;
                  if (result == TaskEditorLoadResult.notFound) {
                    _showSnackBar(context, "Task not found.");
                    return;
                  }
                  if (result == TaskEditorLoadResult.blockedByActiveSession) {
                    _showSnackBar(
                      context,
                      "This task is running. Stop it before editing.",
                    );
                    return;
                  }
                  context.push("/tasks/edit/${t.id}");
                },
                onDelete: () {
                  if (activeSession != null && activeSession.taskId == t.id) {
                    _showSnackBar(
                      context,
                      "This task is running. Stop it before deleting.",
                    );
                    return;
                  }
                  ref.read(taskListProvider.notifier).deleteTask(t.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleConfirm(
    BuildContext context, {
    required AsyncValue<List<PomodoroTask>> tasksAsync,
    required PomodoroSession? activeSession,
  }) async {
    final selection = ref.read(taskSelectionProvider.notifier);
    final selectedIds = ref.read(taskSelectionProvider);
    final tasks = tasksAsync.asData?.value ?? [];
    final selected = tasks.where((t) => selectedIds.contains(t.id)).toList();
    if (selected.isEmpty) return;
    if (activeSession != null) {
      _showSnackBar(
        context,
        "A task is already running. Finish or cancel it first.",
      );
      return;
    }

    final auth = ref.read(firebaseAuthServiceProvider);
    if (auth.currentUser == null) {
      _showSnackBar(context, "Sign in to create task groups.");
      return;
    }

    final now = DateTime.now();
    final items = selected.map(_mapTaskToRunItem).toList();
    final totalDurationSeconds = items.fold<int>(
      0,
      (total, item) => total + item.totalDurationSeconds,
    );

    final group = TaskRunGroup(
      id: const Uuid().v4(),
      ownerUid: auth.currentUser!.uid,
      tasks: items,
      createdAt: now,
      scheduledStartTime: null,
      theoreticalEndTime: now.add(Duration(seconds: totalDurationSeconds)),
      status: TaskRunStatus.scheduled,
      noticeMinutes: null,
      totalTasks: items.length,
      totalPomodoros: items.fold<int>(
        0,
        (total, item) => total + item.totalPomodoros,
      ),
      totalDurationSeconds: totalDurationSeconds,
      updatedAt: now,
    );

    await ref.read(taskRunGroupRepositoryProvider).save(group);
    if (!context.mounted) return;
    selection.clear();
    _showSnackBar(context, "Task group created.");
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _buildSelectedTimeRanges(
    List<PomodoroTask> tasks,
    Set<String> selectedIds,
    DateTime start,
  ) {
    final ranges = <String, String>{};
    var cursor = start;
    for (final task in tasks) {
      if (!selectedIds.contains(task.id)) continue;
      final duration = _taskDurationSeconds(task);
      final end = cursor.add(Duration(seconds: duration));
      ranges[task.id] =
          "${_timeFormat.format(cursor)}–${_timeFormat.format(end)}";
      cursor = end;
    }
    return ranges;
  }

  int _taskDurationSeconds(PomodoroTask task) {
    final pomodoroSeconds = task.pomodoroMinutes * 60;
    final shortBreakSeconds = task.shortBreakMinutes * 60;
    final longBreakSeconds = task.longBreakMinutes * 60;
    var total = task.totalPomodoros * pomodoroSeconds;
    if (task.totalPomodoros <= 1) return total;
    for (var index = 1; index < task.totalPomodoros; index += 1) {
      final isLongBreak = index % task.longBreakInterval == 0;
      total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
    }
    return total;
  }

  TaskRunItem _mapTaskToRunItem(PomodoroTask task) {
    return TaskRunItem(
      sourceTaskId: task.id,
      name: task.name,
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
}

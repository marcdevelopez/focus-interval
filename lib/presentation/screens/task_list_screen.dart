import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../viewmodels/task_editor_view_model.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/models/pomodoro_preset.dart';
import '../../data/models/pomodoro_task.dart';
import '../../data/models/selected_sound.dart';
import '../../data/models/task_run_group.dart';
import '../../data/repositories/task_run_group_repository.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/app_mode_service.dart';
import '../../data/services/local_sound_overrides.dart';
import '../../widgets/task_card.dart';
import '../../widgets/mode_indicator.dart';

enum _EmailVerificationAction { verified, resend, useLocal, signOut }
enum _IntegrityDecision { proceed, adjustFirst, useDefault, cancel }

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  static const String _linuxSyncNoticeKey = 'linux_sync_notice_seen';
  static const String _webLocalNoticeKey = 'web_local_notice_seen';
  final _timeFormat = DateFormat('HH:mm');
  bool _syncNoticeChecked = false;
  bool _webLocalNoticeChecked = false;
  bool _verificationPromptShown = false;
  DateTime _planningAnchor = DateTime.now();
  String _planningAnchorKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLinuxSyncNotice();
      _maybeShowWebLocalNotice();
    });
  }

  @override
  void dispose() {
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
                  'Linux desktop does not support sign-in yet, so tasks and '
                  'task groups stay on this machine.',
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

  Future<void> _maybeShowWebLocalNotice() async {
    if (_webLocalNoticeChecked) return;
    if (!kIsWeb) return;
    final appMode = ref.read(appModeProvider);
    if (appMode != AppMode.local) return;
    _webLocalNoticeChecked = true;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_webLocalNoticeKey) ?? false;
    if (seen) return;
    if (!mounted) return;
    await _showWebLocalNoticeDialog();
    await prefs.setBool(_webLocalNoticeKey, true);
  }

  Future<void> _showWebLocalNoticeDialog() async {
    final action = await showDialog<_WebLocalNoticeAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Local data is stored in this browser'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Local mode keeps your tasks only in this browser. Clearing '
                  'site data, using incognito, or switching devices will remove '
                  'them.',
                ),
                SizedBox(height: 8),
                Text('Sign in to sync and back up your data.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_WebLocalNoticeAction.stayLocal),
              child: const Text('Stay in local mode'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_WebLocalNoticeAction.signIn),
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (action != _WebLocalNoticeAction.signIn) return;
    final controller = ref.read(appModeProvider.notifier);
    await controller.setAccount();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _showModeSwitchDialog({
    required bool authSupported,
    required bool signedIn,
    required bool requiresVerification,
  }) async {
    if (!authSupported) return;
    final appMode = ref.read(appModeProvider);
    final controller = ref.read(appModeProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    final emailLabel = currentUser?.email?.trim() ?? '';
    final accountLabel = signedIn && emailLabel.isNotEmpty
        ? emailLabel
        : (currentUser?.uid ?? '');
    final result = await showDialog<AppMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose app mode'),
          content: Text(
            signedIn && accountLabel.isNotEmpty
                ? 'Active account: $accountLabel\n\n'
                      'Local Mode is device-only. Account Mode syncs data to the current user.'
                : 'Local Mode is device-only. Account Mode syncs data to the current user.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(AppMode.local),
              child: const Text('Local mode'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(AppMode.account),
              child: const Text('Account mode'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == appMode) return;

    if (result == AppMode.local) {
      await controller.setLocal();
      await _maybeShowWebLocalNotice();
      return;
    }

    if (!signedIn) {
      if (mounted) context.go('/login');
      return;
    }

    if (requiresVerification) {
      await _showEmailVerificationDialog();
      return;
    }

    await controller.setAccount();
  }

  Future<void> _showEmailVerificationDialog() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    if (!auth.requiresEmailVerification) return;

    final action = await showDialog<_EmailVerificationAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify your email to enable sync'),
          content: Text(
            'We need to verify ${auth.currentUser?.email ?? 'this email'} before enabling Account Mode. '
            'Check your spam folder if it does not arrive within a few minutes.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EmailVerificationAction.useLocal),
              child: const Text('Use Local Mode'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EmailVerificationAction.signOut),
              child: const Text('Sign out'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EmailVerificationAction.resend),
              child: const Text('Resend email'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EmailVerificationAction.verified),
              child: const Text("I've verified"),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _EmailVerificationAction.resend:
        await _sendVerificationEmail();
        break;
      case _EmailVerificationAction.verified:
        await auth.reloadCurrentUser();
        ref.invalidate(authStateProvider);
        if (auth.requiresEmailVerification && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email still unverified. Please try again.'),
            ),
          );
        }
        break;
      case _EmailVerificationAction.useLocal:
        await ref.read(appModeProvider.notifier).setLocal();
        await _maybeShowWebLocalNotice();
        _verificationPromptShown = false;
        break;
      case _EmailVerificationAction.signOut:
        await _handleLogout();
        _verificationPromptShown = false;
        break;
    }
  }

  Future<void> _sendVerificationEmail() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      await auth.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification email sent to ${auth.currentUser?.email ?? 'your email'}. '
            'Check your spam folder if it does not arrive soon.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
    }
  }

  Future<void> _handleLogout() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    final controller = ref.read(appModeProvider.notifier);
    await auth.signOut();
    await controller.setLocal();
    await _maybeShowWebLocalNotice();
    ref.invalidate(taskListProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(emailVerificationRequiredProvider, (previous, next) {
      if (!next) {
        _verificationPromptShown = false;
        return;
      }
      final appMode = ref.read(appModeProvider);
      if (appMode != AppMode.account) return;
      if (_verificationPromptShown) return;
      _verificationPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showEmailVerificationDialog();
      });
    });
    final tasksAsync = ref.watch(taskListProvider);
    final auth = ref.watch(firebaseAuthServiceProvider);
    final authSupported = auth is! StubAuthService;
    final appMode = ref.watch(appModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final signedIn = currentUser != null;
    final requiresVerification = ref.watch(emailVerificationRequiredProvider);
    final activeSession = ref.watch(activePomodoroSessionProvider);
    final selectedIds = ref.watch(taskSelectionProvider);
    final selection = ref.read(taskSelectionProvider.notifier);
    final isCompact = MediaQuery.of(context).size.width < 360;
    final screenWidth = MediaQuery.of(context).size.width;
    final emailLabel = currentUser?.email?.trim() ?? '';
    final accountLabel = signedIn && emailLabel.isNotEmpty
        ? emailLabel
        : (currentUser?.uid ?? '');
    final maxEmailWidth = screenWidth < 360
        ? 96.0
        : screenWidth < 480
        ? 140.0
        : screenWidth < 720
        ? 200.0
        : 260.0;
    final showAccountLabel =
        authSupported &&
        appMode == AppMode.account &&
        signedIn &&
        accountLabel.isNotEmpty;
    final showLogout = authSupported && appMode == AppMode.account && signedIn;
    final showLogin = authSupported && appMode == AppMode.account && !signedIn;
    final showInfo = !authSupported;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        toolbarHeight: isCompact ? 108 : 92,
        titleSpacing: 12,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: double.infinity,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => context.push('/settings'),
                      ),
                      if (showAccountLabel)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxEmailWidth,
                          ),
                          child: Text(
                            accountLabel,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      if (showAccountLabel) const SizedBox(width: 8),
                      if (showLogout)
                        IconButton(
                          icon: const Icon(Icons.logout),
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: _handleLogout,
                        ),
                      if (showLogin)
                        IconButton(
                          icon: const Icon(Icons.person),
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => context.go('/login'),
                        ),
                      if (showInfo)
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: _handleSyncInfoTap,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: authSupported
                          ? () => _showModeSwitchDialog(
                              authSupported: authSupported,
                              signedIn: signedIn,
                              requiresVerification: requiresVerification,
                            )
                          : null,
                      child: ModeIndicatorChip(compact: isCompact),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Your tasks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(taskEditorProvider.notifier).createNew();
          if (!context.mounted) return;
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            selection.syncWithIds(tasks.map((t) => t.id));
          });
          if (tasks.isEmpty) {
            if (appMode == AppMode.account &&
                signedIn &&
                requiresVerification) {
              return _buildVerificationLockedState();
            }
            if (appMode == AppMode.account && !signedIn) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sign in to use Account Mode. Your local data remains separate.',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(
              child: Text(
                "Your tasks will appear here",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final planningKey = _buildPlanningAnchorKey(tasks, selectedIds);
          if (planningKey != _planningAnchorKey) {
            _planningAnchorKey = planningKey;
            _planningAnchor = DateTime.now();
          }
          final ranges = _buildSelectedTimeRanges(
            tasks,
            selectedIds,
            _planningAnchor,
          );
          final weightTotal = _weightTotal(tasks, selectedIds);

          final soundOverrides = ref.read(localSoundOverridesProvider);

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
              final isSelected = selectedIds.contains(t.id);
              final weightPercent = (weightTotal == null || !isSelected)
                  ? null
                  : (((t.totalPomodoros * t.pomodoroMinutes) / weightTotal) *
                          100)
                      .round();
              return TaskCard(
                key: ValueKey(t.id),
                task: t,
                soundOverrides: soundOverrides,
                weightPercent: weightPercent,
                selected: isSelected,
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
                  await context.push("/tasks/edit/${t.id}");
                  if (!mounted) return;
                  setState(() {});
                },
                onDelete: () {
                  if (activeSession != null && activeSession.taskId == t.id) {
                    _showSnackBar(
                      context,
                      "This task is running. Stop it before deleting.",
                    );
                    return;
                  }
                  _confirmDeleteTask(context, t).then((shouldDelete) {
                    if (!shouldDelete) return;
                    ref.read(taskListProvider.notifier).deleteTask(t.id);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVerificationLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verify your email to enable Account Mode sync.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showEmailVerificationDialog,
              child: const Text('Verify email'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await ref.read(appModeProvider.notifier).setLocal();
                await _maybeShowWebLocalNotice();
              },
              child: const Text('Switch to Local Mode'),
            ),
          ],
        ),
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

    final appMode = ref.read(appModeProvider);
    final auth = ref.read(firebaseAuthServiceProvider);
    final authSupported = auth is! StubAuthService;
    final requiresVerification = ref.read(emailVerificationRequiredProvider);
    if (appMode == AppMode.account &&
        authSupported &&
        auth.currentUser == null) {
      _showSnackBar(context, "Sign in to create task groups.");
      return;
    }
    if (appMode == AppMode.account &&
        authSupported &&
        auth.currentUser != null &&
        requiresVerification) {
      _showSnackBar(context, "Verify your email to create task groups.");
      await _showEmailVerificationDialog();
      return;
    }

    final planAction = await _showPlanActionDialog(context);
    if (!context.mounted) return;
    if (planAction == null) return;
    final planCapturedAt = DateTime.now();
    DateTime? scheduledStart;
    if (planAction == _PlanAction.schedule) {
      scheduledStart = await _pickScheduleDateTime(
        context,
        initial: planCapturedAt,
      );
      if (!context.mounted) return;
      if (scheduledStart == null) return;
      if (scheduledStart.isBefore(planCapturedAt)) {
        _showSnackBar(context, 'Scheduled time must be in the future.');
        return;
      }
    } else if (activeSession != null) {
      final shouldBlock = await _shouldBlockForActiveSession(activeSession);
      if (!context.mounted) return;
      if (shouldBlock) {
        _showSnackBar(
          context,
          "A session is already active (running or paused). Finish or cancel it first.",
        );
        return;
      }
    }

    final integrityDecision = await _maybeShowIntegrityWarning(
      context,
      selected,
    );
    if (!context.mounted) return;
    if (integrityDecision == _IntegrityDecision.cancel) return;

    var items = await _buildRunItemsWithOverrides(selected);
    if (integrityDecision == _IntegrityDecision.adjustFirst) {
      items = await _applySharedStructure(items, forceDefault: false);
    } else if (integrityDecision == _IntegrityDecision.useDefault) {
      items = await _applySharedStructure(items, forceDefault: true);
    }
    final totalDurationSeconds = groupDurationSecondsWithFinalBreaks(items);
    final conflictStart = scheduledStart ?? planCapturedAt;
    final conflictEnd = conflictStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final repo = ref.read(taskRunGroupRepositoryProvider);
    List<TaskRunGroup> existingGroups = const [];
    try {
      existingGroups = await _loadGroupsForConflict(repo);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to check conflicts: $e");
      return;
    }
    if (!context.mounted) return;
    final conflicts = _findConflicts(
      existingGroups,
      newStart: conflictStart,
      newEnd: conflictEnd,
      includeRunningAlways: planAction == _PlanAction.startNow,
    );

    try {
      if (conflicts.running.isNotEmpty) {
        final resolved = await _resolveRunningConflict(
          context,
          conflicts.running,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }

      if (conflicts.scheduled.isNotEmpty) {
        final resolved = await _resolveScheduledConflict(
          context,
          conflicts.scheduled,
          repo,
        );
        if (!context.mounted) return;
        if (!resolved) return;
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to resolve conflicts: $e");
      return;
    }

    final noticeMinutes = await ref
        .read(taskRunNoticeServiceProvider)
        .getNoticeMinutes();
    if (!context.mounted) return;

    final status = planAction == _PlanAction.startNow
        ? TaskRunStatus.running
        : TaskRunStatus.scheduled;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final scheduledByDeviceId = status == TaskRunStatus.scheduled
        ? deviceId
        : null;

    final recalculatedStart = scheduledStart ?? DateTime.now();
    final recalculatedEnd = recalculatedStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final group = TaskRunGroup(
      id: const Uuid().v4(),
      ownerUid: auth.currentUser?.uid ?? 'local',
      tasks: items,
      createdAt: planCapturedAt,
      scheduledStartTime: scheduledStart,
      scheduledByDeviceId: scheduledByDeviceId,
      actualStartTime: null,
      theoreticalEndTime: recalculatedEnd,
      status: status,
      noticeMinutes: noticeMinutes,
      totalTasks: items.length,
      totalPomodoros: items.fold<int>(
        0,
        (total, item) => total + item.totalPomodoros,
      ),
      totalDurationSeconds: totalDurationSeconds,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(taskRunGroupRepositoryProvider).save(group);
      if (!context.mounted) return;
      selection.clear();
      final message = status == TaskRunStatus.running
          ? "Task group started."
          : "Task group scheduled.";
      _showSnackBar(context, message);
      if (status == TaskRunStatus.scheduled) {
        await _schedulePreAlertIfNeeded(group);
      }
      if (!context.mounted) return;
      if (status == TaskRunStatus.running) {
        context.go("/timer/${group.id}");
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, "Failed to create task group: $e");
    }
  }

  Future<void> _schedulePreAlertIfNeeded(TaskRunGroup group) async {
    final scheduledStart = group.scheduledStartTime;
    if (scheduledStart == null) return;
    final scheduledBy = group.scheduledByDeviceId;
    if (scheduledBy != null) {
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      if (scheduledBy != deviceId) return;
    }
    final noticeMinutes = group.noticeMinutes ?? 0;
    if (noticeMinutes <= 0) return;
    final preAlertStart =
        scheduledStart.subtract(Duration(minutes: noticeMinutes));
    final now = DateTime.now();
    if (!preAlertStart.isAfter(now)) return;
    final name = group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    await ref.read(notificationServiceProvider).scheduleGroupPreAlert(
          groupId: group.id,
          groupName: name,
          scheduledFor: preAlertStart,
          remainingSeconds: noticeMinutes * 60,
        );
  }

  Future<_PlanAction?> _showPlanActionDialog(BuildContext context) {
    return showDialog<_PlanAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan start'),
        content: const Text(
          'Choose whether to start now or schedule the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_PlanAction.schedule),
            child: const Text('Schedule start'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_PlanAction.startNow),
            child: const Text('Start now'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickScheduleDateTime(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return null;
    if (!context.mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  _GroupConflicts _findConflicts(
    List<TaskRunGroup> groups, {
    required DateTime newStart,
    required DateTime newEnd,
    required bool includeRunningAlways,
  }) {
    final running = <TaskRunGroup>[];
    final scheduled = <TaskRunGroup>[];

    for (final group in groups) {
      if (group.status == TaskRunStatus.canceled ||
          group.status == TaskRunStatus.completed) {
        continue;
      }
      if (group.status == TaskRunStatus.running && includeRunningAlways) {
        running.add(group);
        continue;
      }
      final start =
          group.actualStartTime ?? group.scheduledStartTime ?? group.createdAt;
      final end = group.theoreticalEndTime.isBefore(start)
          ? start
          : group.theoreticalEndTime;
      if (!_overlaps(newStart, newEnd, start, end)) continue;
      if (group.status == TaskRunStatus.running) {
        running.add(group);
        continue;
      }
      if (group.status == TaskRunStatus.scheduled) {
        scheduled.add(group);
      }
    }

    return _GroupConflicts(running: running, scheduled: scheduled);
  }

  bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final safeAEnd = aEnd.isBefore(aStart) ? aStart : aEnd;
    final safeBEnd = bEnd.isBefore(bStart) ? bStart : bEnd;
    return aStart.isBefore(safeBEnd) && safeAEnd.isAfter(bStart);
  }

  Future<bool> _resolveRunningConflict(
    BuildContext context,
    List<TaskRunGroup> runningGroups,
    TaskRunGroupRepository repo,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict with running group'),
        content: const Text(
          'A group is already running. Cancel it to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel running group'),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return false;
    final now = DateTime.now();
    for (final group in runningGroups) {
      await repo.save(
        group.copyWith(status: TaskRunStatus.canceled, updatedAt: now),
      );
    }
    return true;
  }

  Future<bool> _resolveScheduledConflict(
    BuildContext context,
    List<TaskRunGroup> scheduledGroups,
    TaskRunGroupRepository repo,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict with scheduled group'),
        content: const Text(
          'A group is already scheduled in that time range. Delete it to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete scheduled group'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return false;
    for (final group in scheduledGroups) {
      await repo.delete(group.id);
    }
    return true;
  }

  Future<List<TaskRunGroup>> _loadGroupsForConflict(
    TaskRunGroupRepository repo,
  ) async {
    try {
      return await repo.getAll();
    } on StateError {
      return [];
    }
  }

  Future<bool> _confirmDeleteTask(
    BuildContext context,
    PomodoroTask task,
  ) async {
    final title = task.name.isEmpty ? '(Untitled)' : task.name;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return shouldDelete ?? false;
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildPlanningAnchorKey(
    List<PomodoroTask> tasks,
    Set<String> selectedIds,
  ) {
    final buffer = StringBuffer();
    for (final task in tasks) {
      if (!selectedIds.contains(task.id)) continue;
      buffer.write(task.id);
      buffer.write('|');
    }
    return buffer.toString();
  }

  Map<String, String> _buildSelectedTimeRanges(
    List<PomodoroTask> tasks,
    Set<String> selectedIds,
    DateTime start,
  ) {
    final ranges = <String, String>{};
    final selectedTasks = tasks
        .where((task) => selectedIds.contains(task.id))
        .toList();
    var cursor = start;
    for (var index = 0; index < selectedTasks.length; index += 1) {
      final task = selectedTasks[index];
      final includeFinalBreak = index < selectedTasks.length - 1;
      final duration = _taskDurationSeconds(
        task,
        includeFinalBreak: includeFinalBreak,
      );
      final end = cursor.add(Duration(seconds: duration));
      ranges[task.id] =
          "${_timeFormat.format(cursor)}–${_timeFormat.format(end)}";
      cursor = end;
    }
    return ranges;
  }

  int? _weightTotal(List<PomodoroTask> tasks, Set<String> selectedIds) {
    if (tasks.isEmpty || selectedIds.isEmpty) return null;
    final scoped = tasks.where((task) => selectedIds.contains(task.id));
    var total = 0;
    for (final task in scoped) {
      total += task.totalPomodoros * task.pomodoroMinutes;
    }
    return total <= 0 ? null : total;
  }

  Future<_IntegrityDecision> _maybeShowIntegrityWarning(
    BuildContext context,
    List<PomodoroTask> selected,
  ) async {
    if (selected.length <= 1) return _IntegrityDecision.proceed;
    final base = selected.first;
    final mismatched = selected
        .where((task) => !_matchesStructure(task, base))
        .toList();
    if (mismatched.isEmpty) return _IntegrityDecision.proceed;

    final defaultPreset = await _loadDefaultPreset();
    if (!context.mounted) return _IntegrityDecision.cancel;
    final hasDefaultPreset = defaultPreset != null;
    final rootContext = context;

    final result = await showDialog<_IntegrityDecision>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.orangeAccent, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pomodoro integrity warning',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'This group mixes Pomodoro structures. Mixed durations can '
                  'reduce the benefits of the technique.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tasks with different structure:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                for (final task in mismatched)
                  Text(
                    '• ${task.name.isEmpty ? '(Untitled)' : task.name}',
                    style: const TextStyle(color: Colors.white60),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_IntegrityDecision.adjustFirst),
              child: const Text('Ajustar a la primera'),
            ),
            if (hasDefaultPreset)
              TextButton(
                onPressed: () async {
                  final preset = await _loadDefaultPreset();
                  if (preset == null) {
                    if (!rootContext.mounted) return;
                    _showSnackBar(
                      rootContext,
                      "No default preset found. Please set a default in Settings to use this action.",
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop(_IntegrityDecision.useDefault);
                },
                child: const Text('Usar Predeterminado'),
              ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_IntegrityDecision.proceed),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    return result ?? _IntegrityDecision.cancel;
  }

  bool _matchesStructure(PomodoroTask a, PomodoroTask b) {
    return a.pomodoroMinutes == b.pomodoroMinutes &&
        a.shortBreakMinutes == b.shortBreakMinutes &&
        a.longBreakMinutes == b.longBreakMinutes &&
        a.longBreakInterval == b.longBreakInterval;
  }

  Future<List<TaskRunItem>> _applySharedStructure(
    List<TaskRunItem> items, {
    required bool forceDefault,
  }) async {
    if (items.isEmpty) return items;
    final master = items.first;
    final shouldUseDefault = forceDefault || !_hasClearStructure(master);
    if (shouldUseDefault) {
      final fallbackPreset = await _loadDefaultPreset();
      if (fallbackPreset != null) {
        return await _applyDefaultPreset(items, fallbackPreset);
      }
    }
    return items
        .map(
          (item) => TaskRunItem(
            sourceTaskId: item.sourceTaskId,
            name: item.name,
            presetId: master.presetId,
            pomodoroMinutes: master.pomodoroMinutes,
            shortBreakMinutes: master.shortBreakMinutes,
            longBreakMinutes: master.longBreakMinutes,
            totalPomodoros: item.totalPomodoros,
            longBreakInterval: master.longBreakInterval,
            startSound: master.startSound,
            startBreakSound: master.startBreakSound,
            finishTaskSound: master.finishTaskSound,
          ),
        )
        .toList();
  }

  bool _hasClearStructure(TaskRunItem item) {
    return item.pomodoroMinutes > 0 &&
        item.shortBreakMinutes > 0 &&
        item.longBreakMinutes > 0 &&
        item.longBreakInterval > 0;
  }

  Future<PomodoroPreset?> _loadDefaultPreset() async {
    final cached = ref.read(presetListProvider).value;
    if (cached != null) {
      for (final preset in cached) {
        if (preset.isDefault) return preset;
      }
    }
    final repo = ref.read(presetRepositoryProvider);
    final all = await repo.getAll();
    for (final preset in all) {
      if (preset.isDefault) return preset;
    }
    return null;
  }

  Future<List<TaskRunItem>> _applyDefaultPreset(
    List<TaskRunItem> items,
    PomodoroPreset preset,
  ) async {
    final overrides = ref.read(localSoundOverridesProvider);
    final presetKey = 'preset:${preset.id}';
    final startOverride = await overrides.getOverride(
      presetKey,
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await overrides.getOverride(
      presetKey,
      SoundSlot.breakStart,
    );
    final startSound = startOverride?.sound ?? preset.startSound;
    final breakSound = breakOverride?.sound ?? preset.startBreakSound;

    return items
        .map(
          (item) => TaskRunItem(
            sourceTaskId: item.sourceTaskId,
            name: item.name,
            presetId: preset.id,
            pomodoroMinutes: preset.pomodoroMinutes,
            shortBreakMinutes: preset.shortBreakMinutes,
            longBreakMinutes: preset.longBreakMinutes,
            totalPomodoros: item.totalPomodoros,
            longBreakInterval: preset.longBreakInterval,
            startSound: startSound,
            startBreakSound: breakSound,
            finishTaskSound: preset.finishTaskSound,
          ),
        )
        .toList();
  }

  Future<bool> _shouldBlockForActiveSession(
    PomodoroSession activeSession,
  ) async {
    final sessionRepo = ref.read(pomodoroSessionRepositoryProvider);
    final groupId = activeSession.groupId;
    if (groupId == null || groupId.isEmpty) {
      await sessionRepo.clearSession();
      return false;
    }

    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final group = await groupRepo.getById(groupId);
    if (group == null || group.status != TaskRunStatus.running) {
      await sessionRepo.clearSession();
      return false;
    }
    return true;
  }

  int _taskDurationSeconds(
    PomodoroTask task, {
    required bool includeFinalBreak,
  }) {
    final pomodoroSeconds = task.pomodoroMinutes * 60;
    final shortBreakSeconds = task.shortBreakMinutes * 60;
    final longBreakSeconds = task.longBreakMinutes * 60;
    var total = task.totalPomodoros * pomodoroSeconds;
    if (task.totalPomodoros > 1) {
      for (var index = 1; index < task.totalPomodoros; index += 1) {
        final isLongBreak = index % task.longBreakInterval == 0;
        total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
      }
    }
    if (!includeFinalBreak) return total;
    final isLongBreak = task.totalPomodoros % task.longBreakInterval == 0;
    total += isLongBreak ? longBreakSeconds : shortBreakSeconds;
    return total;
  }

  Future<List<TaskRunItem>> _buildRunItemsWithOverrides(
    List<PomodoroTask> tasks,
  ) async {
    final overrides = ref.read(localSoundOverridesProvider);
    final items = <TaskRunItem>[];
    for (final task in tasks) {
      var startSound = task.startSound;
      var breakSound = task.startBreakSound;
      final startOverride = await overrides.getOverride(
        task.id,
        SoundSlot.pomodoroStart,
      );
      final breakOverride = await overrides.getOverride(
        task.id,
        SoundSlot.breakStart,
      );
      if (startOverride != null) {
        startSound = startOverride.sound;
      }
      if (breakOverride != null) {
        breakSound = breakOverride.sound;
      }
      items.add(
        _mapTaskToRunItem(
          task,
          startSound: startSound,
          startBreakSound: breakSound,
        ),
      );
    }
    return items;
  }

  TaskRunItem _mapTaskToRunItem(
    PomodoroTask task, {
    SelectedSound? startSound,
    SelectedSound? startBreakSound,
  }) {
    return TaskRunItem(
      sourceTaskId: task.id,
      name: task.name,
      presetId: task.presetId,
      pomodoroMinutes: task.pomodoroMinutes,
      shortBreakMinutes: task.shortBreakMinutes,
      longBreakMinutes: task.longBreakMinutes,
      totalPomodoros: task.totalPomodoros,
      longBreakInterval: task.longBreakInterval,
      startSound: startSound ?? task.startSound,
      startBreakSound: startBreakSound ?? task.startBreakSound,
      finishTaskSound: task.finishTaskSound,
    );
  }
}

enum _WebLocalNoticeAction { stayLocal, signIn }

enum _PlanAction { startNow, schedule }

class _GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;

  const _GroupConflicts({required this.running, required this.scheduled});
}

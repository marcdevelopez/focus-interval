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
import '../../data/models/schema_version.dart';
import '../../data/repositories/task_run_group_repository.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/app_mode_service.dart';
import '../../data/services/local_sound_overrides.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../domain/pomodoro_machine.dart';
import '../../domain/validators.dart';
import '../../widgets/task_card.dart';
import '../../widgets/mode_indicator.dart';
import 'task_group_planning_screen.dart';

enum _EmailVerificationAction { verified, resend, useLocal, signOut }
enum _IntegritySelectionType { keepIndividual, useDefault, useStructure, cancel }

class _IntegritySelection {
  final _IntegritySelectionType type;
  final String? masterTaskId;

  const _IntegritySelection._(
    this.type, {
    this.masterTaskId,
  });

  const _IntegritySelection.keepIndividual()
      : this._(_IntegritySelectionType.keepIndividual);

  const _IntegritySelection.useDefault()
      : this._(_IntegritySelectionType.useDefault);

  const _IntegritySelection.cancel() : this._(_IntegritySelectionType.cancel);

  const _IntegritySelection.useStructure(String taskId)
      : this._(
          _IntegritySelectionType.useStructure,
          masterTaskId: taskId,
        );
}

class _StructureKey {
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;

  const _StructureKey({
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakInterval,
  });

  factory _StructureKey.fromTask(PomodoroTask task) {
    return _StructureKey(
      pomodoroMinutes: task.pomodoroMinutes,
      shortBreakMinutes: task.shortBreakMinutes,
      longBreakMinutes: task.longBreakMinutes,
      longBreakInterval: task.longBreakInterval,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StructureKey &&
        other.pomodoroMinutes == pomodoroMinutes &&
        other.shortBreakMinutes == shortBreakMinutes &&
        other.longBreakMinutes == longBreakMinutes &&
        other.longBreakInterval == longBreakInterval;
  }

  @override
  int get hashCode => Object.hash(
        pomodoroMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        longBreakInterval,
      );
}

class _StructureOption {
  final _StructureKey key;
  final PomodoroTask masterTask;
  final List<PomodoroTask> tasks;

  _StructureOption({
    required this.key,
    required this.masterTask,
  }) : tasks = [masterTask];

  void addTask(PomodoroTask task) {
    tasks.add(task);
  }
}

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  static const String _linuxSyncNoticeKey = 'linux_sync_notice_seen';
  static const String _webLocalNoticeKey = 'web_local_notice_seen';
  static const double _autoScrollEdgeThreshold = 56;
  static const double _autoScrollStep = 12;
  final _timeFormat = DateFormat('HH:mm');
  final GlobalKey _taskListViewportKey = GlobalKey();
  final ScrollController _taskListScrollController = ScrollController();
  bool _syncNoticeChecked = false;
  bool _webLocalNoticeChecked = false;
  bool _verificationPromptShown = false;
  bool _isReordering = false;
  DateTime _planningAnchor = DateTime.now();
  String _planningAnchorKey = '';
  String? _activeBannerGroupId;
  bool _staleActiveHandled = false;

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
    _taskListScrollController.dispose();
    super.dispose();
  }

  void _handleReorderAutoScroll(PointerMoveEvent event) {
    if (!_isReordering) return;
    if (!_taskListScrollController.hasClients) return;
    final viewportContext = _taskListViewportKey.currentContext;
    final size = viewportContext?.size;
    if (size == null) return;
    final dy = event.localPosition.dy;
    final maxScroll = _taskListScrollController.position.maxScrollExtent;
    final current = _taskListScrollController.offset;
    double delta = 0;
    if (dy < _autoScrollEdgeThreshold) {
      delta = -_autoScrollStep;
    } else if (dy > size.height - _autoScrollEdgeThreshold) {
      delta = _autoScrollStep;
    }
    if (delta == 0) return;
    final target = (current + delta).clamp(0.0, maxScroll);
    if (target == current) return;
    _taskListScrollController.jumpTo(target);
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
    ref.invalidate(presetListProvider);
    ref.invalidate(presetEditorProvider);
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
    final groupsAsync = ref.watch(taskRunGroupStreamProvider);
    final selectedIds = ref.watch(taskSelectionProvider);
    final selectedWeightPercents =
        ref.watch(selectedTaskWeightPercentsProvider);
    final selection = ref.read(taskSelectionProvider.notifier);
    final isCompact = MediaQuery.of(context).size.width < 360;
    final screenWidth = MediaQuery.of(context).size.width;
    final emailLabel = currentUser?.email?.trim() ?? '';
    final accountLabel = signedIn && emailLabel.isNotEmpty
        ? emailLabel
        : (currentUser?.uid ?? '');
    final showAccountLabel =
        authSupported &&
        appMode == AppMode.account &&
        signedIn &&
        accountLabel.isNotEmpty;
    final showLogout = authSupported && appMode == AppMode.account && signedIn;
    final showLogin = authSupported && appMode == AppMode.account && !signedIn;
    final showInfo = !authSupported;
    final baseMaxEmailWidth = screenWidth < 360
        ? 96.0
        : screenWidth < 480
        ? 140.0
        : screenWidth < 720
        ? 200.0
        : 260.0;
    const titleMinWidth = 120.0;
    const titlePadding = 24.0;
    const actionIconWidth = 36.0;
    const actionRightPadding = 8.0;
    final actionIconCount =
        1 +
        (showLogout ? 1 : 0) +
        (showLogin ? 1 : 0) +
        (showInfo ? 1 : 0);
    final actionReservedWidth =
        (actionIconCount * actionIconWidth) +
        actionRightPadding +
        (showAccountLabel ? 8.0 : 0.0);
    final maxActionsWidth = screenWidth - titleMinWidth - titlePadding;
    final maxEmailWidth = (maxActionsWidth - actionReservedWidth)
        .clamp(0.0, baseMaxEmailWidth)
        .toDouble();
    final activeGroupId = activeSession?.groupId;
    if (activeGroupId != _activeBannerGroupId) {
      _activeBannerGroupId = activeGroupId;
      _staleActiveHandled = false;
    }
    _maybeResolveStaleActiveSession(
      context,
      activeSession: activeSession,
      groupsAsync: groupsAsync,
    );
    final activeGroupBanner = _buildActiveGroupBanner(
      context,
      activeSession: activeSession,
      groupsAsync: groupsAsync,
    );
    final preRunBanner = activeGroupBanner == null
        ? _buildPreRunBanner(
            context,
            groupsAsync: groupsAsync,
          )
        : null;
    final showGroupsHubCta =
        activeGroupBanner == null && preRunBanner == null;

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
            child: const Text('Next'),
          ),
        ),
      ),
      body: Column(
        children: [
          if (activeGroupBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: activeGroupBanner,
            ),
          if (activeGroupBanner == null && preRunBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: preRunBanner,
            ),
          if (showGroupsHubCta)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/groups'),
                  icon: const Icon(Icons.view_list, size: 18),
                  label: const Text('View Groups Hub'),
                ),
              ),
            ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: Colors.red),
                ),
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

                final soundOverrides = ref.read(localSoundOverridesProvider);

                return Listener(
                  key: _taskListViewportKey,
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: _handleReorderAutoScroll,
                  child: DragBoundary(
                    child: ReorderableListView.builder(
                      scrollController: _taskListScrollController,
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.all(12),
                      itemCount: tasks.length,
                      onReorderStart: (_) => setState(() {
                        _isReordering = true;
                      }),
                      onReorderEnd: (_) => setState(() {
                        _isReordering = false;
                      }),
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(taskListProvider.notifier)
                            .reorderTasks(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final t = tasks[i];
                        final isSelected = selectedIds.contains(t.id);
                        final weightPercent = isSelected
                            ? selectedWeightPercents[t.id]
                            : null;
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
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          onEdit: () async {
                            if (activeSession != null &&
                                activeSession.taskId == t.id) {
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
                            if (result ==
                                TaskEditorLoadResult.blockedByActiveSession) {
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
                            if (activeSession != null &&
                                activeSession.taskId == t.id) {
                              _showSnackBar(
                                context,
                                "This task is running. Stop it before deleting.",
                              );
                              return;
                            }
                            _confirmDeleteTask(context, t)
                                .then((shouldDelete) {
                              if (!shouldDelete) return;
                              ref
                                  .read(taskListProvider.notifier)
                                  .deleteTask(t.id);
                            });
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActiveGroupBanner(
    BuildContext context, {
    required PomodoroSession? activeSession,
    required AsyncValue<List<TaskRunGroup>> groupsAsync,
  }) {
    final groups = groupsAsync.value ?? const [];
    TaskRunGroup? group;
    if (activeSession != null) {
      final groupId = activeSession.groupId;
      if (groupId == null || groupId.isEmpty) return null;
      for (final candidate in groups) {
        if (candidate.id == groupId) {
          group = candidate;
          break;
        }
      }
      if (group != null && group.status != TaskRunStatus.running) {
        return null;
      }
    } else {
      final runningGroups =
          groups.where((g) => g.status == TaskRunStatus.running).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (runningGroups.isEmpty) return null;
      group = runningGroups.first;
    }
    if (group == null) return null;
    final groupId = group.id;
    final name =
        group.tasks.isNotEmpty ? group.tasks.first.name : 'Task group';
    final statusLabel =
        activeSession?.status == PomodoroStatus.paused ? 'Paused' : 'Running';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group $statusLabel',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/timer/$groupId'),
                child: const Text('Open Run Mode'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/groups'),
                child: const Text('View in Groups Hub'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildPreRunBanner(
    BuildContext context, {
    required AsyncValue<List<TaskRunGroup>> groupsAsync,
  }) {
    final groups = groupsAsync.value ?? const [];
    if (groups.isEmpty) return null;
    final now = DateTime.now();
    TaskRunGroup? selected;
    DateTime? startTime;
    for (final group in groups) {
      if (group.status != TaskRunStatus.scheduled) continue;
      final scheduledStart = group.scheduledStartTime;
      if (scheduledStart == null) continue;
      final noticeMinutes =
          group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
      if (noticeMinutes <= 0) continue;
      final preRunStart = scheduledStart.subtract(
        Duration(minutes: noticeMinutes),
      );
      if (now.isBefore(preRunStart) || !now.isBefore(scheduledStart)) {
        continue;
      }
      if (startTime == null || scheduledStart.isBefore(startTime)) {
        startTime = scheduledStart;
        selected = group;
      }
    }
    if (selected == null || startTime == null) return null;

    final groupId = selected.id;
    final remainingSeconds = startTime.difference(now).inSeconds;
    final countdown = _formatCountdown(remainingSeconds);
    final name = selected.tasks.isNotEmpty
        ? selected.tasks.first.name
        : 'Task group';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.amber.shade300.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-Run active · Starts in $countdown',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => context.go('/timer/$groupId'),
                child: const Text('Open Pre-Run'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/groups'),
                child: const Text('View in Groups Hub'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _maybeResolveStaleActiveSession(
    BuildContext context, {
    required PomodoroSession? activeSession,
    required AsyncValue<List<TaskRunGroup>> groupsAsync,
  }) {
    if (_staleActiveHandled) return;
    final groupId = activeSession?.groupId;
    if (groupId == null || groupId.isEmpty) return;
    final groups = groupsAsync.value;
    if (groups == null) return;
    TaskRunGroup? group;
    for (final candidate in groups) {
      if (candidate.id == groupId) {
        group = candidate;
        break;
      }
    }
    if (group == null) return;
    if (group.status == TaskRunStatus.running) return;

    _staleActiveHandled = true;
    final groupStatus = group.status;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await ref
          .read(pomodoroSessionRepositoryProvider)
          .clearSessionIfGroupNotRunning();
      if (!context.mounted) return;
      final message = groupStatus == TaskRunStatus.completed
          ? 'Group completed.'
          : 'Group ended.';
      _showSnackBar(context, message);
    });
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

    final integritySelection = await _maybeShowIntegrityWarning(
      context,
      selected,
    );
    if (!context.mounted) return;
    if (integritySelection.type == _IntegritySelectionType.cancel) return;

    final hasMixedStructure = _hasMixedStructure(selected);
    var items = await _buildRunItemsWithOverrides(selected);
    if (hasMixedStructure) {
      if (integritySelection.type == _IntegritySelectionType.useStructure) {
        final masterId = integritySelection.masterTaskId;
        final master = masterId == null
            ? items.first
            : items.firstWhere(
                (item) => item.sourceTaskId == masterId,
                orElse: () => items.first,
              );
        items = await _applySharedStructure(
          items,
          forceDefault: false,
          master: master,
        );
      } else if (integritySelection.type ==
          _IntegritySelectionType.useDefault) {
        items = await _applySharedStructure(
          items,
          forceDefault: true,
        );
      }
    }
    final integrityMode = hasMixedStructure
        ? (integritySelection.type == _IntegritySelectionType.keepIndividual
            ? TaskRunIntegrityMode.individual
            : TaskRunIntegrityMode.shared)
        : TaskRunIntegrityMode.shared;
    if (!context.mounted) return;

    final planningResult = await _showPlanningScreen(
      context,
      items: items,
      integrityMode: integrityMode,
    );
    if (!context.mounted) return;
    if (planningResult == null) return;

    items = planningResult.items;
    final planOption = planningResult.option;
    final isStartNow = planOption == TaskGroupPlanOption.startNow;
    final isSchedule = !isStartNow;

    final planCapturedAt = DateTime.now();
    DateTime? scheduledStart;
    if (isSchedule) {
      scheduledStart = planningResult.scheduledStart;
      if (scheduledStart == null) {
        _showSnackBar(context, 'Select a start time for scheduling.');
        return;
      }
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
    final totalDurationSeconds = groupDurationSecondsByMode(
      items,
      integrityMode,
    );
    final noticeMinutes = await ref
        .read(taskRunNoticeServiceProvider)
        .getNoticeMinutes();
    if (!context.mounted) return;
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
    if (isSchedule &&
        scheduledStart != null &&
        noticeMinutes > 0) {
      final preRunStart = scheduledStart.subtract(
        Duration(minutes: noticeMinutes),
      );
      final now = DateTime.now();
      if (preRunStart.isBefore(now)) {
        _showSnackBar(
          context,
          "That start time is too soon to show the full pre-run countdown. "
          "Choose a later start or reduce the pre-run notice.",
        );
        return;
      }
      final preRunConflict = _findPreRunConflict(
        existingGroups,
        preRunStart: preRunStart,
        scheduledStart: scheduledStart,
      );
      if (preRunConflict != null) {
        final message = preRunConflict == _PreRunConflictType.running
            ? "That time doesn't leave enough pre-run space because another "
                'group is still running. Choose a later start or reduce the '
                'pre-run notice.'
            : "That time doesn't leave enough pre-run space because another "
                'group is scheduled earlier. Choose a later start or reduce '
                'the pre-run notice.';
        _showSnackBar(context, message);
        return;
      }
    }
    final conflicts = _findConflicts(
      existingGroups,
      newStart: conflictStart,
      newEnd: conflictEnd,
      includeRunningAlways: isStartNow,
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

    final status = isStartNow ? TaskRunStatus.running : TaskRunStatus.scheduled;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final scheduledByDeviceId = deviceId;

    final recalculatedStart = scheduledStart ?? DateTime.now();
    final recalculatedEnd = recalculatedStart.add(
      Duration(seconds: totalDurationSeconds),
    );

    final group = TaskRunGroup(
      id: const Uuid().v4(),
      ownerUid: auth.currentUser?.uid ?? 'local',
      dataVersion: kCurrentDataVersion,
      integrityMode: integrityMode,
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

  Future<TaskGroupPlanningResult?> _showPlanningScreen(
    BuildContext context, {
    required List<TaskRunItem> items,
    required TaskRunIntegrityMode integrityMode,
  }) {
    return context.push<TaskGroupPlanningResult>(
      '/tasks/plan',
      extra: TaskGroupPlanningArgs(
        items: items,
        integrityMode: integrityMode,
        planningAnchor: _planningAnchor,
      ),
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

  _PreRunConflictType? _findPreRunConflict(
    List<TaskRunGroup> groups, {
    required DateTime preRunStart,
    required DateTime scheduledStart,
  }) {
    for (final group in groups) {
      if (group.status == TaskRunStatus.canceled ||
          group.status == TaskRunStatus.completed) {
        continue;
      }
      final start =
          group.actualStartTime ?? group.scheduledStartTime ?? group.createdAt;
      final end = group.theoreticalEndTime.isBefore(start)
          ? start
          : group.theoreticalEndTime;
      if (!_overlaps(preRunStart, scheduledStart, start, end)) continue;
      if (group.status == TaskRunStatus.running) {
        return _PreRunConflictType.running;
      }
      if (group.status == TaskRunStatus.scheduled) {
        return _PreRunConflictType.scheduled;
      }
    }
    return null;
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

  String _formatCountdown(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
    final integrityMode = _hasMixedStructure(selectedTasks)
        ? TaskRunIntegrityMode.individual
        : TaskRunIntegrityMode.shared;
    final durations = _previewTaskDurations(
      selectedTasks,
      integrityMode,
    );
    var cursor = start;
    for (var index = 0; index < selectedTasks.length; index += 1) {
      final task = selectedTasks[index];
      final duration = durations[index];
      final end = cursor.add(Duration(seconds: duration));
      ranges[task.id] =
          "${_timeFormat.format(cursor)}–${_timeFormat.format(end)}";
      cursor = end;
    }
    return ranges;
  }

  Future<_IntegritySelection> _maybeShowIntegrityWarning(
    BuildContext context,
    List<PomodoroTask> selected,
  ) async {
    if (selected.length <= 1) {
      return const _IntegritySelection.keepIndividual();
    }
    final base = selected.first;
    final mismatched = selected
        .where((task) => !_matchesStructure(task, base))
        .toList();
    if (mismatched.isEmpty) {
      return const _IntegritySelection.keepIndividual();
    }

    final defaultPreset = await _loadDefaultPreset();
    if (!context.mounted) return const _IntegritySelection.cancel();
    final hasDefaultPreset = defaultPreset != null;
    final rootContext = context;
    final structureOptions = _buildStructureOptions(selected);

    final result = await showDialog<_IntegritySelection>(
      context: context,
      builder: (context) {
        final optionWidgets = <Widget>[];
        for (final option in structureOptions) {
          if (optionWidgets.isNotEmpty) {
            optionWidgets.add(const SizedBox(height: 12));
          }
          optionWidgets.add(
            _integrityOptionCard(
              onTap: () => Navigator.of(context).pop(
                _IntegritySelection.useStructure(option.masterTask.id),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _structurePreviewRow(
                    pomodoroMinutes: option.key.pomodoroMinutes,
                    shortBreakMinutes: option.key.shortBreakMinutes,
                    longBreakMinutes: option.key.longBreakMinutes,
                    longBreakInterval: option.key.longBreakInterval,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Used by:',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _taskNameChips(option.tasks),
                ],
              ),
            ),
          );
        }
        if (hasDefaultPreset) {
          if (optionWidgets.isNotEmpty) {
            optionWidgets.add(const SizedBox(height: 12));
          }
          optionWidgets.add(
            _integrityOptionCard(
              onTap: () async {
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
                Navigator.of(context).pop(
                  const _IntegritySelection.useDefault(),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _structurePreviewRow(
                    pomodoroMinutes: defaultPreset.pomodoroMinutes,
                    shortBreakMinutes: defaultPreset.shortBreakMinutes,
                    longBreakMinutes: defaultPreset.longBreakMinutes,
                    longBreakInterval: defaultPreset.longBreakInterval,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Default preset',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        if (optionWidgets.isNotEmpty) {
          optionWidgets.add(const SizedBox(height: 12));
        }
        optionWidgets.add(
          _integrityOptionCard(
            onTap: () => Navigator.of(context).pop(
              const _IntegritySelection.keepIndividual(),
            ),
            child: const Text(
              'Keep individual configurations',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth =
            (screenWidth * 0.86).clamp(280.0, 360.0).toDouble();
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
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This group mixes Pomodoro structures. Mixed durations can '
                    'reduce the benefits of the technique. Choose the '
                    'configuration to apply to this group.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ...optionWidgets,
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? const _IntegritySelection.cancel();
  }

  List<_StructureOption> _buildStructureOptions(
    List<PomodoroTask> selected,
  ) {
    final options = <_StructureKey, _StructureOption>{};
    for (final task in selected) {
      final key = _StructureKey.fromTask(task);
      final existing = options[key];
      if (existing == null) {
        options[key] = _StructureOption(
          key: key,
          masterTask: task,
        );
      } else {
        existing.addTask(task);
      }
    }
    return options.values.toList();
  }

  Widget _integrityOptionCard({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _structurePreviewRow({
    required int pomodoroMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int longBreakInterval,
  }) {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            child: Center(
              child: _miniMetricCircle(
                value: '$pomodoroMinutes',
                size: 26,
                stroke: 2,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStatCard(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniMetricCircle(
                    value: '$shortBreakMinutes',
                    size: 24,
                    stroke: 1,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  _miniMetricCircle(
                    value: '$longBreakMinutes',
                    size: 24,
                    stroke: 3,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStatCard(
            child: _miniBreakDots(longBreakInterval),
          ),
        ),
      ],
    );
  }

  Widget _taskNameChips(List<PomodoroTask> tasks) {
    final names = tasks
        .map((task) => task.name.isEmpty ? '(Untitled)' : task.name)
        .toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in names)
          Chip(
            label: Text(name),
            labelStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.white10,
            side: const BorderSide(color: Colors.white24, width: 1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          ),
      ],
    );
  }

  Widget _miniMetricCircle({
    required String value,
    required double size,
    required double stroke,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStatCard({required Widget child}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }

  Widget _miniBreakDots(int interval) {
    final safeInterval = interval <= 0 ? 1 : interval;
    final redDots = safeInterval > maxLongBreakInterval
        ? maxLongBreakInterval
        : safeInterval;
    final totalDots = redDots + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 90.0;
        const maxHeight = 24.0;
        var dotSize = 5.0;
        var spacing = 3.0;
        const minDot = 3.0;

        while (dotSize >= minDot) {
          final rows = _miniRowsFor(
            maxHeight,
            dotSize,
            spacing,
            totalDots,
            maxRows: 3,
          );
          final maxCols = _miniMaxColsFor(maxWidth, dotSize, spacing);
          if (rows * maxCols >= totalDots) break;
          dotSize -= 0.5;
          spacing = dotSize <= 4 ? 2 : 3;
        }

        if (redDots == 1) {
          return SizedBox(
            height: maxHeight,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniDot(color: Colors.redAccent, size: dotSize),
                  SizedBox(width: spacing),
                  _MiniDot(color: Colors.blueAccent, size: dotSize),
                ],
              ),
            ),
          );
        }

        final rows = _miniRowsFor(
          maxHeight,
          dotSize,
          spacing,
          totalDots,
          maxRows: 3,
        );
        final maxCols = _miniMaxColsFor(maxWidth, dotSize, spacing);
        final redColsNeeded = (redDots / rows).ceil();
        final blueSeparate = redColsNeeded < maxCols;
        final columns = <Widget>[];
        var remainingRed = redDots;
        final redColumnsCount = blueSeparate ? redColsNeeded : maxCols;

        for (var col = 0; col < redColumnsCount; col += 1) {
          final isLast = col == redColumnsCount - 1;
          final capacity = (!blueSeparate && isLast) ? rows - 1 : rows;
          final take = remainingRed > capacity ? capacity : remainingRed;
          remainingRed -= take;
          columns.add(
            _miniDotColumn(
              redCount: take,
              includeBlue: !blueSeparate && isLast,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        if (blueSeparate) {
          columns.add(
            _miniDotColumn(
              redCount: 0,
              includeBlue: true,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        return SizedBox(
          height: maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _miniWithColumnSpacing(columns, spacing + 2),
          ),
        );
      },
    );
  }

  int _miniRowsFor(
    double maxHeight,
    double dotSize,
    double spacing,
    int totalDots, {
    int? maxRows,
  }) {
    final rows = ((maxHeight + spacing) / (dotSize + spacing)).floor();
    if (rows < 1) return 1;
    final clampedRows = maxRows != null && rows > maxRows ? maxRows : rows;
    return clampedRows > totalDots ? totalDots : clampedRows;
  }

  int _miniMaxColsFor(double maxWidth, double dotSize, double spacing) {
    final cols = ((maxWidth + spacing) / (dotSize + spacing)).floor();
    return cols < 1 ? 1 : cols;
  }

  List<Widget> _miniWithColumnSpacing(List<Widget> columns, double spacing) {
    final spaced = <Widget>[];
    for (var i = 0; i < columns.length; i += 1) {
      spaced.add(columns[i]);
      if (i < columns.length - 1) {
        spaced.add(SizedBox(width: spacing));
      }
    }
    return spaced;
  }

  Widget _miniDotColumn({
    required int redCount,
    required bool includeBlue,
    required double dotSize,
    required double spacing,
    required double height,
  }) {
    return SizedBox(
      width: dotSize,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < redCount; i += 1) ...[
            _MiniDot(color: Colors.redAccent, size: dotSize),
            if (i < redCount - 1) SizedBox(height: spacing),
          ],
          if (includeBlue) ...[
            if (redCount > 0) SizedBox(height: spacing),
            _MiniDot(color: Colors.blueAccent, size: dotSize),
          ],
        ],
      ),
    );
  }

  bool _matchesStructure(PomodoroTask a, PomodoroTask b) {
    return a.pomodoroMinutes == b.pomodoroMinutes &&
        a.shortBreakMinutes == b.shortBreakMinutes &&
        a.longBreakMinutes == b.longBreakMinutes &&
        a.longBreakInterval == b.longBreakInterval;
  }

  bool _hasMixedStructure(List<PomodoroTask> tasks) {
    if (tasks.length <= 1) return false;
    final base = tasks.first;
    for (var index = 1; index < tasks.length; index += 1) {
      if (!_matchesStructure(tasks[index], base)) return true;
    }
    return false;
  }

  Future<List<TaskRunItem>> _applySharedStructure(
    List<TaskRunItem> items, {
    required bool forceDefault,
    TaskRunItem? master,
  }) async {
    if (items.isEmpty) return items;
    final effectiveMaster = master ?? items.first;
    final shouldUseDefault =
        forceDefault || !_hasClearStructure(effectiveMaster);
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
            presetId: effectiveMaster.presetId,
            pomodoroMinutes: effectiveMaster.pomodoroMinutes,
            shortBreakMinutes: effectiveMaster.shortBreakMinutes,
            longBreakMinutes: effectiveMaster.longBreakMinutes,
            totalPomodoros: item.totalPomodoros,
            longBreakInterval: effectiveMaster.longBreakInterval,
            startSound: effectiveMaster.startSound,
            startBreakSound: effectiveMaster.startBreakSound,
            finishTaskSound: effectiveMaster.finishTaskSound,
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
      await sessionRepo.clearSessionIfGroupNotRunning();
      return false;
    }

    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final group = await groupRepo.getById(groupId);
    if (group == null || group.status != TaskRunStatus.running) {
      await sessionRepo.clearSessionIfGroupNotRunning();
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

  List<int> _previewTaskDurations(
    List<PomodoroTask> tasks,
    TaskRunIntegrityMode integrityMode,
  ) {
    if (tasks.isEmpty) return const [];
    if (integrityMode == TaskRunIntegrityMode.individual) {
      return [
        for (var index = 0; index < tasks.length; index += 1)
          _taskDurationSeconds(
            tasks[index],
            includeFinalBreak: index < tasks.length - 1,
          ),
      ];
    }

    final master = tasks.first;
    final pomodoroSeconds = master.pomodoroMinutes * 60;
    final shortBreakSeconds = master.shortBreakMinutes * 60;
    final longBreakSeconds = master.longBreakMinutes * 60;
    final totalPomodoros = tasks.fold<int>(
      0,
      (total, task) => total + task.totalPomodoros,
    );
    if (totalPomodoros <= 0) {
      return List<int>.filled(tasks.length, 0);
    }

    final durations = <int>[];
    var globalIndex = 0;
    for (final task in tasks) {
      var taskTotal = 0;
      for (var localIndex = 0;
          localIndex < task.totalPomodoros;
          localIndex += 1) {
        globalIndex += 1;
        taskTotal += pomodoroSeconds;
        if (globalIndex >= totalPomodoros) {
          continue;
        }
        final isLongBreak = globalIndex % master.longBreakInterval == 0;
        taskTotal += isLongBreak ? longBreakSeconds : shortBreakSeconds;
      }
      durations.add(taskTotal);
    }
    return durations;
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

class _MiniDot extends StatelessWidget {
  final Color color;
  final double size;

  const _MiniDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

enum _WebLocalNoticeAction { stayLocal, signIn }

enum _PreRunConflictType { running, scheduled }

class _GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;

  const _GroupConflicts({required this.running, required this.scheduled});
}

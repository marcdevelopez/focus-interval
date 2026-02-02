import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/timer_display.dart';
import '../../widgets/mode_indicator.dart';
import '../providers.dart';
import '../../domain/pomodoro_machine.dart';
import '../viewmodels/pomodoro_view_model.dart';
import '../../data/models/task_run_group.dart';
import '../../data/services/task_run_notice_service.dart';
import '../../data/services/app_mode_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TimerScreen({super.key, required this.groupId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  Timer? _clockTimer;
  Timer? _preRunTimer;
  Timer? _debugFrameTimer;
  String _currentClock = "";
  bool _taskLoaded = false;
  bool _finishedDialogVisible = false;
  bool _autoStartHandled = false;
  int _autoStartAttempts = 0;
  bool _runningAutoStartHandled = false;
  String? _runningAutoStartGroupId;
  _PreRunInfo? _preRunInfo;
  int _preRunRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Current system time (updates every second)
    _startClockTimer();
    _startDebugFramePing();

    // Load group by ID
    Future.microtask(() async {
      final result = await ref
          .read(pomodoroViewModelProvider.notifier)
          .loadGroup(widget.groupId);
      if (!mounted) return;

      switch (result) {
        case PomodoroGroupLoadResult.loaded:
          setState(() => _taskLoaded = true);
          _syncPreRunInfo(
            ref.read(pomodoroViewModelProvider.notifier).currentGroup,
          );
          _maybeAutoStartScheduled();
          break;
        case PomodoroGroupLoadResult.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected group not found.")),
          );
          Navigator.pop(context);
          break;
        case PomodoroGroupLoadResult.blockedByActiveSession:
          await _handleBlockedStart();
          break;
      }
    });
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentClock =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _updateClock();
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;
    _clockTimer = Timer(Duration(seconds: secondsUntilNextMinute), () {
      if (!mounted) return;
      _updateClock();
      _clockTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _updateClock(),
      );
    });
  }

  void _stopClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _startDebugFramePing() {
    if (!kDebugMode || defaultTargetPlatform != TargetPlatform.macOS) return;
    _debugFrameTimer?.cancel();
    _debugFrameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _stopDebugFramePing() {
    _debugFrameTimer?.cancel();
    _debugFrameTimer = null;
  }

  void _stopPreRunTimer() {
    _preRunTimer?.cancel();
    _preRunTimer = null;
  }

  @override
  void dispose() {
    _stopClockTimer();
    _stopPreRunTimer();
    _stopDebugFramePing();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      _startClockTimer();
      vm.handleAppResumed();
      return;
    }
    final keepClockActive = _keepClockActiveOutOfFocus();
    if (state == AppLifecycleState.detached ||
        (!keepClockActive &&
            (state == AppLifecycleState.inactive ||
                state == AppLifecycleState.paused))) {
      _stopClockTimer();
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      vm.handleAppPaused();
    }
  }

  void _maybeAutoStartScheduled() {
    if (_autoStartHandled) return;
    final pendingId = ref.read(scheduledAutoStartGroupIdProvider);
    if (pendingId != widget.groupId) return;
    _autoStartHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _attemptScheduledAutoStart();
    });
  }

  Future<void> _attemptScheduledAutoStart() async {
    final pendingId = ref.read(scheduledAutoStartGroupIdProvider);
    if (pendingId != widget.groupId) return;

    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final latest = await groupRepo.getById(widget.groupId);
    if (latest != null) {
      vm.updateGroup(latest);
      _syncPreRunInfo(latest);
    }
    final group = vm.currentGroup;
    if (group == null || group.status != TaskRunStatus.running) {
      if (_autoStartAttempts < 3) {
        _autoStartAttempts += 1;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        return _attemptScheduledAutoStart();
      }
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    final state = ref.read(pomodoroViewModelProvider);
    final session = ref.read(activePomodoroSessionProvider);
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final isRemoteOwner =
        session != null &&
        session.groupId == widget.groupId &&
        session.ownerDeviceId != deviceId;
    if (isRemoteOwner || !vm.canControlSession) {
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    if (state.status != PomodoroStatus.idle) {
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
    vm.start();
  }

  bool _keepClockActiveOutOfFocus() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    ref.listen<AsyncValue<List<TaskRunGroup>>>(taskRunGroupStreamProvider, (
      previous,
      next,
    ) {
      final groups = next.value ?? const [];
      final updated = groups.where((g) => g.id == widget.groupId).toList();
      if (updated.isEmpty) return;
      final group = updated.first;
      if (group.status != TaskRunStatus.running) {
        _runningAutoStartHandled = false;
        _runningAutoStartGroupId = null;
      }
      vm.updateGroup(group);
      _syncPreRunInfo(group);

      final state = ref.read(pomodoroViewModelProvider);
      final session = ref.read(activePomodoroSessionProvider);
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final isRemoteOwner =
          session != null &&
          session.groupId == widget.groupId &&
          session.ownerDeviceId != deviceId;
      final hasActiveSession = session != null && session.groupId == group.id;
      final scheduledBy = group.scheduledByDeviceId;
      if (group.status == TaskRunStatus.running &&
          state.status == PomodoroStatus.idle &&
          !isRemoteOwner &&
          hasActiveSession &&
          vm.canControlSession &&
          (scheduledBy == null || scheduledBy == deviceId)) {
        if (_runningAutoStartHandled && _runningAutoStartGroupId == group.id) {
        } else {
          _runningAutoStartHandled = true;
          _runningAutoStartGroupId = group.id;
          vm.start();
        }
      }

      if ((group.status == TaskRunStatus.canceled ||
              group.status == TaskRunStatus.completed) &&
          state.status.isActiveExecution) {
        vm.applyRemoteCancellation();
      }
    });

    ref.listen<PomodoroState>(pomodoroViewModelProvider, (previous, next) {
      final wasFinished = previous?.status == PomodoroStatus.finished;
      final nowFinished = next.status == PomodoroStatus.finished;
      if (!wasFinished && nowFinished && vm.isGroupCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showFinishedDialog(context, vm);
        });
        return;
      }
      if (_finishedDialogVisible && vm.isMirrorMode && !nowFinished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dismissFinishedDialog();
        });
      }
    });

    ref.listen<String?>(scheduledAutoStartGroupIdProvider, (previous, next) {
      if (next == widget.groupId) {
        _maybeAutoStartScheduled();
      }
    });

    final state = ref.watch(pomodoroViewModelProvider);
    final appMode = ref.watch(appModeProvider);
    final preRunInfo = _preRunInfo;
    final isPreRun = preRunInfo != null && _taskLoaded;
    final shouldBlockExit = state.status.isActiveExecution;
    final isLocalMode = appMode == AppMode.local;

    if (isPreRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensurePreRunTimer(preRunInfo);
      });
    } else {
      _stopPreRunTimer();
    }

    return PopScope(
      canPop: !shouldBlockExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExit(state, vm);
        if (!mounted || !shouldExit) return;
        navigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("Focus Interval"),
          actions: [
            const ModeIndicatorAction(compact: true),
            _PlannedGroupsIndicator(),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: _taskLoaded
                    ? TimerDisplay(
                        state: isPreRun ? _preRunState(preRunInfo) : state,
                        phaseColorOverride: isPreRun
                            ? _PreRunCenterContent.preRunColor
                            : null,
                        pulse: isPreRun && _preRunRemainingSeconds <= 60,
                        centerContent: isPreRun
                            ? _PreRunCenterContent(
                                currentClock: _currentClock,
                                remainingSeconds: _preRunRemainingSeconds,
                                firstPomodoroMinutes:
                                    preRunInfo.firstPomodoroMinutes,
                                preRunStart: preRunInfo.start,
                                scheduledStart: preRunInfo.end,
                              )
                            : _RunModeCenterContent(
                                currentClock: _currentClock,
                                state: state,
                                vm: vm,
                              ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            "Loading group...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
            if (_taskLoaded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ContextualTaskList(vm: vm, preRunInfo: preRunInfo),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlsBar(
                state: state,
                vm: vm,
                taskLoaded: _taskLoaded,
                isPreRun: isPreRun,
                isLocalMode: isLocalMode,
                onPauseRequested: () {
                  _handlePauseWithLocalInfo(vm, isLocalMode);
                },
                onLocalPauseInfo: () {
                  _showLocalPauseInfoDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePauseWithLocalInfo(
    PomodoroViewModel vm,
    bool isLocalMode,
  ) async {
    if (isLocalMode) {
      vm.pause();
      if (!mounted) return;
      await _showLocalPauseInfoDialog(context);
      return;
    }
    vm.pause();
  }

  Future<void> _showLocalPauseInfoDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFFFFC107), size: 18),
            SizedBox(width: 8),
            Text(
              "Local Mode pause",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          "If the app is closed while paused, this pause won't be restored. "
          "When you reopen the app, the timer will resume from the original start time.",
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  PomodoroState _preRunState(_PreRunInfo? info) {
    if (info == null) return PomodoroState.idle();
    return PomodoroState(
      status: PomodoroStatus.pomodoroRunning,
      phase: PomodoroPhase.pomodoro,
      currentPomodoro: 1,
      totalPomodoros: 1,
      totalSeconds: info.totalSeconds,
      remainingSeconds: _preRunRemainingSeconds,
    );
  }

  void _ensurePreRunTimer(_PreRunInfo info) {
    if (_preRunTimer != null) return;
    _preRunRemainingSeconds = info.remainingSeconds;
    _preRunTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final remaining = info.end.difference(now).inSeconds;
      final clamped = remaining < 0 ? 0 : remaining;
      if (clamped == _preRunRemainingSeconds) return;
      setState(() {
        _preRunRemainingSeconds = clamped;
      });
      if (clamped == 0) {
        unawaited(_handlePreRunCountdownFinished());
      }
    });
  }

  Future<void> _handlePreRunCountdownFinished() async {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final group = vm.currentGroup;
    if (group == null) return;

    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final scheduledBy = group.scheduledByDeviceId;
    if (scheduledBy != null && scheduledBy != deviceId) {
      return;
    }

    final session = ref.read(activePomodoroSessionProvider);
    final isRemoteOwner =
        session != null &&
        session.groupId == group.id &&
        session.ownerDeviceId != deviceId;
    if (isRemoteOwner || !vm.canControlSession) return;

    if (group.status != TaskRunStatus.running) {
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = group.id;
      await _attemptScheduledAutoStart();
      return;
    }

    final state = ref.read(pomodoroViewModelProvider);
    if (state.status == PomodoroStatus.idle) {
      vm.start();
    }
  }

  void _syncPreRunInfo(TaskRunGroup? group) {
    final info = _computePreRunInfo(group);
    final changed =
        (info == null && _preRunInfo != null) ||
        (info != null &&
            (_preRunInfo == null ||
                info.start != _preRunInfo!.start ||
                info.end != _preRunInfo!.end));
    _preRunInfo = info;
    if (info == null) {
      _preRunRemainingSeconds = 0;
      _stopPreRunTimer();
    } else {
      _preRunRemainingSeconds = info.remainingSeconds;
      if (changed) {
        _stopPreRunTimer();
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  _PreRunInfo? _computePreRunInfo(TaskRunGroup? group) {
    if (group == null) return null;
    if (group.status != TaskRunStatus.scheduled) return null;
    final scheduledStart = group.scheduledStartTime;
    if (scheduledStart == null) return null;
    final noticeMinutes =
        group.noticeMinutes ?? TaskRunNoticeService.defaultNoticeMinutes;
    if (noticeMinutes <= 0) return null;
    final now = DateTime.now();
    final start = scheduledStart.subtract(Duration(minutes: noticeMinutes));
    if (now.isBefore(start)) return null;
    if (!now.isBefore(scheduledStart)) return null;
    final totalSeconds = noticeMinutes * 60;
    final remainingSeconds = scheduledStart.difference(now).inSeconds;
    final firstPomodoroMinutes = group.tasks.isNotEmpty
        ? group.tasks.first.pomodoroMinutes
        : 0;
    return _PreRunInfo(
      start: start,
      end: scheduledStart,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds < 0 ? 0 : remainingSeconds,
      plannedStart: scheduledStart,
      firstPomodoroMinutes: firstPomodoroMinutes,
    );
  }

  void _showFinishedDialog(BuildContext context, PomodoroViewModel vm) {
    if (_finishedDialogVisible) return;
    final router = GoRouter.of(context);
    final totalTasks = vm.totalTasks;
    final totalPomodoros = vm.totalGroupPomodoros;
    final totalDuration = _formatDurationLong(vm.totalGroupDurationSeconds);
    _finishedDialogVisible = true;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "✅ Tasks group completed",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Total tasks: $totalTasks\n"
          "Total pomodoros: $totalPomodoros\n"
          "Total time: $totalDuration",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _finishedDialogVisible = false;
              Navigator.of(context, rootNavigator: true).pop();
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                router.go('/groups');
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    ).whenComplete(() {
      _finishedDialogVisible = false;
    });
  }

  void _dismissFinishedDialog() {
    if (!_finishedDialogVisible) return;
    _finishedDialogVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _handleBlockedStart() async {
    final session = await ref
        .read(pomodoroSessionStreamProvider.future)
        .catchError((_) => null);
    if (!mounted) return;
    if (session == null || !session.status.isActiveExecution) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Another group is already running. Stop it before starting a new one.",
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    final activeGroupId = session.groupId;
    final activeGroup = activeGroupId == null
        ? null
        : await groupRepo.getById(activeGroupId);
    if (!mounted) return;
    final groupName = activeGroup?.tasks.isNotEmpty == true
        ? activeGroup!.tasks.first.name
        : "Another group";

    final goToActive = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Group already running"),
        content: Text(
          "$groupName is currently running. Finish or cancel it before starting another group.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Keep running"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Go to active task"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (goToActive == true) {
      if (activeGroupId != null) {
        context.go("/timer/$activeGroupId");
      }
      return;
    }
    Navigator.pop(context);
  }

  Future<bool> _confirmExit(PomodoroState state, PomodoroViewModel vm) async {
    if (!state.status.isActiveExecution) return true;

    if (!vm.canControlSession) {
      final canTakeOver = vm.canTakeOver;
      final shouldTakeOver = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Group running on another device"),
          content: Text(
            canTakeOver
                ? "This group is controlled by another device. End it there or take over to stop it."
                : "This group is controlled by another device. End it there to stop it.",
          ),
          actions: [
            if (canTakeOver)
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Take over and end"),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Keep running"),
            ),
          ],
        ),
      );

      if (shouldTakeOver != true) return false;
      await vm.takeOver();
      vm.cancel();
      return true;
    }

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Stop current group?"),
        content: const Text(
          "You have a group in progress. End it to leave this screen or keep it running.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Keep running"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("End group and exit"),
          ),
        ],
      ),
    );

    if (shouldEnd != true) return false;
    vm.cancel();
    return true;
  }

  String _formatDurationLong(int seconds) {
    if (seconds <= 0) return "0m";
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return "${hours}h ${minutes.toString().padLeft(2, '0')}m";
    return "${minutes}m";
  }
}

class _ControlsBar extends StatelessWidget {
  final PomodoroState state;
  final PomodoroViewModel vm;
  final bool taskLoaded;
  final bool isPreRun;
  final bool isLocalMode;
  final VoidCallback onPauseRequested;
  final VoidCallback onLocalPauseInfo;

  const _ControlsBar({
    required this.state,
    required this.vm,
    required this.taskLoaded,
    required this.isPreRun,
    required this.isLocalMode,
    required this.onPauseRequested,
    required this.onLocalPauseInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = state.status == PomodoroStatus.idle;
    final isRunning =
        state.status == PomodoroStatus.pomodoroRunning ||
        state.status == PomodoroStatus.shortBreakRunning ||
        state.status == PomodoroStatus.longBreakRunning;
    final isPaused = state.status == PomodoroStatus.paused;
    final isFinished =
        state.status == PomodoroStatus.finished && vm.isGroupCompleted;
    final canTakeOver = vm.canTakeOver;
    final controlsEnabled = vm.canControlSession;
    final showLocalPauseInfo =
        isLocalMode && state.status == PomodoroStatus.paused;

    if (isPreRun) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn("Pause", null),
          _btn("Cancel", controlsEnabled ? vm.cancel : null),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (canTakeOver) _btn("Take over", () => _confirmTakeOver(context)),
        if (isIdle)
          _btn("Start", taskLoaded && controlsEnabled ? vm.start : null),
        if (isFinished)
          _btn("Start again", taskLoaded && controlsEnabled ? vm.start : null),
        if (isRunning)
          _btn("Pause", controlsEnabled ? onPauseRequested : null),
        if (isPaused)
          _buildResumeControl(
            context,
            controlsEnabled,
            showLocalPauseInfo: showLocalPauseInfo,
          ),
        if (!isIdle && !isFinished)
          _btn("Cancel", controlsEnabled ? vm.cancel : null),
      ],
    );
  }

  Widget _buildResumeControl(
    BuildContext context,
    bool controlsEnabled, {
    required bool showLocalPauseInfo,
  }) {
    final resumeButton = _btn("Resume", controlsEnabled ? vm.resume : null);
    if (!showLocalPauseInfo) return resumeButton;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        resumeButton,
        const SizedBox(width: 8),
        IconButton(
          tooltip: "Local Mode pause info",
          onPressed: onLocalPauseInfo,
          icon: const Icon(Icons.info_outline, size: 18),
          color: Colors.white60,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Future<void> _confirmTakeOver(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Take over session?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This device will become the owner and control the active pomodoro.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Take over"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vm.takeOver();
    }
  }

  Widget _btn(String text, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      child: Text(text),
    );
  }
}

class _PlannedGroupsIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(taskRunGroupStreamProvider);
    final hasPlanned = groupsAsync.maybeWhen(
      data: (groups) => groups.any((g) => g.status == TaskRunStatus.scheduled),
      orElse: () => false,
    );

    return IconButton(
      tooltip: 'Planned groups',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planned groups screen coming soon.')),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.event_note),
          if (hasPlanned)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreRunCenterContent extends StatelessWidget {
  static const preRunColor = Color(0xFFFFB300);
  static const pomodoroColor = Color(0xFFE53935);
  static final _timeFormat = DateFormat('HH:mm');

  final String currentClock;
  final int remainingSeconds;
  final int firstPomodoroMinutes;
  final DateTime preRunStart;
  final DateTime scheduledStart;

  const _PreRunCenterContent({
    required this.currentClock,
    required this.remainingSeconds,
    required this.firstPomodoroMinutes,
    required this.preRunStart,
    required this.scheduledStart,
  });

  @override
  Widget build(BuildContext context) {
    final countdown = _formatCountdown(remainingSeconds);
    final pomodoroStart = _timeFormat.format(scheduledStart);
    final focusMode = remainingSeconds <= 10;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current time (hidden in focusMode)
          AnimatedOpacity(
            opacity: focusMode ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: focusMode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentClock,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Group starts in (hidden in focusMode)
          AnimatedOpacity(
            opacity: focusMode ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            child: const Text(
              'Group starts in',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Countdown - always visible and correctly positioned
          AnimatedScale(
            scale: focusMode ? 2.4 : 1.0,
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            child: Text(
              countdown,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Status boxes (hidden in focusMode)
          AnimatedOpacity(
            opacity: focusMode ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: focusMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusBox(
                    label: 'Preparing session',
                    range: null,
                    color: preRunColor,
                  ),
                  const SizedBox(height: 10),
                  _StatusBox(
                    label: 'Starts at $pomodoroStart',
                    range: null,
                    color: pomodoroColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 60) {
      return seconds.toString().padLeft(2, '0');
    }
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _RunModeCenterContent extends StatelessWidget {
  final String currentClock;
  final PomodoroState state;
  final PomodoroViewModel vm;

  const _RunModeCenterContent({
    required this.currentClock,
    required this.state,
    required this.vm,
  });

  static const _red = Color(0xFFE53935);
  static const _blue = Color(0xFF1E88E5);
  static const _goldGreen = Color(0xFFB5C84A);

  @override
  Widget build(BuildContext context) {
    if (state.status == PomodoroStatus.finished && vm.isGroupCompleted) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'TASKS GROUP COMPLETED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    final item = vm.currentItem;
    final timeFormat = DateFormat('HH:mm');
    final phaseStart = vm.currentPhaseStartFromGroup;
    final phaseEnd = phaseStart?.add(Duration(seconds: state.totalSeconds));

    final remaining = _formatMMSS(state.remainingSeconds);

    String currentLabel = 'Ready';
    String? currentRange;
    String? nextLabel;
    String? nextRange;
    Color currentColor = Colors.white70;
    Color nextColor = Colors.white70;

    if (state.phase == PomodoroPhase.pomodoro) {
      currentLabel =
          'Pomodoro ${state.currentPomodoro} of ${state.totalPomodoros}';
      currentColor = _red;
      if (phaseStart != null) {
        currentRange = _formatRange(timeFormat, phaseStart, phaseEnd);
      }

      final isLastPomodoro = state.currentPomodoro >= state.totalPomodoros;
      final isLastTask = vm.currentTaskIndex >= vm.totalTasks - 1;
      if (isLastPomodoro && isLastTask) {
        nextLabel = 'End of group';
        nextColor = _goldGreen;
        if (phaseEnd != null) {
          nextRange = timeFormat.format(phaseEnd);
        }
      } else if (item != null && phaseEnd != null) {
        final isLongBreak = state.currentPomodoro % item.longBreakInterval == 0;
        final breakMinutes = isLongBreak
            ? item.longBreakMinutes
            : item.shortBreakMinutes;
        nextLabel = 'Break: $breakMinutes min';
        nextColor = _blue;
        final nextEnd = phaseEnd.add(Duration(minutes: breakMinutes));
        nextRange = _formatRange(timeFormat, phaseEnd, nextEnd);
      }
    } else if (state.phase == PomodoroPhase.shortBreak ||
        state.phase == PomodoroPhase.longBreak) {
      final breakMinutes = state.phase == PomodoroPhase.longBreak
          ? item?.longBreakMinutes
          : item?.shortBreakMinutes;
      currentLabel = 'Break: ${breakMinutes ?? 0} min';
      currentColor = _blue;
      if (phaseStart != null) {
        currentRange = _formatRange(timeFormat, phaseStart, phaseEnd);
      }

      if (item != null && phaseEnd != null) {
        final isLastTask = vm.currentTaskIndex >= vm.totalTasks - 1;
        final nextPomodoro = state.currentPomodoro + 1;
        if (!isLastTask && state.currentPomodoro >= state.totalPomodoros) {
          nextLabel = 'End of task';
          nextColor = _goldGreen;
          nextRange = timeFormat.format(phaseEnd);
        } else {
          nextLabel = 'Next: Pomodoro $nextPomodoro of ${state.totalPomodoros}';
          nextColor = _red;
          final nextEnd = phaseEnd.add(Duration(minutes: item.pomodoroMinutes));
          nextRange = _formatRange(timeFormat, phaseEnd, nextEnd);
        }
      }
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentClock,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          _StatusBox(
            label: currentLabel,
            range: currentRange,
            color: currentColor,
          ),
          const SizedBox(height: 10),
          if (nextLabel != null)
            _StatusBox(label: nextLabel, range: nextRange, color: nextColor),
        ],
      ),
    );
  }

  String _formatMMSS(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatRange(DateFormat format, DateTime start, DateTime? end) {
    if (end == null) return '${format.format(start)}–--:--';
    return '${format.format(start)}–${format.format(end)}';
  }
}

class _StatusBox extends StatelessWidget {
  final String label;
  final String? range;
  final Color color;

  const _StatusBox({
    required this.label,
    required this.range,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (range != null) ...[
            const SizedBox(height: 4),
            Text(
              range!,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextualTaskList extends StatelessWidget {
  final PomodoroViewModel vm;
  final _PreRunInfo? preRunInfo;

  const _ContextualTaskList({required this.vm, required this.preRunInfo});

  @override
  Widget build(BuildContext context) {
    final group = vm.currentGroup;
    final currentItem = vm.currentItem;
    if (group == null || currentItem == null) return const SizedBox.shrink();

    final timeFormat = DateFormat('HH:mm');

    String formatRange(TaskTimeRange? range) {
      if (range == null) return '--:--';
      return '${timeFormat.format(range.start)}–${timeFormat.format(range.end)}';
    }

    if (preRunInfo != null) {
      final plannedStart = preRunInfo!.plannedStart;
      final items = <_ContextItemData>[];
      for (var i = 0; i < group.tasks.length && items.length < 2; i += 1) {
        final range = _plannedRangeForIndex(group, i, plannedStart);
        items.add(
          _ContextItemData(
            label: group.tasks[i].name,
            range: formatRange(range),
            isCurrent: false,
            muted: true,
          ),
        );
      }
      return _ContextualTaskListBody(items: items);
    }

    final prev = vm.previousItem;
    final next = vm.nextItem;
    final prevIndex = vm.currentTaskIndex - 1;
    final nextIndex = vm.currentTaskIndex + 1;
    final prevRange = prevIndex >= 0 ? vm.taskRangeForIndex(prevIndex) : null;
    final currentRange = vm.taskRangeForIndex(vm.currentTaskIndex);
    final nextRange = nextIndex < group.tasks.length
        ? vm.taskRangeForIndex(nextIndex)
        : null;

    final items = <_ContextItemData>[];
    if (prev != null) {
      items.add(
        _ContextItemData(
          label: prev.name,
          range: formatRange(prevRange),
          isCurrent: false,
        ),
      );
    }

    items.add(
      _ContextItemData(
        label: currentItem.name,
        range: formatRange(currentRange),
        isCurrent: true,
      ),
    );

    if (next != null) {
      items.add(
        _ContextItemData(
          label: next.name,
          range: formatRange(nextRange),
          isCurrent: false,
        ),
      );
    }

    return _ContextualTaskListBody(items: items);
  }

  TaskTimeRange? _plannedRangeForIndex(
    TaskRunGroup group,
    int index,
    DateTime plannedStart,
  ) {
    if (index < 0 || index >= group.tasks.length) return null;
    var cursor = plannedStart;
    final lastIndex = group.tasks.length - 1;
    for (var i = 0; i < index; i += 1) {
      cursor = cursor.add(
        Duration(
          seconds: group.tasks[i].durationSeconds(
            includeFinalBreak: i < lastIndex,
          ),
        ),
      );
    }
    final duration = group.tasks[index].durationSeconds(
      includeFinalBreak: index < lastIndex,
    );
    return TaskTimeRange(cursor, cursor.add(Duration(seconds: duration)));
  }
}

class _PreRunInfo {
  final DateTime start;
  final DateTime end;
  final int totalSeconds;
  final int remainingSeconds;
  final DateTime plannedStart;
  final int firstPomodoroMinutes;

  const _PreRunInfo({
    required this.start,
    required this.end,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.plannedStart,
    required this.firstPomodoroMinutes,
  });
}

class _ContextItemData {
  final String label;
  final String range;
  final bool isCurrent;
  final bool muted;

  const _ContextItemData({
    required this.label,
    required this.range,
    required this.isCurrent,
    this.muted = false,
  });
}

class _ContextualTaskListBody extends StatelessWidget {
  final List<_ContextItemData> items;

  const _ContextualTaskListBody({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.muted
                      ? Colors.white24
                      : item.isCurrent
                      ? Colors.white70
                      : Colors.white24,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.muted
                            ? Colors.white38
                            : item.isCurrent
                            ? Colors.white
                            : Colors.white60,
                        fontWeight: item.isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    item.range,
                    style: TextStyle(
                      color: item.muted ? Colors.white38 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

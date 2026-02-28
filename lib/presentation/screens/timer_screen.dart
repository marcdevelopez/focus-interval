import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/timer_display.dart';
import '../../widgets/mode_indicator.dart';
import '../providers.dart';
import '../../domain/pomodoro_machine.dart';
import '../viewmodels/pomodoro_view_model.dart';
import '../viewmodels/pre_run_notice_view_model.dart';
import '../utils/scheduled_group_timing.dart';
import '../../data/models/task_run_group.dart';
import '../../data/models/pomodoro_session.dart';
import '../../data/services/app_mode_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TimerScreen({super.key, required this.groupId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  static const String _ownerEducationKey = 'owner_education_seen_v1';
  Timer? _clockTimer;
  bool _isDisposing = false;
  Timer? _preRunTimer;
  Timer? _debugFrameTimer;
  Timer? _inactiveRepaintTimer;
  Timer? _cancelNavRetryTimer;
  String _currentClock = "";
  bool _taskLoaded = false;
  bool _finishedDialogVisible = false;
  bool _completionDialogHandled = false;
  bool _completionDialogPending = false;
  bool _completionNavigationHandled = false;
  bool _appIsActive = true;
  bool _autoStartHandled = false;
  int _autoStartAttempts = 0;
  bool _runningAutoStartHandled = false;
  String? _runningAutoStartGroupId;
  bool _cancelNavigationHandled = false;
  int _cancelNavRetryAttempts = 0;
  String? _cancelNavTargetGroupId;
  _PreRunInfo? _preRunInfo;
  int _preRunRemainingSeconds = 0;
  int? _noticeFallbackMinutes;
  bool _ownerEducationInFlight = false;
  String? _lastOwnershipRejectionKey;
  String? _dismissedOwnershipRequestKey;
  String? _dismissedOwnershipRequesterId;
  bool _ownershipRejectionSnackVisible = false;
  bool _mirrorConflictSnackVisible = false;
  final Set<String> _dismissedMirrorConflictSnackKeys = {};
  bool _inactiveRepaintEnabled = false;
  bool _runningOverlapDialogVisible = false;
  RunningOverlapDecision? _pendingRunningOverlapDecision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Current system time (updates every second)
    _startClockTimer();
    _startDebugFramePing();

    _loadGroup(widget.groupId);
  }

  @override
  void deactivate() {
    _setCompletionDialogVisible(false);
    super.deactivate();
  }

  @override
  void didUpdateWidget(TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _resetForGroupSwitch();
      _loadGroup(widget.groupId);
    }
  }

  void _updateClock() {
    if (!mounted || _isDisposing) return;
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
      if (!mounted || _isDisposing) return;
      _updateClock();
      _clockTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) {
          if (!mounted || _isDisposing) return;
          _updateClock();
        },
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

  void _startInactiveRepaintTimer() {
    _inactiveRepaintTimer?.cancel();
    _inactiveRepaintTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _stopInactiveRepaintTimer() {
    _inactiveRepaintTimer?.cancel();
    _inactiveRepaintTimer = null;
  }

  bool _shouldEnableInactiveRepaint({
    required PomodoroState state,
    required bool isMirror,
  }) {
    if (kDebugMode) return false;
    if (defaultTargetPlatform != TargetPlatform.macOS) return false;
    if (_appIsActive) return false;
    if (!isMirror) return false;
    return state.status.isActiveExecution;
  }

  void _setInactiveRepaintEnabled(bool enabled) {
    if (_inactiveRepaintEnabled == enabled) return;
    _inactiveRepaintEnabled = enabled;
    if (enabled) {
      _startInactiveRepaintTimer();
    } else {
      _stopInactiveRepaintTimer();
    }
  }

  bool _resolveIsMirrorForCurrentSession() {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final session = vm.activeSessionForCurrentGroup;
    if (session == null) return false;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    return session.ownerDeviceId != deviceId;
  }

  void _syncInactiveRepaint({
    PomodoroState? state,
    bool? isMirror,
  }) {
    if (!mounted) return;
    final PomodoroState resolvedState =
        state ?? ref.read(pomodoroViewModelProvider);
    final resolvedMirror = isMirror ?? _resolveIsMirrorForCurrentSession();
    final shouldEnable = _shouldEnableInactiveRepaint(
      state: resolvedState,
      isMirror: resolvedMirror,
    );
    _setInactiveRepaintEnabled(shouldEnable);
  }

  void _stopCancelNavRetry() {
    _cancelNavRetryTimer?.cancel();
    _cancelNavRetryTimer = null;
  }

  void _stopPreRunTimer() {
    _preRunTimer?.cancel();
    _preRunTimer = null;
  }

  void _resetForGroupSwitch() {
    _taskLoaded = false;
    _finishedDialogVisible = false;
    _completionDialogHandled = false;
    _completionDialogPending = false;
    _completionNavigationHandled = false;
    _autoStartHandled = false;
    _autoStartAttempts = 0;
    _runningAutoStartHandled = false;
    _runningAutoStartGroupId = null;
    _cancelNavigationHandled = false;
    _cancelNavRetryAttempts = 0;
    _pendingRunningOverlapDecision = null;
    _stopCancelNavRetry();
    _setInactiveRepaintEnabled(false);
    _preRunInfo = null;
    _preRunRemainingSeconds = 0;
    _stopPreRunTimer();
  }

  String _currentRoute() {
    if (!mounted) return 'unmounted';
    return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  }

  void _loadGroup(String groupId) {
    // Load group by ID
    Future.microtask(() async {
      if (!mounted || _isDisposing) return;
      final result = await ref
          .read(pomodoroViewModelProvider.notifier)
          .loadGroup(groupId);
      if (!mounted) return;
      final currentStatus = ref
          .read(pomodoroViewModelProvider.notifier)
          .currentGroup
          ?.status
          .name;
      debugPrint(
        '[RunModeDiag] Timer load group=$groupId result=$result '
        'status=$currentStatus route=${_currentRoute()}',
      );

      switch (result) {
        case PomodoroGroupLoadResult.loaded:
          setState(() => _taskLoaded = true);
          final group =
              ref.read(pomodoroViewModelProvider.notifier).currentGroup;
          _syncPreRunInfo(group);
          if (group != null) {
            _maybeAutoStartRunningGroup(group);
          }
          _maybeAutoStartScheduled();
          break;
        case PomodoroGroupLoadResult.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected group not found.")),
          );
          final appMode = ref.read(appModeProvider);
          final target = appMode == AppMode.local ? '/tasks' : '/groups';
          context.go(target);
          break;
        case PomodoroGroupLoadResult.blockedByActiveSession:
          await _handleBlockedStart();
          break;
      }
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    _stopClockTimer();
    _stopPreRunTimer();
    _stopDebugFramePing();
    _stopInactiveRepaintTimer();
    _stopCancelNavRetry();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      _appIsActive = true;
      _startClockTimer();
      vm.handleAppResumed();
      _syncInactiveRepaint();
      _maybeShowPendingCompletionDialog(vm);
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
      _appIsActive = false;
      vm.handleAppPaused();
      _syncInactiveRepaint();
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
    if (pendingId != widget.groupId) {
      debugPrint(
        '[RunModeDiag] Auto-start skip pending=$pendingId '
        'screen=${widget.groupId} route=${_currentRoute()}',
      );
      return;
    }

    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final groupRepo = ref.read(taskRunGroupRepositoryProvider);
    debugPrint(
      '[RunModeDiag] Auto-start attempt group=${widget.groupId} '
      'route=${_currentRoute()}',
    );
    final latest = await groupRepo.getById(widget.groupId);
    if (latest != null) {
      vm.updateGroup(latest);
      _syncPreRunInfo(latest);
    }
    final group = vm.currentGroup;
    if (group == null) {
      debugPrint(
        '[RunModeDiag] Auto-start group missing; clearing pending '
        'group=${widget.groupId}',
      );
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }
    if (group.status != TaskRunStatus.running) {
      final scheduledStart = group.scheduledStartTime;
      final now = DateTime.now();
      if (group.status == TaskRunStatus.scheduled &&
          scheduledStart != null &&
          !scheduledStart.isAfter(now)) {
        final totalSeconds = group.totalDurationSeconds ??
            groupDurationSecondsByMode(group.tasks, group.integrityMode);
        final updated = group.copyWith(
          status: TaskRunStatus.running,
          actualStartTime: now,
          theoreticalEndTime: now.add(Duration(seconds: totalSeconds)),
          totalDurationSeconds: totalSeconds,
          updatedAt: now,
        );
        await groupRepo.save(updated);
        vm.updateGroup(updated);
      } else {
        debugPrint(
          '[RunModeDiag] Auto-start abort (not due) '
          'status=${group.status.name} scheduledStart=$scheduledStart now=$now',
        );
        ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
        return;
      }
    }
    if (vm.currentGroup?.status != TaskRunStatus.running) {
      if (_autoStartAttempts < 10) {
        _autoStartAttempts += 1;
        debugPrint(
          '[RunModeDiag] Auto-start wait for running '
          'attempt=$_autoStartAttempts group=${widget.groupId}',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        return _attemptScheduledAutoStart();
      }
      debugPrint(
        '[RunModeDiag] Auto-start failed to reach running '
        'group=${widget.groupId}',
      );
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    final state = ref.read(pomodoroViewModelProvider);
    final session = vm.activeSessionForCurrentGroup;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final isRemoteOwner =
        session != null &&
        session.groupId == widget.groupId &&
        session.ownerDeviceId != deviceId;
    if (isRemoteOwner) {
      debugPrint(
        '[RunModeDiag] Auto-start abort (remote owner) '
        'group=${widget.groupId} owner=${session.ownerDeviceId}',
      );
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    if (state.status != PomodoroStatus.idle) {
      debugPrint(
        '[RunModeDiag] Auto-start abort (state not idle) '
        'state=${state.status.name} group=${widget.groupId}',
      );
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
      return;
    }

    debugPrint(
      '[RunModeDiag] Auto-start startFromAutoStart group=${widget.groupId}',
    );
    _runningAutoStartHandled = true;
    _runningAutoStartGroupId = widget.groupId;
    ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
    await vm.startFromAutoStart();
    unawaited(_maybeShowOwnerEducation());
  }

  void _maybeAutoStartRunningGroup(TaskRunGroup group) {
    if (group.status != TaskRunStatus.running) {
      _runningAutoStartHandled = false;
      _runningAutoStartGroupId = null;
      return;
    }
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final state = ref.read(pomodoroViewModelProvider);
    final session = vm.activeSessionForCurrentGroup;
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final isRemoteOwner =
        session != null &&
        session.groupId == group.id &&
        session.ownerDeviceId != deviceId;
    if (state.status != PomodoroStatus.idle || isRemoteOwner) return;
    final appMode = ref.read(appModeProvider);
    if (appMode == AppMode.account && session == null) {
      final initiator = group.scheduledByDeviceId;
      if (initiator != null && initiator != deviceId) {
        return;
      }
    }
    if (_runningAutoStartHandled && _runningAutoStartGroupId == group.id) {
      return;
    }
    _runningAutoStartHandled = true;
    _runningAutoStartGroupId = group.id;
    unawaited(vm.startFromAutoStart());
    unawaited(_maybeShowOwnerEducation());
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
    final deviceId = ref.watch(deviceInfoServiceProvider).deviceId;
    _noticeFallbackMinutes = ref
        .watch(preRunNoticeMinutesProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    ref.listen<AsyncValue<List<TaskRunGroup>>>(taskRunGroupStreamProvider, (
      previous,
      next,
    ) {
      final groups = next.value ?? const [];
      final updated = groups.where((g) => g.id == widget.groupId).toList();
      if (updated.isEmpty) return;
      final group = updated.first;
      vm.updateGroup(group);
      _syncPreRunInfo(group);
      _maybeAutoStartRunningGroup(group);
      final currentState = ref.read(pomodoroViewModelProvider);

      if ((group.status == TaskRunStatus.canceled ||
              group.status == TaskRunStatus.completed) &&
          currentState.status.isActiveExecution) {
        vm.applyRemoteCancellation();
      }

      if (group.status == TaskRunStatus.completed) {
        _maybeHandleGroupCompleted(vm, group);
      }

      if (group.status == TaskRunStatus.canceled &&
          !_cancelNavigationHandled) {
        _navigateToGroupsHub(reason: 'group stream canceled');
      }
    });

    ref.listen<PomodoroState>(pomodoroViewModelProvider, (previous, next) {
      final wasFinished = previous?.status == PomodoroStatus.finished;
      final nowFinished = next.status == PomodoroStatus.finished;
      final group = vm.currentGroup;
      final isGroupCompleted =
          vm.isGroupCompleted || group?.status == TaskRunStatus.completed;
      final isLastTask = vm.nextItem == null && vm.totalTasks > 0;
      if (!wasFinished && nowFinished && (isGroupCompleted || isLastTask)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showFinishedDialog(context, vm);
        });
        return;
      }
      if (_finishedDialogVisible &&
          vm.isMirrorMode &&
          !nowFinished &&
          group?.status != TaskRunStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dismissFinishedDialog();
        });
      }
      if (group?.status == TaskRunStatus.canceled &&
          !_cancelNavigationHandled) {
        _navigateToGroupsHub(reason: 'vm canceled');
      }

      _syncOwnershipRequestUiState(vm: vm, deviceId: deviceId);
      _maybeShowPendingRunningOverlap(next, vm, deviceId);
    });

    ref.listen<String?>(scheduledAutoStartGroupIdProvider, (previous, next) {
      debugPrint(
        '[RunModeDiag] scheduledAutoStartGroupId changed '
        'prev=$previous next=$next screen=${widget.groupId} '
        'route=${_currentRoute()}',
      );
      if (next == widget.groupId) {
        _maybeAutoStartScheduled();
      }
    });

    ref.listen<RunningOverlapDecision?>(runningOverlapDecisionProvider, (
      previous,
      next,
    ) {
      if (next == null) {
        _pendingRunningOverlapDecision = null;
        if (_mirrorConflictSnackVisible) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _mirrorConflictSnackVisible = false;
        }
        return;
      }
      final groups = ref.read(taskRunGroupStreamProvider).value ?? const [];
      final activeSession = ref.read(activePomodoroSessionProvider);
      final now = DateTime.now();
      final stillValid = isRunningOverlapStillValid(
        runningGroupId: next.runningGroupId,
        scheduledGroupId: next.scheduledGroupId,
        groups: groups,
        activeSession: activeSession,
        now: now,
        fallbackNoticeMinutes: _noticeFallbackMinutes,
      );
      if (!stillValid) {
        ref.read(runningOverlapDecisionProvider.notifier).state = null;
        return;
      }
      if (_runningOverlapDialogVisible) return;
      if (_isMirrorOverlapDecision(next, vm, deviceId)) {
        final ownerStale = _isOwnerStale(
          vm.activeSessionForCurrentGroup,
          DateTime.now(),
        );
        _maybeShowMirrorConflictSnack(
          _overlapDecisionKey(next),
          ownerStale: ownerStale,
        );
        return;
      }
      if (!_isRunningOverlapDecisionForCurrentGroup(next, vm, deviceId)) {
        return;
      }
      final state = ref.read(pomodoroViewModelProvider);
      if (_shouldShowRunningOverlapNow(state, vm)) {
        unawaited(_handleRunningOverlapDecision(next));
        return;
      }
      _pendingRunningOverlapDecision = next;
    });

    final state = ref.watch(pomodoroViewModelProvider);
    final appMode = ref.watch(appModeProvider);
    final isAccountMode = appMode == AppMode.account;
    final preRunInfo = _preRunInfo;
    final isPreRun = preRunInfo != null && _taskLoaded;
    final shouldBlockExit = state.status.isActiveExecution;
    final isLocalMode = appMode == AppMode.local;
    final currentGroup = vm.currentGroup;
    final sessionForGroup = vm.activeSessionForCurrentGroup;
    final isSessionForGroup = sessionForGroup != null;
    final ownerDeviceId = sessionForGroup?.ownerDeviceId;
    final isMirror = isSessionForGroup && ownerDeviceId != deviceId;
    final hasSession = isSessionForGroup;
    final isResyncing = vm.isResyncing;
    final isSessionMissingWhileRunning =
        isAccountMode && vm.isSessionMissingWhileRunning;
    final shouldForceSyncUntilSession =
        isAccountMode &&
        currentGroup?.status == TaskRunStatus.running &&
        !isSessionForGroup;
    final isSyncingSession =
        isSessionMissingWhileRunning || shouldForceSyncUntilSession;
    final shouldHoldReadyWhileRunning =
        isAccountMode &&
        currentGroup?.status == TaskRunStatus.running &&
        state.status == PomodoroStatus.idle;
    final shouldShowResyncLoader =
        _taskLoaded &&
        !isPreRun &&
        (isResyncing || isSyncingSession || shouldHoldReadyWhileRunning);
    _syncInactiveRepaint(state: state, isMirror: isMirror);
    final ownershipRequest = vm.ownershipRequest;
    final hasPendingOwnershipRequest = vm.hasPendingOwnershipRequest;
    final hasLocalPendingOwnershipRequest = vm.hasLocalPendingOwnershipRequest;
    final isPendingForSelf =
        vm.isOwnershipRequestPendingForThisDevice ||
        (hasLocalPendingOwnershipRequest && !vm.isOwnershipRequestPendingForOther);
    final isDismissedRequest = _isDismissedOwnershipRequest(ownershipRequest);
    final showOwnerRequestBanner =
        isSessionForGroup &&
        !isMirror &&
        hasPendingOwnershipRequest &&
        ownershipRequest != null &&
        ownershipRequest.requesterDeviceId != deviceId &&
        !isDismissedRequest &&
        !isSyncingSession;
    final showOwnershipOverlay = showOwnerRequestBanner;
    final showOwnershipIndicator = currentGroup != null && isAccountMode;

    if (currentGroup?.status == TaskRunStatus.canceled &&
        !_cancelNavigationHandled) {
      _navigateToGroupsHub(reason: 'build canceled');
    }

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
            if (currentGroup != null && showOwnershipIndicator)
              _OwnershipIndicatorAction(
                isMirror: isMirror,
                isPendingRequest: isPendingForSelf,
                isSyncing: isSyncingSession && !isPendingForSelf,
                hasSession: hasSession,
                onPressed: () => _showOwnershipInfoSheet(
                  isMirror: isMirror,
                  ownerDeviceId: ownerDeviceId,
                  currentDeviceId: deviceId,
                  vm: vm,
                  isSyncing: isSyncingSession && !isPendingForSelf,
                  hasSession: hasSession,
                ),
              ),
            const ModeIndicatorAction(compact: true),
            _PlannedGroupsIndicator(),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: (!_taskLoaded || shouldShowResyncLoader)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(
                                _taskLoaded
                                    ? "Syncing session..."
                                    : "Loading group...",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          )
                        : TimerDisplay(
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
                          ),
                  ),
                ),
                if (_taskLoaded && !shouldShowResyncLoader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ContextualTaskList(vm: vm, preRunInfo: preRunInfo),
                  ),
              ],
            ),
            if (showOwnershipOverlay)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showOwnerRequestBanner)
                        _OwnershipRequestBanner(
                          requesterLabel: _platformFromDeviceId(
                            ownershipRequest.requesterDeviceId,
                          ),
                          onApprove: () =>
                              unawaited(vm.approveOwnershipRequest()),
                          onReject: () {
                            setState(() {
                              _dismissedOwnershipRequestKey =
                                  ownershipRequest.requestId ??
                                      ownershipRequest.requesterDeviceId;
                              _dismissedOwnershipRequesterId =
                                  ownershipRequest.requestId == null
                                      ? ownershipRequest.requesterDeviceId
                                      : null;
                            });
                            unawaited(vm.rejectOwnershipRequest());
                          },
                        ),
                    ],
                  ),
                ),
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
                onStartRequested: () {
                  vm.start();
                  unawaited(_maybeShowOwnerEducation());
                },
                onPauseRequested: () {
                  _handlePauseWithLocalInfo(vm, isLocalMode);
                },
                onLocalPauseInfo: () {
                  _showLocalPauseInfoDialog(context);
                },
                onCancelRequested: () {
                  _handleCancelRequested(vm);
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

    final session = vm.activeSessionForCurrentGroup;
    final isRemoteOwner =
        session != null &&
        session.groupId == group.id &&
        session.ownerDeviceId != deviceId;
    if (isRemoteOwner) return;

    if (group.status != TaskRunStatus.running) {
      ref.read(scheduledAutoStartGroupIdProvider.notifier).state = group.id;
      await _attemptScheduledAutoStart();
      return;
    }

    final state = ref.read(pomodoroViewModelProvider);
    if (state.status == PomodoroStatus.idle) {
      unawaited(vm.startFromAutoStart());
    }
  }

  Future<void> _handleRunningOverlapDecision(
    RunningOverlapDecision decision,
  ) async {
    if (_runningOverlapDialogVisible) return;
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    final state = ref.read(pomodoroViewModelProvider);
    final currentGroup = vm.currentGroup;
    if (currentGroup == null || currentGroup.id != decision.runningGroupId) {
      ref.read(runningOverlapDecisionProvider.notifier).state = null;
      return;
    }

    final wasRunning = state.status.isRunning;
    if (wasRunning) {
      vm.pause();
    }

    _runningOverlapDialogVisible = true;
    final scheduledInfo = _resolveConflictGroupInfo(decision);
    final choice = await showDialog<_RunningOverlapChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Scheduling conflict'),
        content: _ConflictDialogContent(info: scheduledInfo),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_RunningOverlapChoice.endCurrent),
            child: const Text('End current group'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_RunningOverlapChoice.postponeNext),
            child: const Text('Postpone scheduled'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(_RunningOverlapChoice.cancelScheduled),
            child: const Text('Cancel scheduled'),
          ),
        ],
      ),
    );
    _runningOverlapDialogVisible = false;

    ref.read(runningOverlapDecisionProvider.notifier).state = null;

    if (!mounted || choice == null) {
      if (wasRunning) vm.resume();
      return;
    }

    switch (choice) {
      case _RunningOverlapChoice.endCurrent:
        await vm.cancel(reason: TaskRunCanceledReason.interrupted);
        if (!mounted) return;
        context.go('/timer/${decision.scheduledGroupId}');
        return;
      case _RunningOverlapChoice.postponeNext:
        await _postponeScheduledGroup(decision);
        if (wasRunning) vm.resume();
        return;
      case _RunningOverlapChoice.cancelScheduled:
        await _cancelScheduledGroup(decision);
        if (wasRunning) vm.resume();
        return;
    }
  }

  bool _isRunningOverlapDecisionForCurrentGroup(
    RunningOverlapDecision decision,
    PomodoroViewModel vm,
    String deviceId,
  ) {
    final currentGroup = vm.currentGroup;
    if (currentGroup == null || currentGroup.id != decision.runningGroupId) {
      return false;
    }
    final session = vm.activeSessionForCurrentGroup;
    if (session != null && session.ownerDeviceId != deviceId) return false;
    if (!_isRunningOverlapDecisionActive(decision)) return false;
    return true;
  }

  bool _isMirrorOverlapDecision(
    RunningOverlapDecision decision,
    PomodoroViewModel vm,
    String deviceId,
  ) {
    final currentGroup = vm.currentGroup;
    if (currentGroup == null || currentGroup.id != decision.runningGroupId) {
      return false;
    }
    final session = vm.activeSessionForCurrentGroup;
    if (session == null || session.ownerDeviceId == deviceId) return false;
    return _isRunningOverlapDecisionActive(decision);
  }

  bool _isBreakPhase(PomodoroState state) =>
      state.phase == PomodoroPhase.shortBreak ||
      state.phase == PomodoroPhase.longBreak;

  bool _isLastPomodoroInGroup(PomodoroState state, PomodoroViewModel vm) {
    if (state.phase != PomodoroPhase.pomodoro) return false;
    if (state.currentPomodoro < state.totalPomodoros) return false;
    return vm.nextItem == null;
  }

  bool _shouldShowRunningOverlapNow(
    PomodoroState state,
    PomodoroViewModel vm,
  ) {
    if (state.status == PomodoroStatus.paused) return true;
    if (_isBreakPhase(state)) return true;
    if (_isLastPomodoroInGroup(state, vm)) return true;
    return false;
  }

  void _maybeShowPendingRunningOverlap(
    PomodoroState state,
    PomodoroViewModel vm,
    String deviceId,
  ) {
    final pending = _pendingRunningOverlapDecision;
    if (pending == null || _runningOverlapDialogVisible) return;
    if (!_isRunningOverlapDecisionActive(pending)) {
      _pendingRunningOverlapDecision = null;
      return;
    }
    if (!_isRunningOverlapDecisionForCurrentGroup(pending, vm, deviceId)) {
      _pendingRunningOverlapDecision = null;
      return;
    }
    if (!_shouldShowRunningOverlapNow(state, vm)) return;
    _pendingRunningOverlapDecision = null;
    unawaited(_handleRunningOverlapDecision(pending));
  }

  bool _isRunningOverlapDecisionActive(RunningOverlapDecision decision) {
    final groups = ref.read(taskRunGroupStreamProvider).value ?? const [];
    if (groups.isEmpty) return false;
    final activeSession = ref.read(activePomodoroSessionProvider);
    final fallback = _noticeFallbackMinutes;
    return isRunningOverlapStillValid(
      runningGroupId: decision.runningGroupId,
      scheduledGroupId: decision.scheduledGroupId,
      groups: groups,
      activeSession: activeSession,
      now: DateTime.now(),
      fallbackNoticeMinutes: fallback,
    );
  }

  Future<void> _postponeScheduledGroup(RunningOverlapDecision decision) async {
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final notifier = ref.read(notificationServiceProvider);
    final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
    final running = await repo.getById(decision.runningGroupId);
    final scheduled = await repo.getById(decision.scheduledGroupId);
    if (running == null || scheduled == null) return;

    final now = DateTime.now();
    final activeSession = ref.read(activePomodoroSessionProvider);
    final endTime =
        resolveProjectedRunningEnd(
          runningGroup: running,
          activeSession: activeSession,
          now: now,
        ) ??
        _resolveGroupEnd(running);
    if (endTime == null) return;
    final queueId = scheduled.lateStartQueueId;
    final queueOrder = scheduled.lateStartQueueOrder;
    final allGroups = queueId == null
        ? const <TaskRunGroup>[]
        : await repo.getAll();
    final queued = queueId == null
        ? <TaskRunGroup>[]
        : allGroups
            .where(
              (group) =>
                  group.status == TaskRunStatus.scheduled &&
                  group.lateStartQueueId == queueId,
            )
            .toList()
          ..sort((a, b) {
            final aOrder = a.lateStartQueueOrder ?? 0;
            final bOrder = b.lateStartQueueOrder ?? 0;
            return aOrder.compareTo(bOrder);
          });
    final startIndex = queued.isEmpty
        ? 0
        : queued.indexWhere((group) => group.id == scheduled.id);
    final applyChain = queueId != null && queueOrder != null && startIndex >= 0;
    final chainGroups =
        applyChain ? queued.sublist(startIndex) : [scheduled];
    final updates = <TaskRunGroup>[];
    var cursor = endTime;
    for (var index = 0; index < chainGroups.length; index += 1) {
      final group = chainGroups[index];
      final noticeMinutes = _resolveNoticeMinutes(group);
      final scheduledStart = ceilToMinute(
        cursor.add(Duration(minutes: noticeMinutes)),
      );
      final durationSeconds = resolveGroupDurationSeconds(group);
      final anchorId = index == 0 ? running.id : chainGroups[index - 1].id;
      final updated = group.copyWith(
        status: TaskRunStatus.scheduled,
        scheduledStartTime: scheduledStart,
        scheduledByDeviceId: deviceId,
        actualStartTime: null,
        theoreticalEndTime:
            scheduledStart.add(Duration(seconds: durationSeconds)),
        noticeSentAt: null,
        noticeSentByDeviceId: null,
        postponedAfterGroupId: anchorId,
        updatedAt: now,
      );
      updates.add(updated);
      cursor = scheduledStart.add(Duration(seconds: durationSeconds));
    }
    if (updates.length == 1) {
      await repo.save(updates.first);
    } else {
      await repo.saveAll(updates);
    }
    for (final group in updates) {
      await notifier.cancelGroupPreAlert(group.id);
    }
    if (!mounted) return;
    final firstNotice = _resolveNoticeMinutes(updates.first);
    final preRunStart = firstNotice > 0
        ? updates.first.scheduledStartTime!.subtract(
            Duration(minutes: firstNotice),
          )
        : updates.first.scheduledStartTime!;
    _showPostponeConfirmation(
      scheduledStart: updates.first.scheduledStartTime!,
      preRunStart: preRunStart,
      chainedCount: updates.length - 1,
    );
  }

  Future<void> _cancelScheduledGroup(RunningOverlapDecision decision) async {
    final repo = ref.read(taskRunGroupRepositoryProvider);
    final notifier = ref.read(notificationServiceProvider);
    final scheduled = await repo.getById(decision.scheduledGroupId);
    if (scheduled == null) return;
    final updated = scheduled.copyWith(
      status: TaskRunStatus.canceled,
      canceledReason: TaskRunCanceledReason.conflict,
      postponedAfterGroupId: null,
      updatedAt: DateTime.now(),
    );
    await repo.save(updated);
    await notifier.cancelGroupPreAlert(updated.id);
  }

  DateTime? _resolveGroupEnd(TaskRunGroup group) {
    final start = group.actualStartTime;
    if (start == null) return null;
    if (group.theoreticalEndTime.isAfter(start)) {
      return group.theoreticalEndTime;
    }
    final durationSeconds = group.totalDurationSeconds ??
        groupDurationSecondsByMode(group.tasks, group.integrityMode);
    if (durationSeconds <= 0) return start;
    return start.add(Duration(seconds: durationSeconds));
  }

  void _showPostponeConfirmation({
    required DateTime scheduledStart,
    required DateTime preRunStart,
    int chainedCount = 0,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final startLabel = _formatTimeOrDate(scheduledStart);
    final preRunLabel = _formatTimeOrDate(preRunStart);
    final chainNote = chainedCount > 0
        ? ' Remaining queued groups will shift sequentially.'
        : '';
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Scheduled start moved to $startLabel (pre-run at $preRunLabel).$chainNote',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  String _overlapDecisionKey(RunningOverlapDecision decision) {
    return '${decision.runningGroupId}_${decision.scheduledGroupId}';
  }

  bool _isOwnerStale(PomodoroSession? session, DateTime now) {
    if (session == null) return false;
    final updatedAt = session.lastUpdatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) >= const Duration(seconds: 45);
  }

  void _maybeShowMirrorConflictSnack(
    String key, {
    required bool ownerStale,
  }) {
    if (_mirrorConflictSnackVisible ||
        _dismissedMirrorConflictSnackKeys.contains(key)) {
      return;
    }
    _mirrorConflictSnackVisible = true;
    final messenger = ScaffoldMessenger.of(context);
    final message = ownerStale
        ? 'Owner seems unavailable. Claim ownership to resolve this conflict.'
        : 'Owner is resolving this conflict. Request ownership if needed.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(minutes: 10),
          dismissDirection: DismissDirection.none,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              _dismissedMirrorConflictSnackKeys.add(key);
              messenger.hideCurrentSnackBar();
              if (!mounted) return;
              setState(() {
                _mirrorConflictSnackVisible = false;
              });
            },
          ),
        ),
      ).closed.then((_) {
        if (!mounted) return;
        setState(() {
          _mirrorConflictSnackVisible = false;
        });
      });
    });
  }

  void _syncPreRunInfo(TaskRunGroup? group) {
    final allGroups = ref.read(taskRunGroupStreamProvider).value ?? const [];
    final activeSession = ref.read(activePomodoroSessionProvider);
    final info = _computePreRunInfo(
      group,
      allGroups: allGroups,
      activeSession: activeSession,
    );
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

  _PreRunInfo? _computePreRunInfo(
    TaskRunGroup? group, {
    required List<TaskRunGroup> allGroups,
    required PomodoroSession? activeSession,
  }) {
    if (group == null) return null;
    if (group.status != TaskRunStatus.scheduled) return null;
    final now = DateTime.now();
    final scheduledStart =
        resolveEffectiveScheduledStart(
          group: group,
          allGroups: allGroups,
          activeSession: activeSession,
          now: now,
          fallbackNoticeMinutes: _noticeFallbackMinutes,
        ) ??
        group.scheduledStartTime;
    if (scheduledStart == null) return null;
    final noticeMinutes = _resolveNoticeMinutes(group);
    if (noticeMinutes <= 0) return null;
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

  int _resolveNoticeMinutes(TaskRunGroup group) {
    return resolveNoticeMinutes(group, fallback: _noticeFallbackMinutes);
  }

  void _maybeHandleGroupCompleted(PomodoroViewModel vm, TaskRunGroup group) {
    if (_completionNavigationHandled) return;
    if (_completionDialogHandled || _finishedDialogVisible) return;
    if (!_appIsActive) {
      _completionDialogPending = true;
      return;
    }
    _showFinishedDialog(context, vm);
  }

  void _maybeShowPendingCompletionDialog(PomodoroViewModel vm) {
    if (!_completionDialogPending) return;
    final group = vm.currentGroup;
    if (group?.status != TaskRunStatus.completed) {
      _completionDialogPending = false;
      return;
    }
    _completionDialogPending = false;
    _showFinishedDialog(context, vm);
  }

  void _navigateToGroupsHubAfterCompletion({required String reason}) {
    if (_completionNavigationHandled) return;
    _completionNavigationHandled = true;
    _cancelNavRetryAttempts = 0;
    _cancelNavTargetGroupId = widget.groupId;
    _attemptNavigateToGroupsHub(reason);
  }

  void _showFinishedDialog(BuildContext context, PomodoroViewModel vm) {
    if (_finishedDialogVisible || _completionDialogHandled) return;
    final totalTasks = vm.totalTasks;
    final totalPomodoros = vm.totalGroupPomodoros;
    final totalDurationSeconds = vm.totalGroupDurationSeconds;
    if (totalTasks <= 0 || totalPomodoros <= 0 || totalDurationSeconds <= 0) {
      _completionDialogHandled = true;
      _navigateToGroupsHubAfterCompletion(reason: 'completion empty summary');
      return;
    }
    final totalDuration = _formatDurationLong(totalDurationSeconds);
    _finishedDialogVisible = true;
    _completionDialogHandled = true;
    _setCompletionDialogVisible(true);
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
              _setCompletionDialogVisible(false);
              Navigator.of(context, rootNavigator: true).pop();
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _navigateToGroupsHubAfterCompletion(reason: 'group completed');
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    ).whenComplete(() {
      _finishedDialogVisible = false;
      _setCompletionDialogVisible(false);
      if (!_completionNavigationHandled) {
        _navigateToGroupsHubAfterCompletion(reason: 'completion fallback');
      }
    });
  }


  Future<void> _maybeShowOwnerEducation() async {
    if (_ownerEducationInFlight) return;
    _ownerEducationInFlight = true;
    try {
      final appMode = ref.read(appModeProvider);
      if (appMode != AppMode.account) return;
      final vm = ref.read(pomodoroViewModelProvider.notifier);
      final session = vm.activeSessionForCurrentGroup;
      final deviceId = ref.read(deviceInfoServiceProvider).deviceId;
      final isOwner = session != null &&
          session.ownerDeviceId == deviceId &&
          session.status.isActiveExecution;
      if (!isOwner) return;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_ownerEducationKey) ?? false;
      if (seen) return;
      await prefs.setBool(_ownerEducationKey, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'This device controls the execution. Other devices will connect in view-only mode.',
          ),
          action: SnackBarAction(
            label: "Don't show again",
            onPressed: () {},
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      _ownerEducationInFlight = false;
    }
  }

  String _platformFromDeviceId(String deviceId) {
    final dash = deviceId.indexOf('-');
    if (dash <= 0) return deviceId;
    return deviceId.substring(0, dash);
  }

  String? _ownershipRequestKey(OwnershipRequest? request) {
    if (request == null) return null;
    return request.requestId ?? request.requesterDeviceId;
  }

  bool _isDismissedOwnershipRequest(OwnershipRequest? request) {
    if (request == null) return false;
    if (request.requestId != null) {
      return request.requestId == _dismissedOwnershipRequestKey;
    }
    final requestKey = _ownershipRequestKey(request);
    return (requestKey != null && requestKey == _dismissedOwnershipRequestKey) ||
        (_dismissedOwnershipRequesterId != null &&
            request.requesterDeviceId == _dismissedOwnershipRequesterId);
  }

  void _clearDismissedOwnershipRequest() {
    if (mounted) {
      setState(() {
        _dismissedOwnershipRequestKey = null;
        _dismissedOwnershipRequesterId = null;
      });
    } else {
      _dismissedOwnershipRequestKey = null;
      _dismissedOwnershipRequesterId = null;
    }
  }

  void _syncOwnershipRequestUiState({
    required PomodoroViewModel vm,
    required String deviceId,
  }) {
    final session = vm.activeSessionForCurrentGroup;
    final request = vm.ownershipRequest;
    final hasDismissedRequest = _dismissedOwnershipRequestKey != null ||
        _dismissedOwnershipRequesterId != null;

    if (_ownershipRejectionSnackVisible &&
        (vm.isOwnerForCurrentSession ||
            vm.isOwnershipRequestPendingForThisDevice)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _ownershipRejectionSnackVisible = false;
    }

    if (session != null && hasDismissedRequest) {
      final requestResolved = request == null ||
          request.status != OwnershipRequestStatus.pending;
      final matchesDismissed =
          request == null || _isDismissedOwnershipRequest(request);
      if (requestResolved && matchesDismissed) {
        _clearDismissedOwnershipRequest();
      }
    }

    if (request == null) return;
    if (request.status != OwnershipRequestStatus.rejected) return;
    if (request.requesterDeviceId != deviceId) return;
    final respondedAt = request.respondedAt;
    final key = request.requestId ??
        '${request.requesterDeviceId}-${respondedAt?.millisecondsSinceEpoch ?? 0}';
    if (_lastOwnershipRejectionKey == key) return;
    _lastOwnershipRejectionKey = key;
    if (!mounted) return;
    final time = DateFormat('HH:mm').format(respondedAt ?? DateTime.now());
    final messenger = ScaffoldMessenger.of(context);
    final rejectionColor = Theme.of(context).colorScheme.error.withAlpha(217);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: rejectionColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ownership request rejected at $time'),
            ),
          ],
        ),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
    _ownershipRejectionSnackVisible = true;
    controller.closed.then((_) {
      _ownershipRejectionSnackVisible = false;
    });
  }

  String _ownerLabel(String ownerDeviceId, String currentDeviceId) {
    final platform = _platformFromDeviceId(ownerDeviceId);
    if (ownerDeviceId == currentDeviceId) {
      return 'This device ($platform)';
    }
    return platform;
  }

  void _showOwnershipInfoSheet({
    required bool isMirror,
    required String? ownerDeviceId,
    required String currentDeviceId,
    required PomodoroViewModel vm,
    required bool isSyncing,
    required bool hasSession,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final ownerLabel = ownerDeviceId == null
            ? (hasSession ? 'Syncing...' : 'No active session yet')
            : _ownerLabel(ownerDeviceId, currentDeviceId);
        final request = vm.ownershipRequest;
        final isPendingForSelf =
            vm.isOwnershipRequestPendingForThisDevice ||
            (vm.hasLocalPendingOwnershipRequest &&
                !vm.isOwnershipRequestPendingForOther);
        final isPendingForOther = vm.isOwnershipRequestPendingForOther;
        final isRejectedForSelf = vm.isOwnershipRequestRejectedForThisDevice;
        final isPendingStaleForSelf =
            vm.isOwnershipRequestStaleForThisDevice ||
            vm.isLocalOwnershipRequestStaleForThisDevice;
        final canRequestOwnership =
            !isSyncing && hasSession && vm.canRequestOwnership;
        final rejectionAt = request?.respondedAt;
        final allowed = isSyncing
            ? 'Waiting for sync.'
            : !hasSession
                ? 'Waiting to start.'
                : isMirror
                    ? 'View progress only.'
                    : 'Pause, resume, and cancel.';
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session ownership',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSyncing
                      ? 'Syncing session ownership...'
                      : !hasSession
                          ? 'No active session yet.'
                          : isMirror
                              ? 'This device is in view-only mode.'
                              : 'This device controls the execution.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  'Owner: $ownerLabel',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Allowed actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allowed,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (isMirror && isPendingForSelf) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Waiting for owner approval.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                if (!isSyncing && hasSession && isMirror && isPendingForOther) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Another device is requesting ownership.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                if (!isSyncing &&
                    hasSession &&
                    isMirror &&
                    isRejectedForSelf &&
                    rejectionAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last request rejected at ${DateFormat('HH:mm').format(rejectionAt)}.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                if (isMirror) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canRequestOwnership
                          ? () {
                              Navigator.of(context).pop();
                              unawaited(vm.requestOwnership());
                            }
                          : null,
                      child: Text(
                        isPendingForSelf
                            ? isPendingStaleForSelf && canRequestOwnership
                                ? 'Retry'
                                : 'Request sent'
                            : isPendingForOther
                                ? 'Pending'
                                : isSyncing || !hasSession
                                    ? 'Syncing...'
                                    : 'Request ownership',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCancelRequested(PomodoroViewModel vm) async {
    final confirmed = await _confirmCancelDialog();
    if (confirmed != true) return;
    await _cancelAndNavigateToHub(vm);
  }

  Future<bool?> _confirmCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel group?"),
        content: const Text(
          "This will end the group and it cannot be resumed. "
          "The group will be marked as canceled.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Keep running"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Cancel group"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAndNavigateToHub(PomodoroViewModel vm) async {
    await vm.cancel();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigateToGroupsHub(reason: 'user cancel');
    });
  }

  void _navigateToGroupsHub({required String reason}) {
    if (_cancelNavigationHandled) return;
    _cancelNavigationHandled = true;
    _cancelNavRetryAttempts = 0;
    _cancelNavTargetGroupId = widget.groupId;
    _attemptNavigateToGroupsHub(reason);
  }

  void _attemptNavigateToGroupsHub(String reason) {
    if (!mounted) return;
    final rootContext =
        GoRouter.of(context).routerDelegate.navigatorKey.currentContext;
    final router = rootContext != null ? GoRouter.of(rootContext) : GoRouter.of(context);
    if (kDebugMode) {
      debugPrint(
        'Cancel nav: $reason (attempt $_cancelNavRetryAttempts, root=${rootContext != null})',
      );
    }
    router.go('/groups');
    _scheduleCancelNavRetry(router);
  }

  void _scheduleCancelNavRetry(GoRouter router) {
    if (_cancelNavRetryAttempts >= 3) return;
    _cancelNavRetryAttempts += 1;
    _cancelNavRetryTimer?.cancel();
    _cancelNavRetryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (!currentPath.startsWith('/timer/')) {
        return;
      }
      final activeId =
          currentPath.substring('/timer/'.length).split('?').first;
      if (_cancelNavTargetGroupId != null &&
          activeId != _cancelNavTargetGroupId) {
        return;
      }
      if (currentPath.startsWith('/timer/')) {
        if (kDebugMode) {
          debugPrint('Cancel nav retry $_cancelNavRetryAttempts (still in timer)');
        }
        router.go('/groups');
        _scheduleCancelNavRetry(router);
      }
    });
  }

  void _dismissFinishedDialog() {
    if (!_finishedDialogVisible) return;
    _finishedDialogVisible = false;
    _setCompletionDialogVisible(false);
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _setCompletionDialogVisible(bool value) {
    ref.read(completionDialogVisibleProvider.notifier).state = value;
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
      final appMode = ref.read(appModeProvider);
      final target = appMode == AppMode.local ? '/tasks' : '/groups';
      context.go(target);
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
    final appMode = ref.read(appModeProvider);
    final target = appMode == AppMode.local ? '/tasks' : '/groups';
    context.go(target);
  }

  Future<bool> _confirmExit(PomodoroState state, PomodoroViewModel vm) async {
    if (!state.status.isActiveExecution) return true;

    if (!vm.canControlSession) {
      final pendingForSelf =
          vm.isOwnershipRequestPendingForThisDevice ||
          (vm.hasLocalPendingOwnershipRequest &&
              !vm.isOwnershipRequestPendingForOther);
      final pendingForOther = vm.isOwnershipRequestPendingForOther;
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Group running on another device"),
          content: Text(
            pendingForSelf
                ? "Ownership request pending. Wait for approval to stop it here."
                : pendingForOther
                    ? "Another device is requesting ownership. End it there to stop it."
                    : "This group is controlled by another device. Use the ownership icon to request control.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return false;
    }

    final shouldCancel = await _confirmCancelDialog();
    if (shouldCancel != true) return false;
    await _cancelAndNavigateToHub(vm);
    return false;
  }

  String _formatDurationLong(int seconds) {
    if (seconds <= 0) return "0m";
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return "${hours}h ${minutes.toString().padLeft(2, '0')}m";
    return "${minutes}m";
  }

  String _formatTimeOrDate(DateTime value) {
    final now = DateTime.now();
    final isToday =
        value.year == now.year && value.month == now.month && value.day == now.day;
    if (isToday) {
      return DateFormat('HH:mm').format(value);
    }
    return DateFormat('MMM d, HH:mm').format(value);
  }

  String _formatConflictRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final isToday =
        start.year == now.year && start.month == now.month && start.day == now.day;
    if (isToday) {
      return '${DateFormat('HH:mm').format(start)}-${DateFormat('HH:mm').format(end)}';
    }
    final startLabel = DateFormat('MMM d, HH:mm').format(start);
    final endLabel = DateFormat('HH:mm').format(end);
    return '$startLabel-$endLabel';
  }

  _ConflictGroupInfo? _resolveConflictGroupInfo(
    RunningOverlapDecision decision,
  ) {
    final groups = ref.read(taskRunGroupStreamProvider).value ?? const [];
    final scheduled = findGroupById(groups, decision.scheduledGroupId);
    if (scheduled == null) return null;
    final name =
        scheduled.tasks.isNotEmpty ? scheduled.tasks.first.name : 'Task group';
    final activeSession = ref.read(activePomodoroSessionProvider);
    final scheduledStart =
        resolveEffectiveScheduledStart(
          group: scheduled,
          allGroups: groups,
          activeSession: activeSession,
          now: DateTime.now(),
          fallbackNoticeMinutes: _noticeFallbackMinutes,
        ) ??
        scheduled.scheduledStartTime;
    String? rangeLabel;
    String? preRunLabel;
    if (scheduledStart != null) {
      final durationSeconds = resolveGroupDurationSeconds(scheduled);
      final scheduledEnd =
          scheduledStart.add(Duration(seconds: durationSeconds));
      rangeLabel = _formatConflictRange(scheduledStart, scheduledEnd);
      final noticeMinutes = resolveNoticeMinutes(
        scheduled,
        fallback: _noticeFallbackMinutes,
      );
      if (noticeMinutes > 0) {
        final preRunStart =
            scheduledStart.subtract(Duration(minutes: noticeMinutes));
        if (!preRunStart.isAtSameMomentAs(scheduledStart)) {
          preRunLabel = _formatTimeOrDate(preRunStart);
        }
      }
    }
    return _ConflictGroupInfo(
      name: name,
      scheduledRange: rangeLabel,
      preRunStartLabel: preRunLabel,
    );
  }
}

class _ConflictGroupInfo {
  final String name;
  final String? scheduledRange;
  final String? preRunStartLabel;

  const _ConflictGroupInfo({
    required this.name,
    required this.scheduledRange,
    required this.preRunStartLabel,
  });
}

class _ConflictDialogContent extends StatelessWidget {
  final _ConflictGroupInfo? info;

  const _ConflictDialogContent({required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A scheduled group is about to start while this group is still active.',
        ),
        if (info != null) ...[
          const SizedBox(height: 12),
          Text(
            info!.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (info!.scheduledRange != null) ...[
            const SizedBox(height: 6),
            Text('Scheduled: ${info!.scheduledRange}'),
          ],
          if (info!.preRunStartLabel != null) ...[
            const SizedBox(height: 4),
            Text('Pre-Run: ${info!.preRunStartLabel}'),
          ],
        ],
      ],
    );
  }
}

class _ControlsBar extends StatelessWidget {
  static const _runModeButtonTextStyle = TextStyle(fontSize: 14);
  static const _runModeButtonIconSize = 16.0;
  static const _runModeButtonIconSpacing = 6.0;
  static const _runModeButtonPadding =
      EdgeInsets.symmetric(horizontal: 22, vertical: 14);
  static const _runModeButtonMinHeight = 44.0;
  static final _runModeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white12,
    foregroundColor: Colors.white,
    padding: _runModeButtonPadding,
    minimumSize: const Size(0, _runModeButtonMinHeight),
    textStyle: _runModeButtonTextStyle,
  );

  final PomodoroState state;
  final PomodoroViewModel vm;
  final bool taskLoaded;
  final bool isPreRun;
  final bool isLocalMode;
  final VoidCallback onStartRequested;
  final VoidCallback onPauseRequested;
  final VoidCallback onLocalPauseInfo;
  final VoidCallback onCancelRequested;

  const _ControlsBar({
    required this.state,
    required this.vm,
    required this.taskLoaded,
    required this.isPreRun,
    required this.isLocalMode,
    required this.onStartRequested,
    required this.onPauseRequested,
    required this.onLocalPauseInfo,
    required this.onCancelRequested,
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
    final controlsEnabled = vm.canControlSession;
    final showLocalPauseInfo =
        isLocalMode && state.status == PomodoroStatus.paused;

    if (isPreRun) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn("Pause", null),
          _btn(
            "Cancel",
            controlsEnabled ? onCancelRequested : null,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (isIdle)
          _btn(
            "Start",
            taskLoaded && controlsEnabled ? onStartRequested : null,
          ),
        if (isFinished)
          _btn(
            "Start again",
            taskLoaded && controlsEnabled ? onStartRequested : null,
          ),
        if (isRunning)
          _btn(
            "Pause",
            controlsEnabled ? onPauseRequested : null,
          ),
        if (isPaused)
          _buildResumeControl(
            controlsEnabled,
            showLocalPauseInfo: showLocalPauseInfo,
          ),
        if (!isIdle && !isFinished)
          _btn(
            "Cancel",
            controlsEnabled ? onCancelRequested : null,
          ),
      ],
    );
  }

  Widget _buildResumeControl(
    bool controlsEnabled, {
    required bool showLocalPauseInfo,
  }) {
    final resumeButton = _btn(
      "Resume",
      controlsEnabled ? vm.resume : null,
    );
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

  Widget _btn(
    String text,
    VoidCallback? onTap, {
    IconData? icon,
  }) {
    final child = icon == null
        ? Text(
            text,
            style: _runModeButtonTextStyle,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: _runModeButtonIconSize,
                color: Colors.white70,
              ),
              const SizedBox(width: _runModeButtonIconSpacing),
              Text(
                text,
                style: _runModeButtonTextStyle,
              ),
            ],
          );
    return ElevatedButton(
      onPressed: onTap,
      style: _runModeButtonStyle,
      child: child,
    );
  }
}

class _OwnershipRequestBanner extends StatelessWidget {
  final String requesterLabel;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _OwnershipRequestBanner({
    required this.requesterLabel,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ownership request',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$requesterLabel wants to control this session.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnershipIndicatorAction extends StatelessWidget {
  final bool isMirror;
  final bool isPendingRequest;
  final bool isSyncing;
  final bool hasSession;
  final VoidCallback onPressed;

  const _OwnershipIndicatorAction({
    required this.isMirror,
    required this.isPendingRequest,
    required this.isSyncing,
    required this.hasSession,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isPendingRequest
        ? Icons.verified
        : isSyncing
            ? Icons.sync
            : !hasSession
                ? Icons.hourglass_empty
                : isMirror
                    ? Icons.remove_red_eye
                    : Icons.verified;
    final color = isPendingRequest
        ? Colors.orangeAccent
        : isSyncing
            ? Colors.white38
            : !hasSession
                ? Colors.white54
                : isMirror
                    ? Colors.white70
                    : Colors.greenAccent;
    final tooltip = isPendingRequest
        ? 'Ownership request pending'
        : isSyncing
            ? 'Syncing session'
            : !hasSession
                ? 'No active session yet'
                : isMirror
                    ? 'Mirror device'
                    : 'Owner device';

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, color: color),
          ),
        ],
      ),
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
        context.go('/groups');
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
    final phaseEnd = vm.currentPhaseEndFromGroup;

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
    final dateFormat = DateFormat('MMM d');

    String formatRange(TaskTimeRange? range) {
      if (range == null) return '--:--';
      final start = range.start;
      final end = range.end;
      final rangeLabel =
          '${timeFormat.format(start)}–${timeFormat.format(end)}';
      final now = DateTime.now();
      final isToday =
          start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
      if (isToday) return rangeLabel;
      return '${dateFormat.format(start)}, $rangeLabel';
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
    final durations = taskDurationSecondsByMode(
      group.tasks,
      group.integrityMode,
    );
    var cursor = plannedStart;
    for (var i = 0; i < index; i += 1) {
      cursor = cursor.add(
        Duration(
          seconds: durations[i],
        ),
      );
    }
    final duration = durations[index];
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

enum _RunningOverlapChoice {
  endCurrent,
  postponeNext,
  cancelScheduled,
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

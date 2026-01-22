import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/timer_display.dart';
import '../providers.dart';
import '../../domain/pomodoro_machine.dart';
import '../viewmodels/pomodoro_view_model.dart';
import '../../data/models/task_run_group.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TimerScreen({super.key, required this.groupId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  Timer? _clockTimer;
  String _currentClock = "";
  bool _taskLoaded = false;
  bool _finishedDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Current system time (updates every second)
    _startClockTimer();

    // Load group by ID
    Future.microtask(() async {
      final result = await ref
          .read(pomodoroViewModelProvider.notifier)
          .loadGroup(widget.groupId);
      if (!mounted) return;

      switch (result) {
        case PomodoroGroupLoadResult.loaded:
          setState(() => _taskLoaded = true);
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

  @override
  void dispose() {
    _stopClockTimer();
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
    // Listen for pomodoro completion
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

    final state = ref.watch(pomodoroViewModelProvider);
    final shouldBlockExit = state.status.isActiveExecution;

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
          actions: [_PlannedGroupsIndicator()],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            // Premium clock or initial loader while loading the task
            Expanded(
              child: Center(
                child: _taskLoaded
                    ? TimerDisplay(
                        state: state,
                        centerContent: _RunModeCenterContent(
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
                child: _ContextualTaskList(vm: vm),
              ),

            // Dynamic buttons
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ControlsBar(
                state: state,
                vm: vm,
                taskLoaded: _taskLoaded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog(BuildContext context, PomodoroViewModel vm) {
    if (_finishedDialogVisible) return;
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
              vm.cancel();
              Navigator.of(context, rootNavigator: true).pop();
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

  const _ControlsBar({
    required this.state,
    required this.vm,
    required this.taskLoaded,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (canTakeOver) _btn("Take over", () => _confirmTakeOver(context)),
        if (isIdle)
          _btn("Start", taskLoaded && controlsEnabled ? vm.start : null),
        if (isFinished)
          _btn("Start again", taskLoaded && controlsEnabled ? vm.start : null),
        if (isRunning) _btn("Pause", controlsEnabled ? vm.pause : null),
        if (isPaused) _btn("Resume", controlsEnabled ? vm.resume : null),
        if (!isIdle && !isFinished)
          _btn("Cancel", controlsEnabled ? vm.cancel : null),
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

  const _ContextualTaskList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final group = vm.currentGroup;
    final currentItem = vm.currentItem;
    if (group == null || currentItem == null) return const SizedBox.shrink();

    final timeFormat = DateFormat('HH:mm');
    final prev = vm.previousItem;
    final next = vm.nextItem;
    final prevIndex = vm.currentTaskIndex - 1;
    final nextIndex = vm.currentTaskIndex + 1;
    final prevRange = prevIndex >= 0 ? vm.taskRangeForIndex(prevIndex) : null;
    final currentRange = vm.taskRangeForIndex(vm.currentTaskIndex);
    final nextRange =
        nextIndex < group.tasks.length ? vm.taskRangeForIndex(nextIndex) : null;

    String formatRange(TaskTimeRange? range) {
      if (range == null) return '--:--';
      return '${timeFormat.format(range.start)}–${timeFormat.format(range.end)}';
    }

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

}

class _ContextItemData {
  final String label;
  final String range;
  final bool isCurrent;

  const _ContextItemData({
    required this.label,
    required this.range,
    required this.isCurrent,
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
                  color: item.isCurrent ? Colors.white70 : Colors.white24,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.isCurrent ? Colors.white : Colors.white60,
                        fontWeight: item.isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    item.range,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

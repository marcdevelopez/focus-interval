import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/timer_display.dart';
import '../providers.dart';
import '../../domain/pomodoro_machine.dart';
import '../viewmodels/pomodoro_view_model.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TimerScreen({super.key, required this.taskId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  Timer? _clockTimer;
  String _currentClock = "";
  bool _taskLoaded = false;
  bool _finishedDialogVisible = false;
  bool _resumeDialogVisible = false;
  AppLifecycleState? _lifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState = WidgetsBinding.instance.lifecycleState;

    // Current system time (updates every second)
    _startClockTimer();

    // Load real task parameters by ID
    Future.microtask(() async {
      final ok = await ref
          .read(pomodoroViewModelProvider.notifier)
          .loadTask(widget.taskId);
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selected task not found."),
          ),
        );
        Navigator.pop(context);
        return;
      }

      setState(() => _taskLoaded = true);
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
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );
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
    _lifecycleState = state;
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      _startClockTimer();
      vm.handleAppResumed();
      return;
    }
    _stopClockTimer();
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      vm.handleAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    // Listen for pomodoro completion
    ref.listen<PomodoroState>(pomodoroViewModelProvider, (previous, next) {
      final wasFinished = previous?.status == PomodoroStatus.finished;
      final nowFinished = next.status == PomodoroStatus.finished;
      if (!wasFinished && nowFinished) {
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

    final lifecycleState =
        _lifecycleState ?? WidgetsBinding.instance.lifecycleState;
    final isResumed =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    final canShowResumePrompt = _taskLoaded &&
        vm.hasResumePrompt &&
        !_resumeDialogVisible &&
        isResumed;

    if (canShowResumePrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showResumeDialog(context, vm);
      });
    }

    final state = ref.watch(pomodoroViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          state.status == PomodoroStatus.finished
              ? "Task completed"
              : "Focus Interval",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _currentClock,
                style: const TextStyle(
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Premium clock or initial loader while loading the task
          Expanded(
            child: Center(
              child: _taskLoaded
                  ? TimerDisplay(state: state)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          "Loading task...",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
            ),
          ),

          // Dynamic buttons
          _ControlsBar(state: state, vm: vm, taskLoaded: _taskLoaded),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFinishedDialog(BuildContext context, PomodoroViewModel vm) {
    if (_finishedDialogVisible) return;
    _finishedDialogVisible = true;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "✅ Task completed",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "You have completed all configured pomodoros.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _finishedDialogVisible = false;
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

  void _showResumeDialog(BuildContext context, PomodoroViewModel vm) {
    if (_resumeDialogVisible || _finishedDialogVisible) return;
    if (!vm.hasResumePrompt) return;
    final projected = vm.resumePromptProjected;
    final isFinished = projected?.status == PomodoroStatus.finished;
    final pausedInBackground = vm.resumePromptFromPause;
    _resumeDialogVisible = true;
    final title = isFinished ? 'Task finished' : 'Resume task?';
    final body = isFinished
        ? 'The timer finished while the app was closed. Continue to mark the task as completed or cancel it?'
        : pausedInBackground
            ? 'The app paused the timer in background. Continue or cancel the task?'
            : 'The timer advanced while the app was closed. Continue from the current state or cancel the task?';

    showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          body,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ).then((result) {
      _resumeDialogVisible = false;
      if (!mounted) return;
      vm.resolveResumePrompt(continueTask: result == true);
    });
  }

  void _dismissFinishedDialog() {
    if (!_finishedDialogVisible) return;
    _finishedDialogVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
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
    final isFinished = state.status == PomodoroStatus.finished;
    final canTakeOver = vm.canTakeOver;
    final controlsEnabled = !vm.isMirrorMode;

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
        backgroundColor: Colors.black,
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

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/timer_display.dart';
import '../providers.dart';
import '../../domain/pomodoro_machine.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TimerScreen({super.key, required this.taskId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _clockTimer;
  String _currentClock = "";

  PomodoroStatus? _lastStatus; // para detectar transición a finished

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
    });

    // Config demo temporal (luego vendrá del repo por taskId)
    final vm = ref.read(pomodoroViewModelProvider.notifier);
    vm.configureTask(
      pomodoroMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      totalPomodoros: 2,
      longBreakInterval: 4,
    );
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentClock =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroViewModelProvider);
    final vm = ref.read(pomodoroViewModelProvider.notifier);

    // Detectar finalización para mostrar diálogo
    if (_lastStatus != PomodoroStatus.finished &&
        state.status == PomodoroStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFinishedDialog(context);
      });
    }
    _lastStatus = state.status;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          state.status == PomodoroStatus.finished
              ? "Tarea completada"
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

          // Reloj premium
          Expanded(
            child: Center(child: TimerDisplay(state: state)),
          ),

          // Botones dinámicos
          _ControlsBar(state: state, vm: vm),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatMMSS(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, "0");
    final s = (seconds % 60).toString().padLeft(2, "0");
    return "$m:$s";
  }

  void _showFinishedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "✅ Tarea finalizada",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Has completado todos los pomodoros configurados.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final PomodoroState state;
  final dynamic vm;

  const _ControlsBar({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isIdle = state.status == PomodoroStatus.idle;
    final isRunning =
        state.status == PomodoroStatus.pomodoroRunning ||
        state.status == PomodoroStatus.shortBreakRunning ||
        state.status == PomodoroStatus.longBreakRunning;
    final isPaused = state.status == PomodoroStatus.paused;
    final isFinished = state.status == PomodoroStatus.finished;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (isIdle) _btn("Start", vm.start),
        if (isRunning) _btn("Pause", vm.pause),
        if (isPaused) _btn("Resume", vm.resume),
        if (!isIdle && !isFinished) _btn("Cancel", vm.cancel),
      ],
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
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

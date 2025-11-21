import 'package:flutter/material.dart';
import 'dart:async';

import 'domain/pomodoro_machine.dart';
import 'widgets/timer_display.dart';

void main() {
  runApp(const DemoApp());
}

/// App de demostración temporal para ver el reloj.
/// ⚠️ Esta NO es la app final.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Timer Demo",
      theme: ThemeData.dark(useMaterial3: true),
      home: const TimerDemoScreen(),
    );
  }
}

class TimerDemoScreen extends StatefulWidget {
  const TimerDemoScreen({super.key});

  @override
  State<TimerDemoScreen> createState() => _TimerDemoScreenState();
}

class _TimerDemoScreenState extends State<TimerDemoScreen> {
  late PomodoroMachine machine;
  late StreamSubscription<PomodoroState> sub;

  PomodoroState _currentState = PomodoroState.idle();

  @override
  void initState() {
    super.initState();

    machine = PomodoroMachine(
      callbacks: PomodoroCallbacks(
        onPomodoroStart: (_) => print("➡️ Pomodoro iniciado"),
        onPomodoroEnd: (_) => print("⏹ Pomodoro terminado"),
        onBreakStart: (_) => print("💤 Descanso iniciado"),
        onBreakEnd: (_) => print("☕ Descanso terminado"),
        onTaskFinished: (_) => print("🎉 Tarea COMPLETADA"),
      ),
    );

    /// Configuración corta para pruebas visuales.
    machine.configureTask(
      pomodoroMinutes: 1, // 1 min real
      shortBreakMinutes: 1,
      longBreakMinutes: 1,
      totalPomodoros: 2,
      longBreakInterval: 4,
    );

    /// OVERRIDE para que dure 10s (solo demo)
    /// NO se usará en producción.
    machine.configureTask(
      pomodoroMinutes: 1, // 1 minuto normal
      shortBreakMinutes: 1,
      longBreakMinutes: 1,
      totalPomodoros: 2,
      longBreakInterval: 4,
    );

    /// Suscripción para redibujar la UI al cambiar estado.
    sub = machine.stream.listen((state) {
      setState(() {
        _currentState = state;
      });
    });
  }

  @override
  void dispose() {
    sub.cancel();
    machine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _currentState;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Demo Reloj Pomodoro"),
        backgroundColor: Colors.black,
      ),
      body: Center(child: TimerDisplay(state: s)),
      bottomNavigationBar: _buildControls(),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _demoBtn("Start", () {
            machine.startTask();
          }),
          _demoBtn("Pause", () {
            machine.pause();
          }),
          _demoBtn("Resume", () {
            machine.resume();
          }),
          _demoBtn("Cancel", () {
            machine.cancel();
          }),
        ],
      ),
    );
  }

  Widget _demoBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      child: Text(label),
    );
  }
}

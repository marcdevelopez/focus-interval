import 'dart:async';
import 'package:flutter/material.dart';
import 'domain/pomodoro_machine.dart';

void main() {
  runPomodoroTest();
}

/// Mini test manual de la máquina de estados.
/// NO es la UI final.
void runPomodoroTest() {
  final machine = PomodoroMachine(
    callbacks: PomodoroCallbacks(
      onPomodoroStart: (state) =>
          print("➡️ Pomodoro iniciado: ${state.currentPomodoro}"),
      onPomodoroEnd: (state) => print("⏹ Pomodoro terminado"),
      onBreakStart: (state) => print("💤 Descanso iniciado (${state.phase})"),
      onBreakEnd: (state) => print("☕ Descanso terminado"),
      onTaskFinished: (state) => print("🎉 Tarea COMPLETADA"),
      onTick: (state) => print("⏱ Tick: ${state.remainingSeconds}s restantes"),
    ),
  );

  // Configuración válida mínima para test (1 pomodoro, 5s de duración)
  machine.configureTask(
    pomodoroMinutes: 1,
    shortBreakMinutes: 1,
    longBreakMinutes: 1,
    totalPomodoros: 1,
    longBreakInterval: 4,
  );

  // Sobreescribimos tiempos a 5s solo para debug (NO será así en producción)
  machine..configureTask(
    pomodoroMinutes: 1,
    shortBreakMinutes: 1,
    longBreakMinutes: 1,
    totalPomodoros: 1,
    longBreakInterval: 4,
  );

  print("🚀 Iniciando Pomodoro...");
  machine.startTask();
}

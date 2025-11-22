import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/pomodoro_machine.dart';

/// Reloj circular premium para Pomodoro/Descanso.
/// - 60fps con AnimationController.
/// - Aguja analógica en sentido horario.
/// - Colores dinámicos según estado.
/// - Responsive y fondo negro real.
/// - Sin dependencias de Firebase/riverpod/UI externa.
class TimerDisplay extends StatefulWidget {
  final PomodoroState state;

  /// Si quieres forzar color final concreto.
  /// Si es null, alterna verde/dorado según pomodoro par/impar.
  final Color? finishColorOverride;

  const TimerDisplay({
    super.key,
    required this.state,
    this.finishColorOverride,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  PomodoroState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Arranque inicial alineado con el estado.
    _syncControllerWithState(initial: true);
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambió cualquier aspecto relevante del estado, resincronizamos.
    final oldState = oldWidget.state;
    final newState = widget.state;

    final phaseChanged = oldState.phase != newState.phase;
    final statusChanged = oldState.status != newState.status;
    final durationChanged = oldState.totalSeconds != newState.totalSeconds;
    final remainingChanged =
        oldState.remainingSeconds != newState.remainingSeconds;
    final pomodoroIndexChanged =
        oldState.currentPomodoro != newState.currentPomodoro;

    if (phaseChanged ||
        statusChanged ||
        durationChanged ||
        (remainingChanged && newState.status != PomodoroStatus.paused) ||
        pomodoroIndexChanged) {
      _syncControllerWithState();
    }
  }

  void _syncControllerWithState({bool initial = false}) {
    _controller.stop();

    final total = s.totalSeconds;
    final remaining = s.remainingSeconds.clamp(0, total);

    // Estado finalizado: mostrar círculo completo con color final.
    if (s.status == PomodoroStatus.finished) {
      _controller.duration = const Duration(milliseconds: 1);
      _controller.value = 1.0;
      if (!initial) setState(() {});
      return;
    }

    // En idle o sin duración no animamos.
    if (s.status == PomodoroStatus.idle || total == 0) {
      _controller.duration = const Duration(milliseconds: 1);
      _controller.value = s.progress.clamp(0, 1);
      if (!initial) setState(() {});
      return;
    }

    // Si está pausado, congelamos en el progreso actual.
    if (s.status == PomodoroStatus.paused) {
      _controller.duration = Duration(seconds: total);
      _controller.value = s.progress.clamp(0, 1);
      if (!initial) setState(() {});
      return;
    }

    // Running: animación continua desde el progreso actual hasta 1.0
    final progress = s.progress.clamp(0, 1);
    _controller.duration = Duration(seconds: total);
    _controller.value = progress.toDouble();

    final remainingDuration = Duration(seconds: remaining);

    // Si remaining == total pero progress no es 0 (edge), arreglamos.
    if (remainingDuration.inSeconds <= 0) {
      _controller.value = 1.0;
      if (!initial) setState(() {});
      return;
    }

    _controller.animateTo(
      1.0,
      duration: remainingDuration,
      curve: Curves.linear,
    );

    if (!initial) setState(() {});
  }

  Color _phaseColor() {
    switch (s.status) {
      case PomodoroStatus.pomodoroRunning:
        return const Color(0xFFE53935); // rojo
      case PomodoroStatus.shortBreakRunning:
      case PomodoroStatus.longBreakRunning:
        return const Color(0xFF1E88E5); // azul
      case PomodoroStatus.finished:
        return widget.finishColorOverride ??
            (s.totalPomodoros > 0 && s.currentPomodoro.isEven
                ? const Color(0xFFFFB300) // dorado
                : const Color(0xFF43A047)); // verde
      default:
        // paused/idle: usamos color de fase previa si existe
        if (s.phase == PomodoroPhase.shortBreak ||
            s.phase == PomodoroPhase.longBreak) {
          return const Color(0xFF1E88E5);
        }
        if (s.phase == PomodoroPhase.pomodoro) {
          return const Color(0xFFE53935);
        }
        return const Color(0xFF1E88E5);
    }
  }

  String _phaseLabel() {
    if (s.status == PomodoroStatus.finished) return "TAREA COMPLETADA";
    if (s.phase == PomodoroPhase.pomodoro) return "Pomodoro";
    if (s.phase == PomodoroPhase.shortBreak) return "Descanso corto";
    if (s.phase == PomodoroPhase.longBreak) return "Descanso largo";
    if (s.status == PomodoroStatus.paused) return "Pausado";
    return "";
  }

  String _formatMMSS(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, "0");
    final sec = (seconds % 60).toString().padLeft(2, "0");
    return "$m:$sec";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: Colors.black, // fondo negro real
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final progress = _controller.value.clamp(0, 1);

              return SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _TimerPainter(
                    progress: progress.toDouble(),
                    color: _phaseColor(),
                    status: s.status,
                  ),
                  child: _CenterContent(
                    timeText: (s.status == PomodoroStatus.finished)
                        ? "00:00"
                        : _formatMMSS(s.remainingSeconds),
                    phaseText: _phaseLabel(),
                    pomodoroText:
                        (s.status == PomodoroStatus.finished ||
                            s.totalPomodoros == 0)
                        ? ""
                        : "${s.currentPomodoro}/${s.totalPomodoros}",
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Contenido central del reloj: tiempo, fase y contador.
class _CenterContent extends StatelessWidget {
  final String timeText;
  final String phaseText;
  final String pomodoroText;

  const _CenterContent({
    required this.timeText,
    required this.phaseText,
    required this.pomodoroText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            phaseText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: phaseText == "TAREA COMPLETADA" ? 20 : 18,
              fontWeight: phaseText == "TAREA COMPLETADA"
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          if (pomodoroText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pomodoroText,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dibuja el reloj circular: aro base, progreso y aguja analógica.
class _TimerPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final PomodoroStatus status;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;

    final strokeWidth =
        size.shortestSide * 0.06; // responsive (≈12–18px típico)
    final bgStrokeWidth = strokeWidth * 0.9;

    // Aro base (gris oscuro)
    final bgPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bgStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2; // 12 en punto
    final sweepAngle = (2 * math.pi) * progress;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Aguja analógica (solo si no está idle)
    if (status != PomodoroStatus.idle) {
      final needlePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = size.shortestSide * 0.008
        ..strokeCap = StrokeCap.round;

      final angle = startAngle + sweepAngle; // sentido horario
      final needleLength = radius * 0.95;

      final needleEnd = Offset(
        center.dx + needleLength * math.cos(angle),
        center.dy + needleLength * math.sin(angle),
      );

      canvas.drawLine(center, needleEnd, needlePaint);

      // Punto central
      final hubPaint = Paint()..color = Colors.white;
      canvas.drawCircle(center, strokeWidth * 0.18, hubPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.status != status;
}

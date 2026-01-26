import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../domain/pomodoro_machine.dart';

/// Premium circular clock for Pomodoro/Break.
/// - 60fps with AnimationController.
/// - Counterclockwise countdown hand.
/// - Dynamic colors by state.
/// - Responsive with true black background.
/// - No dependencies on Firebase/riverpod/external UI.
class TimerDisplay extends StatefulWidget {
  final PomodoroState state;

  /// Optional custom center content (for Run Mode redesign).
  final Widget? centerContent;

  /// Use this to force a specific final color.
  /// If null, alternates green/gold based on even/odd pomodoro.
  final Color? finishColorOverride;

  /// Override the active ring color (used for Pre-Run Countdown mode).
  final Color? phaseColorOverride;

  /// Enable a subtle pulse on the ring.
  final bool pulse;

  const TimerDisplay({
    super.key,
    required this.state,
    this.finishColorOverride,
    this.phaseColorOverride,
    this.pulse = false,
    this.centerContent,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  PomodoroState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.pulse) {
      _pulseController.repeat(reverse: true);
    }

    // Initial start aligned with the current state.
    _syncControllerWithState(initial: true);
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If any relevant state aspect changed, resync.
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

    if (oldWidget.pulse != widget.pulse) {
      if (widget.pulse) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  void _syncControllerWithState({bool initial = false}) {
    _controller.stop();

    final total = s.totalSeconds;
    final displayRemaining = _displayRemainingSeconds();
    final remaining = displayRemaining.clamp(0, total);
    final countdown = _countdownProgress();

    // Finished state: show full circle with final color.
    if (s.status == PomodoroStatus.finished) {
      _controller.duration = const Duration(milliseconds: 1);
      _controller.value = 1.0;
      if (!initial) setState(() {});
      return;
    }

    // In idle or with no duration, do not animate.
    if (s.status == PomodoroStatus.idle || total == 0) {
      _controller.duration = const Duration(milliseconds: 1);
      _controller.value = countdown;
      if (!initial) setState(() {});
      return;
    }

    // If paused, freeze at the current progress.
    if (s.status == PomodoroStatus.paused) {
      _controller.duration = Duration(seconds: total);
      _controller.value = countdown;
      if (!initial) setState(() {});
      return;
    }

    // Running: continuous animation from remaining progress to 0.0
    _controller.duration = Duration(seconds: total);
    _controller.value = countdown;

    final remainingDuration = Duration(seconds: remaining);

    // If remaining == total but progress is not 0 (edge case), fix it.
    if (remainingDuration.inSeconds <= 0) {
      _controller.value = 0.0;
      if (!initial) setState(() {});
      return;
    }

    _controller.animateTo(
      0.0,
      duration: remainingDuration,
      curve: Curves.linear,
    );

    if (!initial) setState(() {});
  }

  double _countdownProgress() {
    final total = s.totalSeconds;
    if (total <= 0) return 0;
    final remaining = _displayRemainingSeconds().clamp(0, total);
    return remaining / total;
  }

  int _displayRemainingSeconds() {
    if (s.status == PomodoroStatus.idle && s.totalSeconds > 0) {
      return s.totalSeconds;
    }
    return s.remainingSeconds;
  }

  Color _phaseColor() {
    if (widget.phaseColorOverride != null) {
      return widget.phaseColorOverride!;
    }
    switch (s.status) {
      case PomodoroStatus.idle:
        if (s.totalSeconds > 0) {
          return const Color(0xFFE53935); // red
        }
        return const Color(0xFF222222);
      case PomodoroStatus.pomodoroRunning:
        return const Color(0xFFE53935); // red
      case PomodoroStatus.shortBreakRunning:
      case PomodoroStatus.longBreakRunning:
        return const Color(0xFF1E88E5); // blue
      case PomodoroStatus.finished:
        return widget.finishColorOverride ??
            (s.totalPomodoros > 0 && s.currentPomodoro.isEven
                ? const Color(0xFFFFB300) // gold
                : const Color(0xFF43A047)); // green
      default:
        // paused/idle: use previous phase color if available
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
    if (s.status == PomodoroStatus.finished) return "TASK COMPLETED";
    if (s.status == PomodoroStatus.idle && s.totalSeconds > 0) {
      return "Pomodoro";
    }
    if (s.phase == PomodoroPhase.pomodoro) return "Pomodoro";
    if (s.phase == PomodoroPhase.shortBreak) return "Short break";
    if (s.phase == PomodoroPhase.longBreak) return "Long break";
    if (s.status == PomodoroStatus.paused) return "Paused";
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: Colors.black, // true black background
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _pulseController]),
            builder: (_, __) {
              final progress = _controller.value.clamp(0, 1);
              final pulseValue = widget.pulse
                  ? math
                        .sin(_pulseController.value.clamp(0.0, 1.0) * math.pi)
                        .clamp(0.0, 1.0)
                  : 0.0;

              return SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _TimerPainter(
                    progress: progress.toDouble(),
                    color: _phaseColor(),
                    status: s.status,
                    pulse: pulseValue,
                  ),
                  child:
                      widget.centerContent ??
                      _CenterContent(
                        timeText: (s.status == PomodoroStatus.finished)
                            ? "00:00"
                            : _formatMMSS(_displayRemainingSeconds()),
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

/// Clock center content: time, phase, and counter.
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
              fontSize: phaseText == "TASK COMPLETED" ? 20 : 18,
              fontWeight: phaseText == "TASK COMPLETED"
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

/// Draws the circular clock: base ring, remaining arc, and analog hand.
class _TimerPainter extends CustomPainter {
  final double progress; // 0..1 remaining fraction
  final Color color;
  final PomodoroStatus status;
  final double pulse; // 0..1

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.status,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;

    final pulseFactor = 1 + (pulse * 0.12);
    final strokeWidth =
        size.shortestSide * 0.06 * pulseFactor; // responsive (≈12–18px typical)
    final bgStrokeWidth = strokeWidth * 0.9;

    // Base ring (dark gray)
    final bgPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = bgStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    final pulseOpacity = 0.65 + (pulse * 0.35);
    final progressPaint = Paint()
      ..color = color.withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = (2 * math.pi) * progress;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Progress head marker (white dot with inner hole + shadow).
    if (status != PomodoroStatus.idle || progress > 0) {
      final angle = startAngle + sweepAngle; // clockwise
      final direction = Offset(math.cos(angle), math.sin(angle));
      final markerCenter = center + direction * radius;

      final markerRadius = strokeWidth * 0.55;
      final outerShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          strokeWidth * 0.35,
        );
      canvas.drawCircle(
        markerCenter,
        markerRadius + strokeWidth * 0.25,
        outerShadowPaint,
      );

      final markerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(markerCenter, markerRadius, markerPaint);

      final ringShadowPaint = Paint()
        ..shader = ui.Gradient.radial(
          markerCenter,
          markerRadius,
          [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          [0.6, 1.0],
        );
      canvas.drawCircle(markerCenter, markerRadius, ringShadowPaint);

      final innerColor = const ui.Color.fromARGB(255, 200, 199, 199);
      final innerRadius = markerRadius * 0.55;
      final innerShadowPaint = Paint()
        ..color = const ui.Color.fromARGB(
          255,
          188,
          188,
          188,
        ).withValues(alpha: 1)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          strokeWidth * 0.15,
        );
      canvas.drawCircle(markerCenter, innerRadius, innerShadowPaint);

      final innerPaint = Paint()..color = innerColor;
      canvas.drawCircle(markerCenter, innerRadius, innerPaint);

      final innerEdgeShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.outer,
          strokeWidth * 0.15,
        );
      canvas.drawCircle(markerCenter, innerRadius, innerEdgeShadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.status != status ||
      oldDelegate.pulse != pulse;
}

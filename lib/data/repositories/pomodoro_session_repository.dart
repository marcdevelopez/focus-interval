import '../models/pomodoro_session.dart';

abstract class PomodoroSessionRepository {
  Future<void> publishSession(PomodoroSession session);
  Stream<PomodoroSession?> watchSession();
  Future<void> clearSession();
}

class NoopPomodoroSessionRepository implements PomodoroSessionRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<void> publishSession(PomodoroSession session) async {}

  @override
  Stream<PomodoroSession?> watchSession() => Stream.value(null);
}

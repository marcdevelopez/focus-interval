import '../models/pomodoro_session.dart';

abstract class PomodoroSessionRepository {
  Future<void> publishSession(PomodoroSession session);
  Stream<PomodoroSession?> watchSession();
  Future<void> clearSession();
}

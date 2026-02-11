import '../models/pomodoro_session.dart';

abstract class PomodoroSessionRepository {
  Future<void> publishSession(PomodoroSession session);
  Future<bool> tryClaimSession(PomodoroSession session);
  Stream<PomodoroSession?> watchSession();
  Future<void> clearSession();
  Future<void> requestOwnership({required String requesterDeviceId});
  Future<bool> tryAutoClaimStaleOwner({required String requesterDeviceId});
  Future<void> respondToOwnershipRequest({
    required String ownerDeviceId,
    required String requesterDeviceId,
    required bool approved,
  });
}

class NoopPomodoroSessionRepository implements PomodoroSessionRepository {
  @override
  Future<void> clearSession() async {}

  @override
  Future<void> publishSession(PomodoroSession session) async {}

  @override
  Future<bool> tryClaimSession(PomodoroSession session) async => true;

  @override
  Stream<PomodoroSession?> watchSession() => Stream.value(null);

  @override
  Future<void> requestOwnership({required String requesterDeviceId}) async {}

  @override
  Future<bool> tryAutoClaimStaleOwner({
    required String requesterDeviceId,
  }) async {
    return false;
  }

  @override
  Future<void> respondToOwnershipRequest({
    required String ownerDeviceId,
    required String requesterDeviceId,
    required bool approved,
  }) async {}
}

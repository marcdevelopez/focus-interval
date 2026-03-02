import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/repositories/firestore_pomodoro_session_repository.dart';

void main() {
  test('evaluateSessionWrite ignores lower revision', () {
    final decision = evaluateSessionWrite(
      incomingRevision: 2,
      currentRevision: 3,
      currentHasRevision: true,
    );
    expect(decision, SessionWriteDecision.ignore);
  });

  test('evaluateSessionWrite is idempotent on equal revision', () {
    final decision = evaluateSessionWrite(
      incomingRevision: 4,
      currentRevision: 4,
      currentHasRevision: true,
    );
    expect(decision, SessionWriteDecision.idempotent);
  });

  test('evaluateSessionWrite applies on higher revision', () {
    final decision = evaluateSessionWrite(
      incomingRevision: 5,
      currentRevision: 4,
      currentHasRevision: true,
    );
    expect(decision, SessionWriteDecision.apply);
  });

  test('evaluateSessionWrite applies when no current revision exists', () {
    final decision = evaluateSessionWrite(
      incomingRevision: 1,
      currentRevision: null,
      currentHasRevision: false,
    );
    expect(decision, SessionWriteDecision.apply);
  });
}

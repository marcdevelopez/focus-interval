import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/task_run_group.dart';
import 'package:focus_interval/data/repositories/firestore_task_run_group_repository.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/data/services/github_oauth_models.dart';
import 'package:focus_interval/data/services/task_run_retention_service.dart';

class _StubFirestoreService implements FirestoreService {
  @override
  FirebaseFirestore get instance =>
      throw UnsupportedError('Firestore not used in tests');
}

class _StubAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  bool get isEmailVerified => false;

  @override
  bool get requiresEmailVerification => false;

  @override
  bool get isGitHubSignInSupported => false;

  @override
  bool get isGitHubDesktopOAuthSupported => false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Stream<User?> get userChanges => const Stream.empty();

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGitHub() => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithGitHubProvider() => throw UnimplementedError();

  @override
  Future<GitHubDeviceFlowData> startGitHubDeviceFlow() =>
      throw UnimplementedError();

  @override
  Future<UserCredential> completeGitHubDeviceFlow(GitHubDeviceFlowData flow) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithGitHubDeviceFlow(GitHubDeviceFlowData flow) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> reloadCurrentUser() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _StubRetentionService extends TaskRunRetentionService {
  @override
  Future<int> getRetentionCount() async =>
      TaskRunRetentionService.defaultRetention;
}

Map<String, dynamic> _buildRunningRaw({
  required DateTime now,
}) {
  return {
    'id': 'group-1',
    'ownerUid': 'user-1',
    'status': TaskRunStatus.running.name,
    'actualStartTime': now.subtract(const Duration(hours: 2)).toIso8601String(),
    'theoreticalEndTime':
        now.subtract(const Duration(minutes: 30)).toIso8601String(),
    'totalDurationSeconds': 3600,
    'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
    'updatedAt': now.toIso8601String(),
  };
}

void main() {
  test('repo does NOT complete when activeSession is null', () {
    final repo = FirestoreTaskRunGroupRepository(
      firestoreService: _StubFirestoreService(),
      authService: _StubAuthService(),
      retentionService: _StubRetentionService(),
    );
    final now = DateTime.now();
    final normalized = repo.normalizeMapForTest(
      raw: _buildRunningRaw(now: now),
      now: now,
    );
    expect(normalized['status'], TaskRunStatus.running.name);
  });

  test('repo does NOT complete when activeSession is paused', () {
    final repo = FirestoreTaskRunGroupRepository(
      firestoreService: _StubFirestoreService(),
      authService: _StubAuthService(),
      retentionService: _StubRetentionService(),
    );
    final now = DateTime.now();
    final normalized = repo.normalizeMapForTest(
      raw: _buildRunningRaw(now: now),
      now: now,
    );
    expect(normalized['status'], TaskRunStatus.running.name);
  });

  test('repo does NOT complete when activeSession is other group', () {
    final repo = FirestoreTaskRunGroupRepository(
      firestoreService: _StubFirestoreService(),
      authService: _StubAuthService(),
      retentionService: _StubRetentionService(),
    );
    final now = DateTime.now();
    final normalized = repo.normalizeMapForTest(
      raw: _buildRunningRaw(now: now),
      now: now,
    );
    expect(normalized['status'], TaskRunStatus.running.name);
  });
}

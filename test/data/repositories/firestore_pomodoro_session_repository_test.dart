// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_interval/data/models/pomodoro_session.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/repositories/firestore_pomodoro_session_repository.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/domain/pomodoro_machine.dart';

void main() {
  test(
    'publishSession persists payload changes when sessionRevision is equal',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-a',
      );

      final first = _buildSession(
        ownerDeviceId: 'device-a',
        sessionRevision: 5,
        phase: PomodoroPhase.pomodoro,
        status: PomodoroStatus.pomodoroRunning,
        remainingSeconds: 1200,
      );
      await repo.publishSession(first);

      final updatedSameRevision = _buildSession(
        ownerDeviceId: 'device-a',
        sessionRevision: 5,
        phase: PomodoroPhase.shortBreak,
        status: PomodoroStatus.shortBreakRunning,
        remainingSeconds: 300,
      );
      await repo.publishSession(updatedSameRevision);

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['sessionRevision'], 5);
      expect(stored['phase'], PomodoroPhase.shortBreak.name);
      expect(stored['status'], PomodoroStatus.shortBreakRunning.name);
      expect(stored['remainingSeconds'], 300);
    },
  );

  test(
    'publishSession keeps existing snapshot when incoming owner differs',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-a',
      );

      await repo.publishSession(
        _buildSession(
          ownerDeviceId: 'device-a',
          sessionRevision: 7,
          phase: PomodoroPhase.pomodoro,
          status: PomodoroStatus.pomodoroRunning,
          remainingSeconds: 1000,
        ),
      );

      await repo.publishSession(
        _buildSession(
          ownerDeviceId: 'device-b',
          sessionRevision: 7,
          phase: PomodoroPhase.shortBreak,
          status: PomodoroStatus.shortBreakRunning,
          remainingSeconds: 200,
        ),
      );

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['phase'], PomodoroPhase.pomodoro.name);
      expect(stored['remainingSeconds'], 1000);
    },
  );

  test(
    'tryAutoClaimStaleOwner auto-claims running stale owner without manual request',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 3,
        'lastUpdatedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 60)),
        ),
      });

      final claimed = await repo.tryAutoClaimStaleOwner(
        requesterDeviceId: 'device-b',
      );

      expect(claimed, isTrue);
      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-b');
      expect(stored['sessionRevision'], 4);
    },
  );

  test(
    'tryAutoClaimStaleOwner does not claim running owner before 45s stale threshold',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 9,
        'lastUpdatedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 44)),
        ),
      });

      final claimed = await repo.tryAutoClaimStaleOwner(
        requesterDeviceId: 'device-b',
      );

      expect(claimed, isFalse);
      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['sessionRevision'], 9);
    },
  );

  test(
    'tryAutoClaimStaleOwner claims paused stale owner only when pending request is for requester',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.paused.name,
        'sessionRevision': 11,
        'lastUpdatedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 60)),
        ),
        'ownershipRequest': {
          'requestId': 'request-1',
          'requesterDeviceId': 'device-b',
          'status': 'pending',
          'requestedAt': Timestamp.fromDate(
            now.subtract(const Duration(minutes: 2)),
          ),
          'respondedAt': null,
          'respondedByDeviceId': null,
        },
      });

      final claimed = await repo.tryAutoClaimStaleOwner(
        requesterDeviceId: 'device-b',
      );

      expect(claimed, isTrue);
      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-b');
      expect(stored['sessionRevision'], 12);
    },
  );

  test(
    'tryAutoClaimStaleOwner does not claim paused stale owner without self pending request',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.paused.name,
        'sessionRevision': 13,
        'lastUpdatedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 60)),
        ),
        'ownershipRequest': {
          'requestId': 'request-2',
          'requesterDeviceId': 'device-c',
          'status': 'pending',
          'requestedAt': Timestamp.fromDate(
            now.subtract(const Duration(minutes: 2)),
          ),
          'respondedAt': null,
          'respondedByDeviceId': null,
        },
      });

      final claimed = await repo.tryAutoClaimStaleOwner(
        requesterDeviceId: 'device-b',
      );

      expect(claimed, isFalse);
      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['sessionRevision'], 13);
    },
  );

  test(
    'requestOwnership never transfers owner even when owner heartbeat is stale',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 21,
        'lastUpdatedAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 60)),
        ),
      });

      await repo.requestOwnership(
        requesterDeviceId: 'device-b',
        requestId: 'request-stale-owner',
      );

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(
        stored!['ownerDeviceId'],
        'device-a',
        reason:
            'requestOwnership must only create/update ownershipRequest and never transfer owner.',
      );
      expect(stored['sessionRevision'], 21);
      final request = Map<String, dynamic>.from(
        stored['ownershipRequest'] as Map<dynamic, dynamic>,
      );
      expect(request['requestId'], 'request-stale-owner');
      expect(request['requesterDeviceId'], 'device-b');
      expect(request['status'], 'pending');
    },
  );

  test(
    'clearSessionAsOwner keeps session when caller is not current owner',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 31,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await repo.clearSessionAsOwner();

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['sessionRevision'], 31);
    },
  );

  test(
    'clearSessionAsOwner deletes session when caller matches current owner',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-a',
      );
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 32,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await repo.clearSessionAsOwner();

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNull);
    },
  );

  test(
    'tryAutoClaimStaleOwner does not claim when lastUpdatedAt is missing',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-b',
      );
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 41,
      });

      final claimed = await repo.tryAutoClaimStaleOwner(
        requesterDeviceId: 'device-b',
      );

      expect(claimed, isFalse);
      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['sessionRevision'], 41);
    },
  );

  test(
    'clearSessionIfStale keeps active session when lastUpdatedAt is missing',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final repo = FirestorePomodoroSessionRepository(
        firestoreService: _FakeFirestoreService(firestore),
        authService: _FakeAuthService(_FakeUser('user-1')),
        deviceId: 'device-a',
      );
      final now = DateTime.now();
      firestore.seedDoc(_sessionPath('user-1'), {
        'ownerDeviceId': 'device-a',
        'status': PomodoroStatus.pomodoroRunning.name,
        'sessionRevision': 42,
      });

      await repo.clearSessionIfStale(now: now);

      final stored = firestore.readDoc(_sessionPath('user-1'));
      expect(stored, isNotNull);
      expect(stored!['ownerDeviceId'], 'device-a');
      expect(stored['status'], PomodoroStatus.pomodoroRunning.name);
      expect(stored['sessionRevision'], 42);
    },
  );
}

String _sessionPath(String uid) => 'users/$uid/activeSession/current';

PomodoroSession _buildSession({
  required String ownerDeviceId,
  required int sessionRevision,
  required PomodoroPhase phase,
  required PomodoroStatus status,
  required int remainingSeconds,
}) {
  final now = DateTime.utc(2026, 3, 2, 19, 41, 0);
  return PomodoroSession(
    taskId: 'task-1',
    groupId: 'group-1',
    currentTaskId: 'task-1',
    currentTaskIndex: 0,
    totalTasks: 1,
    dataVersion: kCurrentDataVersion,
    sessionRevision: sessionRevision,
    ownerDeviceId: ownerDeviceId,
    status: status,
    phase: phase,
    currentPomodoro: 1,
    totalPomodoros: 4,
    phaseDurationSeconds: 1500,
    remainingSeconds: remainingSeconds,
    accumulatedPausedSeconds: 0,
    phaseStartedAt: now.subtract(const Duration(minutes: 5)),
    currentTaskStartedAt: now.subtract(const Duration(minutes: 5)),
    pausedAt: null,
    lastUpdatedAt: now,
    finishedAt: null,
    pauseReason: null,
    ownershipRequest: null,
  );
}

class _FakeFirestoreService implements FirestoreService {
  _FakeFirestoreService(this.instance);

  @override
  final FirebaseFirestore instance;
}

class _FakeAuthService extends Fake implements AuthService {
  _FakeAuthService(this.currentUser);

  @override
  final User? currentUser;

  @override
  bool get isSignedIn => currentUser != null;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

class _FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _docs = {};

  void seedDoc(String path, Map<String, dynamic> data) {
    _docs[path] = _deepCloneMap(data);
  }

  Map<String, dynamic>? readDoc(String path) {
    final data = _docs[path];
    if (data == null) return null;
    return _deepCloneMap(data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionReference(firestore: this, path: collectionPath);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    return transactionHandler(_FakeTransaction(this));
  }

  Map<String, dynamic>? _getDoc(String path) {
    final data = _docs[path];
    if (data == null) return null;
    return _deepCloneMap(data);
  }

  void _setDoc(String path, Map<String, dynamic> data, {required bool merge}) {
    if (!merge || !_docs.containsKey(path)) {
      _docs[path] = _deepCloneMap(data);
      return;
    }
    final current = _deepCloneMap(_docs[path]!);
    for (final entry in data.entries) {
      current[entry.key] = _deepCloneValue(entry.value);
    }
    _docs[path] = current;
  }

  void _deleteDoc(String path) {
    _docs.remove(path);
  }
}

class _FakeTransaction extends Fake implements Transaction {
  _FakeTransaction(this._firestore);

  final _FakeFirebaseFirestore _firestore;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final path = documentReference.path;
    final data = _firestore._getDoc(path);
    final mapReference =
        documentReference as DocumentReference<Map<String, dynamic>>;
    return _FakeDocumentSnapshot(reference: mapReference, data: data)
        as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final map = Map<String, dynamic>.from(data as Map);
    _firestore._setDoc(
      documentReference.path,
      map,
      merge: options?.merge ?? false,
    );
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) {
    _firestore._deleteDoc(documentReference.path);
    return this;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<String, dynamic> data,
  ) {
    _firestore._setDoc(documentReference.path, data, merge: true);
    return this;
  }
}

class _FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference({required this.firestore, required this.path});

  @override
  final FirebaseFirestore firestore;

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  DocumentReference<Map<String, dynamic>>? get parent => null;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) {
    final safeId = id ?? 'doc-auto';
    return _FakeDocumentReference(firestore: firestore, path: '$path/$safeId');
  }
}

class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference({required this.firestore, required this.path});

  @override
  final FirebaseFirestore firestore;

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> get parent {
    final slash = path.lastIndexOf('/');
    final parentPath = slash < 0 ? '' : path.substring(0, slash);
    return _FakeCollectionReference(firestore: firestore, path: parentPath);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionReference(
      firestore: firestore,
      path: '$path/$collectionPath',
    );
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    final data = (firestore as _FakeFirebaseFirestore)._getDoc(path);
    return _FakeDocumentSnapshot(reference: this, data: data);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    (firestore as _FakeFirebaseFirestore)._setDoc(
      path,
      data,
      merge: options?.merge ?? false,
    );
  }

  @override
  Future<void> delete() async {
    (firestore as _FakeFirebaseFirestore)._deleteDoc(path);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final mapped = <String, dynamic>{};
    for (final entry in data.entries) {
      mapped[entry.key.toString()] = entry.value;
    }
    (firestore as _FakeFirebaseFirestore)._setDoc(path, mapped, merge: true);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    yield await get();
  }

  @override
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    throw UnsupportedError('withConverter is not used in these tests');
  }
}

class _FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot({
    required this.reference,
    required Map<String, dynamic>? data,
  }) : _data = data == null ? null : _deepCloneMap(data);

  final Map<String, dynamic>? _data;

  @override
  final DocumentReference<Map<String, dynamic>> reference;

  @override
  String get id => reference.id;

  @override
  bool get exists => _data != null;

  @override
  SnapshotMetadata get metadata {
    throw UnsupportedError('metadata is not used in these tests');
  }

  @override
  Map<String, dynamic>? data() {
    final data = _data;
    if (data == null) return null;
    return _deepCloneMap(data);
  }

  @override
  dynamic get(Object field) {
    if (_data == null) {
      throw StateError('Document does not exist');
    }
    final key = field.toString();
    if (!_data.containsKey(key)) {
      throw StateError('Field "$key" does not exist');
    }
    return _data[key];
  }

  @override
  dynamic operator [](Object field) => get(field);
}

Map<String, dynamic> _deepCloneMap(Map<String, dynamic> source) {
  final clone = <String, dynamic>{};
  for (final entry in source.entries) {
    clone[entry.key] = _deepCloneValue(entry.value);
  }
  return clone;
}

dynamic _deepCloneValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), _deepCloneValue(mapValue)),
    );
  }
  if (value is List) {
    return value.map(_deepCloneValue).toList(growable: false);
  }
  return value;
}

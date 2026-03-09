import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class TimeSyncService {
  static const Duration minRefreshInterval = Duration(seconds: 30);
  static const Duration _rejectCooldown = Duration(seconds: 3);
  static const Duration _maxValidRoundTrip = Duration(seconds: 3);
  static const Duration _maxOffsetJump = Duration(seconds: 5);
  static const String _collection = 'timeSync';
  static const String _docId = 'anchor';

  final AuthService? _authService;
  final FirestoreService? _firestoreService;
  final bool _enabled;

  Duration? _offset;
  DateTime? _lastSyncAt;
  DateTime? _lastRejectedAt;
  String? _lastUserId;
  Future<Duration?>? _inFlight;

  TimeSyncService({
    AuthService? authService,
    FirestoreService? firestoreService,
    bool enabled = false,
  }) : _authService = authService,
       _firestoreService = firestoreService,
       _enabled = enabled;

  Duration? get offset => _offset;

  DateTime? get lastSyncAt => _lastSyncAt;

  bool get isEnabled => _enabled;

  DateTime? serverNow({DateTime? localNow}) {
    final currentOffset = _offset;
    if (currentOffset == null) return null;
    final base = localNow ?? DateTime.now();
    return base.add(currentOffset);
  }

  Future<Duration?> refresh({bool force = false}) async {
    if (!_enabled) return _offset;
    final uid = _authService?.currentUser?.uid;
    final db = _firestoreService?.instance;
    if (uid == null || db == null) return _offset;
    if (_lastUserId != uid) {
      _lastUserId = uid;
      _offset = null;
      _lastSyncAt = null;
      _lastRejectedAt = null;
    }
    final now = DateTime.now();
    final lastRejectedAt = _lastRejectedAt;
    if (lastRejectedAt != null &&
        now.difference(lastRejectedAt) < _rejectCooldown) {
      return _offset;
    }
    final lastSyncAt = _lastSyncAt;
    if (!force && lastSyncAt != null) {
      if (now.difference(lastSyncAt) < minRefreshInterval) {
        return _offset;
      }
    }
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final completer = Completer<Duration?>();
    _inFlight = completer.future;
    try {
      final docRef = db
          .collection('users')
          .doc(uid)
          .collection(_collection)
          .doc(_docId);
      final localBefore = DateTime.now();
      await docRef.set({
        'serverTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final snap = await docRef.get(const GetOptions(source: Source.server));
      final localAfter = DateTime.now();
      final data = snap.data();
      final serverTime = data?['serverTime'] as Timestamp?;
      if (serverTime != null) {
        final roundTrip =
            localAfter.difference(localBefore).inMicroseconds ~/ 2;
        final roundTripDuration = Duration(microseconds: roundTrip * 2);
        final localMid = localBefore.add(Duration(microseconds: roundTrip));
        final measuredOffset = serverTime.toDate().difference(localMid);
        final previousOffset = _offset;
        final hasInvalidRoundTrip = roundTripDuration > _maxValidRoundTrip;
        final hasInvalidOffsetJump =
            previousOffset != null &&
            (measuredOffset - previousOffset).abs() > _maxOffsetJump;
        if (hasInvalidRoundTrip || hasInvalidOffsetJump) {
          _lastRejectedAt = localAfter;
          if (kDebugMode) {
            debugPrint(
              '[TimeSync] rejected measurement '
              '(roundTripMs=${roundTripDuration.inMilliseconds} '
              'offsetMs=${measuredOffset.inMilliseconds} '
              'prevOffsetMs=${previousOffset?.inMilliseconds ?? 'n/a'})',
            );
          }
          completer.complete(_offset);
          return completer.future;
        }
        _offset = measuredOffset;
        _lastSyncAt = localAfter;
        _lastRejectedAt = null;
        if (kDebugMode) {
          debugPrint(
            '[TimeSync] offset=${_offset?.inMilliseconds}ms '
            'local=$localAfter server=${serverTime.toDate()}',
          );
        }
      }
      completer.complete(_offset);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[TimeSync] refresh failed: $error');
      }
      completer.complete(_offset);
    } finally {
      _inFlight = null;
    }
    return completer.future;
  }

  void reset() {
    _offset = null;
    _lastSyncAt = null;
    _lastRejectedAt = null;
    _lastUserId = null;
    _inFlight = null;
  }
}

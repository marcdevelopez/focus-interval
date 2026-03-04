import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class TimeSyncService {
  static const Duration minRefreshInterval = Duration(seconds: 30);
  static const String _collection = 'timeSync';
  static const String _docId = 'anchor';

  final AuthService? _authService;
  final FirestoreService? _firestoreService;
  final bool _enabled;

  Duration? _offset;
  DateTime? _lastSyncAt;
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
    }
    final now = DateTime.now();
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
      final docRef =
          db.collection('users').doc(uid).collection(_collection).doc(_docId);
      final localBefore = DateTime.now();
      await docRef.set({
        'serverTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final snap = await docRef.get(
        const GetOptions(source: Source.server),
      );
      final localAfter = DateTime.now();
      final data = snap.data();
      final serverTime = data?['serverTime'] as Timestamp?;
      if (serverTime != null) {
        final roundTrip =
            localAfter.difference(localBefore).inMicroseconds ~/ 2;
        final localMid =
            localBefore.add(Duration(microseconds: roundTrip));
        _offset = serverTime.toDate().difference(localMid);
        _lastSyncAt = localAfter;
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
    _lastUserId = null;
    _inFlight = null;
  }
}

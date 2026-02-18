import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class TaskRunNoticeService {
  static const int defaultNoticeMinutes = 5;
  static const int minNoticeMinutes = 0;
  static const int maxNoticeMinutes = 15;
  static const String _localKey = 'task_run_notice_minutes_v2';
  static const String _legacyLocalKey = 'task_run_notice_minutes_v1';
  static const String _accountKeyPrefix = 'task_run_notice_minutes_account_v1_';
  static const String _settingsCollection = 'settings';
  static const String _settingsDocId = 'preferences';

  final AuthService? _authService;
  final FirestoreService? _firestoreService;
  final bool _useAccount;

  TaskRunNoticeService({
    AuthService? authService,
    FirestoreService? firestoreService,
    bool useAccount = false,
  }) : _authService = authService,
       _firestoreService = firestoreService,
       _useAccount = useAccount;

  Future<int> getNoticeMinutes() async {
    final accountValue = await _loadAccountNoticeMinutes();
    if (accountValue != null) return accountValue;
    return _loadLocalNoticeMinutes();
  }

  Future<int> setNoticeMinutes(int value) async {
    final clamped = _clamp(value);
    final wroteAccount = await _saveAccountNoticeMinutes(clamped);
    if (!wroteAccount) {
      await _storeLocalNoticeMinutes(clamped, key: _fallbackLocalKey());
    }
    return clamped;
  }

  Future<int?> _loadAccountNoticeMinutes() async {
    if (!_useAccount) return null;
    final uid = _authService?.currentUser?.uid;
    final db = _firestoreService?.instance;
    if (uid == null || db == null) return null;
    try {
      final doc =
          await db
              .collection('users')
              .doc(uid)
              .collection(_settingsCollection)
              .doc(_settingsDocId)
              .get();
      final raw = (doc.data() ?? const {})['noticeMinutes'] as num?;
      final localFallback = await _loadLocalNoticeMinutes(
        key: _accountKey(uid),
      );
      final resolved = raw == null ? localFallback : raw.toInt();
      final clamped = _clamp(resolved);
      await _storeLocalNoticeMinutes(clamped, key: _accountKey(uid));
      if (raw == null) {
        await _saveAccountNoticeMinutes(clamped);
      }
      return clamped;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _saveAccountNoticeMinutes(int value) async {
    if (!_useAccount) return false;
    final uid = _authService?.currentUser?.uid;
    final db = _firestoreService?.instance;
    if (uid == null || db == null) return false;
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection(_settingsCollection)
          .doc(_settingsDocId)
          .set({
            'noticeMinutes': value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      await _storeLocalNoticeMinutes(value, key: _accountKey(uid));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> _loadLocalNoticeMinutes({String? key}) async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedKey = key ?? _fallbackLocalKey();
    var raw = prefs.getInt(resolvedKey);
    if (raw == null && resolvedKey == _localKey) {
      final legacy = prefs.getInt(_legacyLocalKey);
      if (legacy != null) {
        final clamped = _clamp(legacy);
        await prefs.setInt(_localKey, clamped);
        raw = clamped;
      }
    }
    raw ??= defaultNoticeMinutes;
    return _clamp(raw);
  }

  Future<void> _storeLocalNoticeMinutes(
    int value, {
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  String _accountKey(String uid) => '$_accountKeyPrefix$uid';

  String _fallbackLocalKey() {
    final uid = _authService?.currentUser?.uid;
    if (_useAccount && uid != null) return _accountKey(uid);
    return _localKey;
  }

  int _clamp(int value) {
    if (value < minNoticeMinutes) return minNoticeMinutes;
    if (value > maxNoticeMinutes) return maxNoticeMinutes;
    return value;
  }
}

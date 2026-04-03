import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_interval/data/models/pomodoro_preset.dart';
import 'package:focus_interval/data/models/schema_version.dart';
import 'package:focus_interval/data/models/selected_sound.dart';
import 'package:focus_interval/data/repositories/firestore_pomodoro_preset_repository.dart';
import 'package:focus_interval/data/repositories/local_pomodoro_preset_repository.dart';
import 'package:focus_interval/data/services/app_mode_service.dart';
import 'package:focus_interval/data/services/firebase_auth_service.dart';
import 'package:focus_interval/data/services/firestore_service.dart';
import 'package:focus_interval/presentation/providers.dart';
import 'package:focus_interval/widgets/preset_sync_coordinator.dart';

class _FakeUser implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestorePresetRepository extends FirestorePomodoroPresetRepository {
  _FakeFirestorePresetRepository({required List<PomodoroPreset> initial})
    : _store = {for (final preset in initial) preset.id: preset},
      super(
        firestoreService: StubFirestoreService(),
        authService: StubAuthService(),
      );

  final Map<String, PomodoroPreset> _store;
  final List<PomodoroPreset> saveLog = [];

  @override
  Future<List<PomodoroPreset>> getAll() async => _store.values.toList();

  @override
  Future<PomodoroPreset?> getById(String id) async => _store[id];

  @override
  Future<void> save(PomodoroPreset preset) async {
    saveLog.add(preset);
    _store[preset.id] = preset;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Stream<List<PomodoroPreset>> watchAll() =>
      Stream<List<PomodoroPreset>>.value(_store.values.toList());
}

PomodoroPreset _buildCustomPreset({required String id, required DateTime now}) {
  return PomodoroPreset(
    id: id,
    name: 'Deep Work Focus',
    dataVersion: kCurrentDataVersion,
    pomodoroMinutes: 30,
    shortBreakMinutes: 6,
    longBreakMinutes: 18,
    longBreakInterval: 3,
    startSound: const SelectedSound.builtIn('default_chime'),
    startBreakSound: const SelectedSound.builtIn('default_chime_break'),
    finishTaskSound: const SelectedSound.builtIn('default_chime_finish'),
    isDefault: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets(
    'PresetSyncCoordinator dedupes Classic Pomodoro when pushing account-local presets',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final user = _FakeUser('rvp027-user');
      final localClassic = PomodoroPreset.classicDefault(
        id: 'local-classic',
        now: now,
      );
      final localCustom = _buildCustomPreset(
        id: 'local-custom',
        now: now.add(const Duration(seconds: 1)),
      );
      final remoteClassic = PomodoroPreset.classicDefault(
        id: 'remote-classic',
        now: now.add(const Duration(seconds: 2)),
      );

      final localRepo = LocalPomodoroPresetRepository(
        prefsKey: 'account_presets_v1_${user.uid}',
      );
      await localRepo.save(localClassic);
      await localRepo.save(localCustom);

      final remoteRepo = _FakeFirestorePresetRepository(
        initial: [remoteClassic],
      );
      final appModeService = AppModeService.memory();

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          appModeServiceProvider.overrideWithValue(appModeService),
          currentUserProvider.overrideWith((_) => user),
          accountLocalPresetRepositoryProvider.overrideWithValue(localRepo),
          firestorePresetRepositoryProvider.overrideWithValue(remoteRepo),
        ],
      );

      try {
        await container.read(appModeProvider.notifier).setAccount();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PresetSyncCoordinator(child: SizedBox.shrink()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final remotePresets = await remoteRepo.getAll();
        final classicCount = remotePresets
            .where(
              (preset) =>
                  preset.name.trim().toLowerCase() == 'classic pomodoro',
            )
            .length;
        expect(classicCount, 1);
        expect(
          remoteRepo.saveLog
              .where(
                (preset) =>
                    preset.name.trim().toLowerCase() == 'classic pomodoro',
              )
              .isEmpty,
          isTrue,
        );
        expect(
          remotePresets.any((preset) => preset.id == localCustom.id),
          isTrue,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('account_presets_pushed_v1_${user.uid}'), isTrue);
      } finally {
        container.dispose();
      }
    },
  );
}

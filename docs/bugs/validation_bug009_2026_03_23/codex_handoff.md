# Codex Handoff — BUG-013 Completion modal no se cierra al iniciar pre-run

## Branch
`fix-bug009b-cascade-completion-overlap` (continuar en la misma)

## Reference commit
`76ee374`

## Regla obligatoria
Lee CLAUDE.md secciones 3 y 4 antes de tocar cualquier archivo.

## Overview
Un solo commit. Un archivo modificado. Un test añadido.

BUGLOG-009B (Capa 3) ya está implementado y validado. Este handoff cubre BUG-013.

El problema: cuando G1 completa y el modal de finalización permanece visible, el modal no
se auto-cierra cuando G2 entra en su ventana de pre-run (1 minuto antes de arrancar).
Solo se cerraba cuando G2 pasaba a `running` — 1 minuto después, bloqueando la UI.

La causa: el listener de `scheduledAutoStartGroupIdProvider` en `timer_screen.dart`
recibe el ID de G2 cuando el coordinador emite `openTimer` para G2 (en el instante del
pre-alert, `prealert-timer-fired`). Pero el listener solo actúa cuando
`next == widget.groupId` (el propio grupo). Para G1's screen, `next = G2.id ≠ G1.id`
→ no hace nada. El dismiss era accionado más tarde por el cambio en `PomodoroState`
a `isActiveExecution` cuando G2 ya estaba corriendo.

La solución: en ese mismo listener, si `next != null && next != widget.groupId &&
_finishedDialogVisible`, llamar a `_dismissCompletionDialogForAutoOpen` con
`reason: 'next group pre-run'`. Esto cubre tanto pre-run como auto-start directo,
tanto owner como mirror (el coordinador corre en ambos dispositivos y setea el provider
localmente en cada uno).

---

## Cambio 1 — `lib/presentation/screens/timer_screen.dart`

**Por qué:** El `scheduledAutoStartGroupIdProvider` se setea con el ID de G2 cuando el
pre-alert de G2 dispara (1 min antes de su scheduled start). G1's timer screen recibe
ese evento pero lo ignora porque `next != widget.groupId`. El modal sigue visible
durante 1 minuto extra, bloqueando la UI de pre-run. Añadir el check para `next != null
&& next != widget.groupId` permite cerrar el modal en el momento correcto.

**Código actual (líneas 566–575):**
```dart
    ref.listen<String?>(scheduledAutoStartGroupIdProvider, (previous, next) {
      debugPrint(
        '[RunModeDiag] scheduledAutoStartGroupId changed '
        'prev=$previous next=$next screen=${widget.groupId} '
        'route=${_currentRoute()}',
      );
      if (next == widget.groupId) {
        _maybeAutoStartScheduled();
      }
    });
```

**Reemplazar con:**
```dart
    ref.listen<String?>(scheduledAutoStartGroupIdProvider, (previous, next) {
      debugPrint(
        '[RunModeDiag] scheduledAutoStartGroupId changed '
        'prev=$previous next=$next screen=${widget.groupId} '
        'route=${_currentRoute()}',
      );
      if (next == widget.groupId) {
        _maybeAutoStartScheduled();
      }
      // BUG-013: dismiss the completion modal when another group enters its
      // pre-run or auto-start window. The coordinator sets this provider at
      // prealert time (1 min before scheduled start), which is earlier than
      // the PomodoroState → isActiveExecution transition that previously
      // drove the dismiss. Works for both owner and mirror devices because
      // the coordinator runs locally on each device.
      if (next != null && next != widget.groupId && _finishedDialogVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dismissCompletionDialogForAutoOpen(reason: 'next group pre-run');
        });
      }
    });
```

**Restricciones:**
- Solo añadir el bloque `if (next != null && next != widget.groupId...)` — no tocar la
  lógica existente del listener.
- No tocar `_dismissCompletionDialogForAutoOpen` ni `_dismissFinishedDialog`.
- No modificar los otros paths de dismiss (listener de `TaskRunGroup`, listener de
  `PomodoroState`). Los paths existentes siguen siendo válidos como fallback.

---

## Cambio 2 — `test/presentation/timer_screen_completion_navigation_test.dart`

Añadir el siguiente test dentro del `group` principal, después del test
`'auto-dismisses completion modal when timer route switches to next group'`
(que termina en la línea ~733):

```dart
  testWidgets(
    'auto-dismisses completion modal when next group enters pre-run '
    '(scheduledAutoStartGroupId set to next group)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final deviceInfo = DeviceInfoService.ephemeral();
      final firstGroup = _buildRunningGroup(id: 'g1-prerun-dismiss', now: now);
      final secondGroup = _buildScheduledGroup(
        id: 'g2-prerun-target',
        now: now,
      ).copyWith(
        scheduledStartTime: now.add(const Duration(minutes: 5)),
        theoreticalEndTime: now.add(const Duration(minutes: 30)),
        noticeMinutes: 1,
      );

      final groupRepo = FakeTaskRunGroupRepository()
        ..seed(firstGroup)
        ..seed(secondGroup);
      final sessionRepo = FakePomodoroSessionRepository(
        _buildRunningSession(
          groupId: firstGroup.id,
          ownerDeviceId: deviceInfo.deviceId,
          now: now,
        ),
      );
      final appModeService = AppModeService.memory();
      var disposed = false;

      final container = ProviderContainer(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(StubAuthService()),
          firestoreServiceProvider.overrideWithValue(StubFirestoreService()),
          taskRunGroupRepositoryProvider.overrideWithValue(groupRepo),
          pomodoroSessionRepositoryProvider.overrideWithValue(sessionRepo),
          appModeServiceProvider.overrideWithValue(appModeService),
          deviceInfoServiceProvider.overrideWithValue(deviceInfo),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          timeSyncServiceProvider.overrideWithValue(FakeTimeSyncService()),
        ],
      );
      final router = GoRouter(
        initialLocation: '/timer/${firstGroup.id}',
        routes: [
          GoRoute(
            path: '/timer/:id',
            builder: (context, state) =>
                TimerScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const Scaffold(body: Text('groups-screen')),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const Scaffold(body: Text('tasks-screen')),
          ),
        ],
      );
      try {
        await container.read(appModeProvider.notifier).setAccount();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump(const Duration(milliseconds: 180));

        // Complete G1 — triggers completion modal.
        groupRepo.emit(
          firstGroup.copyWith(
            status: TaskRunStatus.completed,
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 220));
        expect(find.text('✅ Tasks group completed'), findsOneWidget);

        // Simulate coordinator setting scheduledAutoStartGroupId for G2
        // (fires at prealert time, 1 min before G2 scheduled start).
        // G1's timer screen must dismiss the modal without waiting for G2 running.
        container
            .read(scheduledAutoStartGroupIdProvider.notifier)
            .state = secondGroup.id;
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 80));
          if (find.text('✅ Tasks group completed').evaluate().isEmpty) break;
        }

        expect(
          find.text('✅ Tasks group completed'),
          findsNothing,
          reason:
              'completion modal must auto-dismiss at next group pre-run, '
              'not wait until next group is running',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        container.dispose();
        sessionRepo.dispose();
        groupRepo.dispose();
        disposed = true;
      } finally {
        if (!disposed) {
          container.dispose();
          sessionRepo.dispose();
          groupRepo.dispose();
        }
      }
    },
  );
```

**Restricciones:**
- Usar los helpers `_buildRunningGroup`, `_buildScheduledGroup`, `_buildRunningSession`
  ya existentes. No crear nuevos helpers.
- El provider `scheduledAutoStartGroupIdProvider` ya está importado vía
  `package:focus_interval/presentation/providers.dart` (línea 26 del test).
- No eliminar ni modificar el test `'auto-dismisses completion modal when timer route
  switches to next group'` existente.

---

## Orden del commit

Un único commit:

```
fix(timer): auto-dismiss completion modal at next group pre-run

scheduledAutoStartGroupIdProvider is set when the coordinator opens the
pre-alert window for the next group (1 min before scheduled start).
G1's timer screen now listens for any non-null value pointing to a
different group and dismisses the completion dialog immediately, instead
of waiting for PomodoroState → isActiveExecution (i.e., next group
running) which fired 1 minute later.
```

---

## Tests a ejecutar antes de devolver a Claude

```bash
flutter analyze
flutter test test/presentation/timer_screen_completion_navigation_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```

Todos deben pasar. Si el test existente
`'auto-dismisses completion modal when timer route switches to next group'`
falla por el nuevo código, investiga — no debe fallar porque ese test no setea
`scheduledAutoStartGroupIdProvider` para un grupo diferente.

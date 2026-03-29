# Codex Handoff — BUG-015 (v2 — Fix A revisado por Codex review)

## Branch
`fix/buglog-running-without-foreground-ready-invalid`

## Reference commit
`f929117`

## Regla obligatoria
Leer `CLAUDE.md` secciones 3 (anti-patrones confirmados) y 4 (guardrails) antes de escribir una línea de código.

## Overview
Tres commits en `lib/presentation/viewmodels/pomodoro_view_model.dart`.
Cada commit tiene alcance quirúrgico: un bug vector o un test.

> **Nota de revisión:** La versión anterior del Fix A fallaba silenciosamente porque
> `_applyGroupTimelineProjection` contiene `if (!_controlsEnabled) return false;`
> y `_controlsEnabled` devuelve `false` cuando `_resyncInProgress = true`.
> `syncWithRemoteSession` activa `_resyncInProgress = true` antes de llamar a
> `_hydrateOwnerSession`, así que el guard de controls bloqueaba el camino de
> recovery exactamente cuando más se necesitaba. Fix A corregido añade un parámetro
> named que permite bypasear esa sola guarda en el contexto de recuperación.

---

## Fix A — Recovery en `_hydrateOwnerSession` cuando la proyección de sesión sobrepasa la tarea (vector primario)

**Archivo:** `lib/presentation/viewmodels/pomodoro_view_model.dart`
**Funciones modificadas:** `_applyGroupTimelineProjection` + `_hydrateOwnerSession`

### Por qué es necesario

Cuando Android toma ownership de una sesión stale de macOS (con máquina en `idle` desde mirror mode),
`_hydrateOwnerSession` proyecta la sesión con `_projectStateFromSession`, que solo proyecta
**dentro de la tarea actual**. Si el tiempo transcurrido supera la duración de esa tarea,
devuelve `PomodoroStatus.finished` → se publica `finished` a Firestore → UI muestra "Ready" + ámbar.

La solución es activar la proyección por **grupo** (`_applyGroupTimelineProjection`) en ese caso.
Pero `_applyGroupTimelineProjection` contiene `if (!_controlsEnabled) return false;`, y
`_controlsEnabled` devuelve `false` cuando `_resyncInProgress = true` — que es exactamente
el estado durante `syncWithRemoteSession`. La barrera `_controlsEnabled` es correcta para el
uso normal (previene que el usuario interactúe durante un resync), pero es incorrecto bloquear
la **recuperación de estado** durante ese mismo resync.

Fix: añadir parámetro named `skipControlsCheck` a `_applyGroupTimelineProjection`, con default
`false` para preservar todo comportamiento existente. Solo el call site de recovery en
`_hydrateOwnerSession` lo activa.

---

### Cambio 1 de 2 — firma de `_applyGroupTimelineProjection`

**Código actual (~línea 2827):**
```dart
bool _applyGroupTimelineProjection(DateTime now) {
  final group = _currentGroup;
  if (group == null) return false;
  if (group.status != TaskRunStatus.running) return false;
  if (!_controlsEnabled) return false;
  if (state.status == PomodoroStatus.paused) return false;
```

**Código nuevo:**
```dart
bool _applyGroupTimelineProjection(DateTime now, {bool skipControlsCheck = false}) {
  final group = _currentGroup;
  if (group == null) return false;
  if (group.status != TaskRunStatus.running) return false;
  if (!skipControlsCheck && !_controlsEnabled) return false;
  if (state.status == PomodoroStatus.paused) return false;
```

**Constraints:**
- Solo cambiar la firma y la línea `if (!_controlsEnabled)`.
- Ningún otro cambio en el cuerpo de `_applyGroupTimelineProjection`.
- Todos los call sites existentes ya tienen `skipControlsCheck = false` por el default → comportamiento preservado.

---

### Cambio 2 de 2 — `_hydrateOwnerSession`

**Código actual (~línea 2118):**
```dart
    _applyProjectedState(projected, now: projectionNow ?? now);
    _pinOwnerPhaseStartFromSession(session);
    final allowTimelineProjection =
        ref.read(appModeProvider) != AppMode.account;
    if (allowTimelineProjection &&
        session.status != PomodoroStatus.paused &&
        _applyGroupTimelineProjection(now)) {
      _bumpSessionRevision();
      _publishCurrentSession();
      return;
    }
    _publishCurrentSession();
```

**Código nuevo:**
```dart
    _applyProjectedState(projected, now: projectionNow ?? now);
    _pinOwnerPhaseStartFromSession(session);
    final allowTimelineProjection =
        ref.read(appModeProvider) != AppMode.account;
    // In Account mode: if the session-based projection overshot the current task
    // boundary (returned finished for a non-completed group), fall back to group
    // timeline. skipControlsCheck=true because this runs inside syncWithRemoteSession
    // which holds _resyncInProgress=true, blocking _controlsEnabled.
    final overshotTaskBoundary =
        projected.status == PomodoroStatus.finished && !_groupCompleted;
    if ((allowTimelineProjection || overshotTaskBoundary) &&
        session.status != PomodoroStatus.paused &&
        _applyGroupTimelineProjection(now, skipControlsCheck: overshotTaskBoundary)) {
      _bumpSessionRevision();
      _publishCurrentSession();
      return;
    }
    _publishCurrentSession();
```

**Constraints:**
- Solo cambiar las líneas mostradas dentro de `_hydrateOwnerSession`.
- No tocar ninguna otra línea de la función.
- `_groupCompleted` ya existe como campo de ViewModel.
- El comentario es informativo y debe quedar en el código.

---

## Fix B — Guard contra publish de `finished` transitorio en `_applySessionTimelineProjection` (vector secundario)

**Archivo:** `lib/presentation/viewmodels/pomodoro_view_model.dart`
**Función:** `_applySessionTimelineProjection` (~línea 1626)

### Por qué es necesario

Un sync concurrente (resync inactivo o stream) puede llegar durante `await _resolveServerNow()`
en `_handleTaskFinishedInternal`, cuando la máquina está transientemente en `finished`
(entre tareas). La rama del owner en `_applySessionTimelineProjection` llama a
`_publishCurrentSession()` con ese estado, escribiendo `finished` a Firestore aunque
`_groupCompleted = false`.

### Código actual (~línea 1626):
```dart
    } else if (_machine.state.status != PomodoroStatus.idle &&
        !_pendingPublishAfterSync &&
        _hotSwapPublishedForRevision != session.sessionRevision) {
      _bumpSessionRevision();
      _hotSwapPublishedForRevision = _sessionRevision;
      _publishCurrentSession();
    }
```

### Código nuevo:
```dart
    } else if (_machine.state.status != PomodoroStatus.idle &&
        !_pendingPublishAfterSync &&
        _hotSwapPublishedForRevision != session.sessionRevision) {
      // Do not publish a finished state unless the group is truly completed.
      // During task-to-task transition the machine is transiently finished;
      // a concurrent sync must not race-write that to Firestore.
      if (_machine.state.status == PomodoroStatus.finished && !_groupCompleted) {
        return;
      }
      _bumpSessionRevision();
      _hotSwapPublishedForRevision = _sessionRevision;
      _publishCurrentSession();
    }
```

**Constraints:**
- Solo añadir el guard antes de `_bumpSessionRevision()`.
- No cambiar nada más en `_applySessionTimelineProjection`.

---

## Fix C — Test de regresión específico para BUG-015

Añadir un test en el archivo de tests del ViewModel que ya existe:
`test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
(o el archivo de tests más apropiado según lo que ya exista allí).

### Descripción del test a escribir

**Nombre:** `owner hydration with stale session past task boundary does not publish finished`

**Precondiciones:**
- Account mode.
- Grupo con 2 tareas (task 0: 1 pomodoro 25min; task 1: 1 pomodoro 25min).
- Machine en estado `idle` (simula que venía de mirror mode).
- Session stale: `phaseStartedAt` hace 60 minutos (2× la duración de la tarea 0),
  `status = pomodoroRunning`, `currentTaskIndex = 0`, `currentPomodoro = 1`,
  `totalPomodoros = 1`, `ownerDeviceId = thisDevice`.
- Grupo `status = running`, `actualStartTime = now - 60 min`.

**Ejecutar:**
- Llamar a `_hydrateOwnerSession(staleSession)` (o simular la ingesta vía `syncWithRemoteSession`).

**Asserts:**
1. El estado publicado en el session repository NO tiene `status = finished`.
2. El estado del ViewModel NO es `PomodoroStatus.finished`.
3. El `currentTaskIndex` resultante es consistente con la posición en el grupo (0 o 1, según la timeline).

**Si el comportamiento pre-fix era publicar `finished` en este caso, el test debe
fallar ANTES del fix y pasar DESPUÉS. Documenta eso en el test con un comentario.**

---

## Orden de commits

```
Commit 1: fix(bug-015): guard against transient finished publish during task transition
  Files: lib/presentation/viewmodels/pomodoro_view_model.dart
  Change: Fix B (_applySessionTimelineProjection guard)

Commit 2: fix(bug-015): allow group timeline recovery when session overshoot detected
  Files: lib/presentation/viewmodels/pomodoro_view_model.dart
  Change: Fix A (_applyGroupTimelineProjection skipControlsCheck + _hydrateOwnerSession)

Commit 3: test(bug-015): owner hydration with stale session past task boundary
  Files: test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
         (o el archivo de test correcto según el repo)
  Change: Fix C (nuevo test)
```

---

## Tests a ejecutar antes de devolver a Claude

```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```

Todos deben pasar. Si alguno falla, reportar a Claude con el error exacto antes de entregar.

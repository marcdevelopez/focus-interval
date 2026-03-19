# Codex Handoff — BUG-F25-I

## Branch
`fix-f25-i-postponed-start-drifts-on-cancel`

## Reference commit
`25dcbd0` (docs registration on this branch; develop base: ed65f6f + F25-F merge)

## Regla obligatoria
Lee `CLAUDE.md` secciones 3 y 4 antes de escribir código. Presta atención especial
a AP-3 (recovery paths) y G-2 (change isolation). **Lee también §10 completo —
`codex_handoff.md` es un archivo explícitamente permitido en la carpeta de validación.**

## Overview

Dos commits. El primero en `scheduled_group_coordinator.dart` es el fix real que
detiene el auto-start prematuro. El segundo en `scheduled_group_timing.dart` es
defensa-en-profundidad que protege `resolveEffectiveScheduledStart` durante la
ventana transitoria antes de que la escritura a DB se complete.

---

## Fix 1 — `lib/presentation/viewmodels/scheduled_group_coordinator.dart`

### Por qué es necesario

`_finalizePostponedGroupsIfNeeded` itera grupos scheduled con `postponedAfterGroupId`.
Cuando el anchor está `running`, salta (`continue`). Cuando el anchor está `canceled`,
**no salta** — cae a `resolvePostponedAnchorEnd` que devuelve `anchor.updatedAt`
(la hora de cancelación ≈ "ahora"). El resultado: el postponed group recibe
`scheduledStartTime = ceilToMinute(now)` y es auto-iniciado al minuto siguiente.

### Código actual (líneas 1124–1133)

```dart
      final anchor = findGroupById(groups, anchorId);
      if (anchor == null) {
        updates.add(
          latest.copyWith(postponedAfterGroupId: null, updatedAt: now),
        );
        continue;
      }
      if (anchor.status == TaskRunStatus.running) {
        continue;
      }
      final anchorEnd = resolvePostponedAnchorEnd(
```

### Código reemplazado (insertar después de línea 1133)

```dart
      final anchor = findGroupById(groups, anchorId);
      if (anchor == null) {
        updates.add(
          latest.copyWith(postponedAfterGroupId: null, updatedAt: now),
        );
        continue;
      }
      if (anchor.status == TaskRunStatus.running) {
        continue;
      }
      if (anchor.status == TaskRunStatus.canceled) {
        updates.add(
          latest.copyWith(postponedAfterGroupId: null, updatedAt: now),
        );
        continue;
      }
      final anchorEnd = resolvePostponedAnchorEnd(
```

### Constraints

- **NO tocar `scheduledStartTime`** en el bloque `canceled`. El `copyWith` solo
  actualiza `postponedAfterGroupId` y `updatedAt`. La hora almacenada (22:35) se
  preserva íntegramente.
- El patrón es idéntico al bloque "anchor not found" (líneas 1125–1129). Misma
  semántica: linkage muerto → seccionar, preservar schedule.
- NO aplicar este bloque para `TaskRunStatus.completed`. Un anchor que completó
  normalmente sí debe anclar G2 al final real del anchor. Solo `canceled` rompe la
  promesa del usuario.

---

## Fix 2 — `lib/presentation/utils/scheduled_group_timing.dart`

### Por qué es necesario

`resolveEffectiveScheduledStart` llama a `resolvePostponedAnchorEnd` para calcular
el tiempo efectivo de inicio del postponed group. Hay una ventana transitoria entre
que el Fix 1 escribe a DB y el stream de Firestore propaga la actualización. Durante
ese window, `postponedAfterGroupId` aún está set en el grupo local y el anchor está
`canceled`. Sin esta guardia, `resolveEffectiveScheduledStart` computa `anchorEnd =
anchor.updatedAt = now` y expone el tiempo incorrecto al scheduler y al UI.

### Código actual (líneas 97–104)

```dart
) {
  if (anchor.status == TaskRunStatus.running) {
    return resolveProjectedRunningEnd(
      runningGroup: anchor,
      activeSession: activeSession,
      now: now,
    );
  }
  final effectiveEnd = resolveEffectiveScheduledEnd(
```

### Código reemplazado

```dart
) {
  if (anchor.status == TaskRunStatus.running) {
    return resolveProjectedRunningEnd(
      runningGroup: anchor,
      activeSession: activeSession,
      now: now,
    );
  }
  if (anchor.status == TaskRunStatus.canceled) {
    return null;
  }
  final effectiveEnd = resolveEffectiveScheduledEnd(
```

### Constraints

- Devolver `null` para `canceled` hace que `resolveEffectiveScheduledStart` (línea
  180) devuelva el `scheduledStart` almacenado — exactamente lo que queremos.
- `_finalizePostponedGroupsIfNeeded` también llama a esta función y llega a
  `if (anchorEnd == null) continue;` (línea 1141) — pero con Fix 1 ya habremos
  salido antes vía el nuevo bloque `canceled`. El Fix 2 es redundante en esa ruta
  pero correcto y no causa conflicto.
- NO aplicar para `completed` — mismo razonamiento que Fix 1.

---

## Orden de commits

```
1. fix(f25-i): sever postponed linkage on canceled anchor in coordinator
   → scheduled_group_coordinator.dart únicamente

2. fix(f25-i): return null from resolvePostponedAnchorEnd for canceled anchor
   → scheduled_group_timing.dart únicamente
```

---

## Tests a escribir y ejecutar

### Tests nuevos requeridos

**`test/presentation/utils/scheduled_group_timing_test.dart`** — agregar dentro del
grupo `resolvePostponedAnchorEnd` (o crearlo si no existe como grupo):

1. `resolvePostponedAnchorEnd returns null when anchor is canceled`
   - Crear anchor con `status = TaskRunStatus.canceled`, `updatedAt = now - 1 min`
   - Llamar `resolvePostponedAnchorEnd(anchor: anchor, ...)`
   - Verificar que devuelve `null`

2. `resolveEffectiveScheduledStart returns stored scheduledStart when anchor is canceled`
   - Crear anchor con `status = canceled`, postponed group con `postponedAfterGroupId = anchor.id`
     y `scheduledStartTime = now + 30 min`
   - Llamar `resolveEffectiveScheduledStart(group: postponed, allGroups: [anchor, postponed], ...)`
   - Verificar que devuelve `now + 30 min` (el valor almacenado, no derivado)

**`test/presentation/viewmodels/scheduled_group_coordinator_test.dart`** — agregar
caso de test:

3. `_finalizePostponedGroupsIfNeeded: canceling anchor severs link without changing scheduledStartTime`
   - Setup: anchor `status = canceled`, postponed `status = scheduled`,
     `postponedAfterGroupId = anchor.id`, `scheduledStartTime = now + 60 min`
   - Ejecutar el coordinator con estos grupos
   - Verificar que el postponed group guardado en repo tiene:
     - `postponedAfterGroupId == null`
     - `scheduledStartTime == now + 60 min` (sin cambio)
   - Verificar que NO se dispara auto-start

### Tests de regresión a ejecutar (deben seguir pasando)

```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/utils/scheduled_group_timing_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```

Todos deben pasar antes de devolver a Claude para QA review.

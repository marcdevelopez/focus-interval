# Codex Handoff — IDEA-039: Scheduling Conflict Explainer + Guided Start Suggestions

**Branch:** `feature/idea039-conflict-explainer`
**Reference commit:** `375b1d7`
**Feature folder:** `docs/features/feature_2026_04_02_idea039-conflict-explainer/`

---

## Regla obligatoria

Lee las secciones 3 y 4 de `CLAUDE.md` antes de escribir una sola línea de código.
Este handoff no toca código de sync/session/timer, pero sí comparte helpers de timing
con `scheduled_group_timing.dart`. No toques nada relacionado con `_sessionSub`,
`_sessionMissingWhileRunning`, ni `TimeSyncService`.

---

## Overview

**4 commits en orden estricto:**

1. Extraer helpers de detección de conflictos de `task_list_screen.dart` a un archivo nuevo `lib/presentation/utils/scheduling_conflict_helpers.dart`.
2. Migrar `TaskGroupPlanningScreen` de `StatefulWidget` a `ConsumerStatefulWidget` y conectar los providers necesarios para detección en tiempo real.
3. Implementar Layer 1 (inline indicators) y Layer 2 (modal bloqueante unificado) dentro de `TaskGroupPlanningScreen`.
4. Limpiar `task_list_screen.dart`: eliminar los dos diálogos viejos (`_resolveRunningConflict`, `_resolveScheduledConflict`) y el bloque de detección post-Confirmar que ya no es necesario.

---

## Commit 1 — Extraer helpers de conflicto

**Archivo a crear:** `lib/presentation/utils/scheduling_conflict_helpers.dart`

**Por qué:** La lógica de `_findConflicts` y `_findPreRunConflict` en
`task_list_screen.dart` (líneas 1719–1823) debe ser compartida entre
`TaskListScreen` y `TaskGroupPlanningScreen`. Duplicarla causaría drift.

**Mueve estas funciones exactamente como están, sin modificar su lógica:**

Desde `task_list_screen.dart`:
- `_findConflicts` (línea 1719) → renombrar a `findSchedulingConflicts` (public)
- `_findPreRunConflict` (línea 1777) → renombrar a `findPreRunConflict` (public)
- `_overlaps` (línea 1825) → renombrar a `schedulingOverlaps` (public)
- El enum `_PreRunConflictType` → renombrar a `PreRunConflictType` (public)
- La clase `_GroupConflicts` → renombrar a `GroupConflicts` (public, con campos `running` y `scheduled` públicos)

**Firma del archivo resultante:**

```dart
// lib/presentation/utils/scheduling_conflict_helpers.dart

import '../../data/models/pomodoro_session.dart';
import '../../data/models/task_run_group.dart';
import 'scheduled_group_timing.dart';

enum PreRunConflictType { running, scheduled }

class GroupConflicts {
  final List<TaskRunGroup> running;
  final List<TaskRunGroup> scheduled;
  const GroupConflicts({required this.running, required this.scheduled});
  bool get isEmpty => running.isEmpty && scheduled.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

bool schedulingOverlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) { ... }

GroupConflicts findSchedulingConflicts(
  List<TaskRunGroup> groups, {
  required DateTime newStart,
  required DateTime newEnd,
  required bool includeRunningAlways,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) { ... }

PreRunConflictType? findPreRunConflict(
  List<TaskRunGroup> groups, {
  required DateTime preRunStart,
  required DateTime scheduledStart,
  required PomodoroSession? activeSession,
  required DateTime now,
  required int? fallbackNoticeMinutes,
}) { ... }
```

**IMPORTANTE:** El parámetro `_noticeFallbackMinutes` en `task_list_screen.dart`
es un campo de instancia. Al moverlo al helper, pasa a ser un parámetro nombrado
`fallbackNoticeMinutes` en cada función.

**Después del commit 1:** actualiza `task_list_screen.dart` para que llame a las
funciones públicas del helper en lugar de las privadas. Elimina las funciones
privadas, el enum privado y la clase privada del archivo. El comportamiento
observable debe ser **idéntico** — este commit no cambia ningún flujo de usuario.

**Tests a pasar después de este commit:**
```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/utils/scheduled_group_timing_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```
No deben romperse. No hay tests nuevos en este commit.

---

## Commit 2 — Migrar TaskGroupPlanningScreen a ConsumerStatefulWidget

**Archivo a modificar:** `lib/presentation/screens/task_group_planning_screen.dart`

**Por qué:** Plan Group necesita acceso a `taskRunGroupStreamProvider`,
`activePomodoroSessionProvider` y `preRunNoticeMinutesProvider` en tiempo real
para evaluar conflictos mientras el usuario interactúa.

**Cambios exactos:**

1. Cambiar `StatefulWidget` → `ConsumerStatefulWidget`.
2. Cambiar `State<TaskGroupPlanningScreen>` → `ConsumerState<TaskGroupPlanningScreen>`.
3. En `build()`, añadir las tres lecturas de provider (ver abajo).
4. Eliminar la importación de `SharedPreferences` si ya no hace falta (NO la elimines si sigue usándose para `_infoSeenKey`, `_shiftNoticeKey`, `_noticeClampKey` — esas siguen igual).

**Código a añadir en `build()`, antes de `return Scaffold(...)`:**

```dart
final groupsAsync = ref.watch(taskRunGroupStreamProvider);
final allGroups = groupsAsync.value ?? const <TaskRunGroup>[];
final activeSession = ref.watch(activePomodoroSessionProvider);
final noticeFallbackMinutes = ref
    .watch(preRunNoticeMinutesProvider)
    .maybeWhen(data: (v) => v, orElse: () => null);
```

**Añadir imports necesarios:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../data/models/task_run_group.dart';
import '../../data/models/pomodoro_session.dart';
```

**Constraints:**
- No toques ningún método existente en este commit.
- No cambies ningún comportamiento observable.
- Este commit solo hace la migración estructural.

**Tests a pasar:** mismo bloque que Commit 1. No deben romperse.

---

## Commit 3 — Implementar Layer 1 (inline) y Layer 2 (modal unificado)

**Archivos a modificar:**
- `lib/presentation/screens/task_group_planning_screen.dart` (cambios principales)

### 3a — Modelo de estado de conflicto en tiempo real

Añade estos campos al estado:

```dart
// Conflicts detectados en tiempo real contra la selección actual
GroupConflicts _currentConflicts = const GroupConflicts(running: [], scheduled: []);

// Acumulador transaccional: grupos marcados para cancelar/eliminar en el modal.
// Solo se aplican al confirmar el plan nuevo exitosamente.
// Se resetea si el usuario cancela o cierra el modal sin confirmar el plan.
final Set<String> _pendingCancelIds = {};   // grupos running a cancelar
final Set<String> _pendingDeleteIds = {};   // grupos scheduled a eliminar
```

### 3b — Método de re-evaluación de conflictos

Añade este método privado. Se llama en dos momentos: desde `build()` (reactivo
al stream) y desde el ticker de 1s existente (para el notice auto-clamp).

```dart
GroupConflicts _evaluateConflicts({
  required List<TaskRunGroup> allGroups,
  required PomodoroSession? activeSession,
  required int? fallbackNoticeMinutes,
}) {
  final preview = _buildPlanPreview();
  if (_selected == TaskGroupPlanOption.startNow) {
    return const GroupConflicts(running: [], scheduled: []);
  }
  final start = preview.scheduledStart;
  if (start == null) return const GroupConflicts(running: [], scheduled: []);
  final end = start.add(Duration(seconds: preview.totalDurationSeconds));
  final now = DateTime.now();

  // Filtrar grupos que ya están en los acumuladores transaccionales —
  // se tratan como si ya no existieran para el cálculo inline.
  final effectiveGroups = allGroups
      .where((g) => !_pendingCancelIds.contains(g.id) && !_pendingDeleteIds.contains(g.id))
      .toList();

  return findSchedulingConflicts(
    effectiveGroups,
    newStart: start,
    newEnd: end,
    includeRunningAlways: false,   // scheduled siempre excluye start-now
    activeSession: activeSession,
    now: now,
    fallbackNoticeMinutes: fallbackNoticeMinutes,
  );
}
```

### 3c — Case A: auto-clamp de notice (pre-run only)

El auto-clamp ya existe en `_applyNoticeSuggestion()`. Asegúrate de que ese método
**no** muestres indicador de error cuando el único conflicto es de pre-run. El
flujo de Case A no cambia funcionalmente — solo se confirma que el clamp silencioso
ya está implementado y que `_canConfirm` no lo bloquea.

Verificar en `_canConfirm`:
```dart
bool _canConfirm(_PlanPreview preview) {
  if (!preview.isValid) return false;
  if (_selected == TaskGroupPlanOption.startNow) return true;
  if (preview.scheduledStart == null) return false;
  // Confirmar deshabilitado SOLO si hay conflicto de ejecución (Case B).
  // Case A (pre-run only) no bloquea Confirmar.
  return _currentConflicts.isEmpty;
}
```

### 3d — Layer 1: indicadores inline

En `build()`, después de calcular `_currentConflicts` (llamar a `_evaluateConflicts`
con los valores del stream leídos en el paso 2), actualizar `_currentConflicts` via
`WidgetsBinding.instance.addPostFrameCallback` o directamente si el método es
llamado dentro de un setState del ticker.

**IMPORTANTE — cómo actualizar `_currentConflicts` desde `build()`:**
No puedes llamar `setState()` desde `build()`. El patrón correcto es calcular
los conflictos en `build()` directamente a partir de los valores del stream y
pasarlos como parámetro local, sin asignarlos a `_currentConflicts` dentro de
`build()`. En su lugar, usa `_currentConflicts` como cache que se actualiza
desde el ticker y desde un `ref.listen` en `build()`:

```dart
// En build(), después de leer los providers:
ref.listen(taskRunGroupStreamProvider, (_, next) {
  if (!mounted) return;
  final groups = next.value ?? const <TaskRunGroup>[];
  final conflicts = _evaluateConflicts(
    allGroups: groups,
    activeSession: activeSession,
    fallbackNoticeMinutes: noticeFallbackMinutes,
  );
  if (mounted) setState(() => _currentConflicts = conflicts);
});
```

Y también actualizar en el ticker existente:
```dart
_noticeNowTicker = Timer.periodic(const Duration(seconds: 1), (_) {
  if (!mounted) return;
  setState(() {
    _noticeNow = DateTime.now();
    _applyStartAutoUpdate();
    _applyNoticeSuggestion();
    // Re-evaluar conflictos cada segundo para detectar grupos running que terminan
    _currentConflicts = _evaluateConflicts(
      allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
      activeSession: ref.read(activePomodoroSessionProvider),
      fallbackNoticeMinutes: ref.read(preRunNoticeMinutesProvider).value,
    );
  });
});
```

**Widget de chips inline:**

Añade este widget después del footer de la opción seleccionada (debajo del
`_SchedulePickerRow` activo) si `_currentConflicts.isNotEmpty`:

```dart
if (_currentConflicts.isNotEmpty) ...[
  const SizedBox(height: 8),
  _ConflictInlineIndicator(conflicts: _currentConflicts),
],
```

`_ConflictInlineIndicator` es un widget privado en el mismo archivo:

```dart
class _ConflictInlineIndicator extends StatelessWidget {
  final GroupConflicts conflicts;
  const _ConflictInlineIndicator({required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final all = [
      ...conflicts.running.map((g) => (group: g, isRunning: true)),
      ...conflicts.scheduled.map((g) => (group: g, isRunning: false)),
    ]..sort((a, b) {
        final aTime = a.group.scheduledStartTime ?? a.group.createdAt;
        final bTime = b.group.scheduledStartTime ?? b.group.createdAt;
        return aTime.compareTo(bTime);
      });

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduling conflict',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: all.map((entry) {
              final name = entry.group.tasks.isNotEmpty
                  ? entry.group.tasks.first.name
                  : 'Task group';
              final fmt = DateFormat('HH:mm');
              final start = entry.group.scheduledStartTime ??
                  entry.group.actualStartTime ??
                  entry.group.createdAt;
              final end = entry.group.theoreticalEndTime;
              final badge = entry.isRunning ? 'Running' : 'Scheduled';
              return Chip(
                label: Text(
                  '$name · ${fmt.format(start)}–${fmt.format(end)} · $badge',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

### 3e — Layer 2: modal bloqueante unificado

**Primero: ampliar `TaskGroupPlanningResult`** para llevar los acumuladores
transaccionales. Los grupos NO se modifican en Firestore dentro de Plan Group —
solo se pasan al llamador (`task_list_screen.dart`) para que los aplique
**después** de guardar el grupo nuevo exitosamente.

```dart
class TaskGroupPlanningResult {
  final TaskGroupPlanOption option;
  final DateTime? scheduledStart;
  final List<TaskRunItem> items;
  final int noticeMinutes;
  // IDs de grupos running a cancelar (solo si el nuevo plan se guarda OK)
  final Set<String> pendingCancelIds;
  // IDs de grupos scheduled a eliminar (solo si el nuevo plan se guarda OK)
  final Set<String> pendingDeleteIds;

  const TaskGroupPlanningResult({
    required this.option,
    required this.items,
    required this.noticeMinutes,
    this.scheduledStart,
    this.pendingCancelIds = const {},
    this.pendingDeleteIds = const {},
  });
}
```

**Modifica `_handleConfirm`** para propagar los acumuladores sin aplicarlos:

```dart
Future<void> _handleConfirm(_PlanPreview preview) async {
  // Guardia de carrera: re-evaluar en el momento exacto del tap
  // (puede haber pasado tiempo entre el último tick y este tap)
  final recheck = _evaluateConflicts(
    allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
    activeSession: ref.read(activePomodoroSessionProvider),
    fallbackNoticeMinutes: ref.read(preRunNoticeMinutesProvider).value,
  );

  if (recheck.isNotEmpty) {
    setState(() => _currentConflicts = recheck);
    final resolved = await _showConflictModal(recheck, preview);
    if (!resolved || !mounted) return;
  }

  final scheduledStart = _selected == TaskGroupPlanOption.startNow
      ? null
      : preview.scheduledStart;

  // NO aplicar destructive actions aquí. Pasarlas al llamador para que
  // las aplique DESPUÉS de guardar el grupo nuevo.
  Navigator.of(context).pop(
    TaskGroupPlanningResult(
      option: _selected,
      items: preview.items,
      noticeMinutes: _noticeMinutes,
      scheduledStart: scheduledStart,
      pendingCancelIds: Set<String>.unmodifiable(_pendingCancelIds),
      pendingDeleteIds: Set<String>.unmodifiable(_pendingDeleteIds),
    ),
  );
}
```

**Modal `_showConflictModal`:**

```dart
Future<bool> _showConflictModal(
  GroupConflicts conflicts,
  _PlanPreview preview,
) async {
  // Estado local del modal: qué checkboxes están marcados
  final checkedIds = <String>{
    ...conflicts.running.map((g) => g.id),
    ...conflicts.scheduled.map((g) => g.id),
  };

  final fmt = DateFormat('HH:mm');
  final previewStart = preview.scheduledStart;
  final previewEnd = previewStart == null
      ? null
      : previewStart.add(Duration(seconds: preview.totalDurationSeconds));
  final rangeLabel = (previewStart != null && previewEnd != null)
      ? '${fmt.format(previewStart)}–${fmt.format(previewEnd)}'
      : '--:--';

  // Lista unificada ordenada por hora de inicio
  final allConflicts = [
    ...conflicts.running.map((g) => (group: g, isRunning: true)),
    ...conflicts.scheduled.map((g) => (group: g, isRunning: false)),
  ]..sort((a, b) {
      final aTime = a.group.scheduledStartTime ?? a.group.createdAt;
      final bTime = b.group.scheduledStartTime ?? b.group.createdAt;
      return aTime.compareTo(bTime);
    });

  final result = await showDialog<_ConflictModalResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final checkedCount = checkedIds.length;
        return AlertDialog(
          title: const Text('Scheduling conflict'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your plan ($rangeLabel) conflicts with:'),
                const SizedBox(height: 12),
                ...allConflicts.map((entry) {
                  final g = entry.group;
                  final name = g.tasks.isNotEmpty
                      ? g.tasks.first.name
                      : 'Task group';
                  final start =
                      g.scheduledStartTime ?? g.actualStartTime ?? g.createdAt;
                  final end = g.theoreticalEndTime;
                  final badge = entry.isRunning ? 'Running' : 'Scheduled';
                  return CheckboxListTile(
                    value: checkedIds.contains(g.id),
                    onChanged: (v) {
                      setModalState(() {
                        if (v == true) {
                          checkedIds.add(g.id);
                        } else {
                          checkedIds.remove(g.id);
                        }
                      });
                    },
                    title: Text(name),
                    subtitle: Text(
                      '${fmt.format(start)}–${fmt.format(end)} · $badge',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(const _ConflictModalResult.cancelled()),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(const _ConflictModalResult.changeTime()),
              child: const Text('Change time'),
            ),
            ElevatedButton(
              onPressed: checkedCount > 0
                  ? () => Navigator.of(context).pop(
                        _ConflictModalResult.delete(
                          Set<String>.from(checkedIds),
                        ),
                      )
                  : null,
              child: Text('Delete ($checkedCount)'),
            ),
          ],
        );
      },
    ),
  );

  if (result == null || result.isCancelled) return false;

  if (result.isChangeTime) {
    // Abre el selector del modo activo — NO forzar scheduleStart, respetar
    // el modo elegido por el usuario (Range, Total o Start).
    await _selectOption(_selected);
    return false;   // vuelve a Plan Group con la nueva hora; no confirma aún
  }

  if (result.isDelete) {
    // Acumular en los sets transaccionales, NO aplicar todavía a Firestore
    for (final entry in allConflicts) {
      if (result.selectedIds.contains(entry.group.id)) {
        if (entry.isRunning) {
          _pendingCancelIds.add(entry.group.id);
        } else {
          _pendingDeleteIds.add(entry.group.id);
        }
      }
    }

    // Re-evaluar conflictos tras las marcas transaccionales
    final remaining = _evaluateConflicts(
      allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
      activeSession: ref.read(activePomodoroSessionProvider),
      fallbackNoticeMinutes: ref.read(preRunNoticeMinutesProvider).value,
    );
    setState(() => _currentConflicts = remaining);

    // Si aún quedan conflictos: volver a Plan Group con chips actualizados
    if (remaining.isNotEmpty) return false;

    // Sin conflictos: proceder
    return true;
  }

  return false;
}
```

**Clase auxiliar `_ConflictModalResult`:**

```dart
class _ConflictModalResult {
  final _ConflictModalAction action;
  final Set<String> selectedIds;

  const _ConflictModalResult._({required this.action, this.selectedIds = const {}});

  const _ConflictModalResult.cancelled()
      : this._(action: _ConflictModalAction.cancelled);
  const _ConflictModalResult.changeTime()
      : this._(action: _ConflictModalAction.changeTime);
  _ConflictModalResult.delete(Set<String> ids)
      : this._(action: _ConflictModalAction.delete, selectedIds: ids);

  bool get isCancelled => action == _ConflictModalAction.cancelled;
  bool get isChangeTime => action == _ConflictModalAction.changeTime;
  bool get isDelete => action == _ConflictModalAction.delete;
}

enum _ConflictModalAction { cancelled, changeTime, delete }
```

**Imports adicionales requeridos en `task_group_planning_screen.dart`:**

```dart
import '../utils/scheduling_conflict_helpers.dart';
```

**Constraints críticos del Commit 3:**
- Plan Group NO accede al repo de grupos. No hay escrituras a Firestore en este archivo.
- `_pendingCancelIds` y `_pendingDeleteIds` son acumuladores en memoria. Si el usuario cancela Plan Group o cierra por la X, se destruyen con el widget sin efecto.
- La guardia de carrera en `_handleConfirm` re-evalúa contra el stream actual, no contra `_currentConflicts` (que puede tener 1s de retraso por el ticker).
- `_canConfirm` llama a `_currentConflicts.isEmpty` — nunca a `_evaluateConflicts` directamente (eso es costoso por frame).
- `TaskGroupPlanningResult` ahora tiene `pendingCancelIds` y `pendingDeleteIds`. Los campos son opcionales con default `const {}` para no romper llamadores que no los usan.

---

## Commit 4 — Limpiar task_list_screen.dart y aplicar acumuladores transaccionales

**Archivo a modificar:** `lib/presentation/screens/task_list_screen.dart`

**Eliminar:**
1. Los métodos privados `_findConflicts`, `_findPreRunConflict`, `_overlaps` (ahora están en el helper).
2. El enum privado `_PreRunConflictType`.
3. La clase privada `_GroupConflicts`.
4. Los métodos `_resolveRunningConflict` (línea 1836) y `_resolveScheduledConflict` (línea 1874).
5. El bloque que llama a `_loadGroupsForConflict`, `_findPreRunConflict`, `_findConflicts`, `_resolveRunningConflict`, `_resolveScheduledConflict` — líneas ~1535–1611.
6. `_loadGroupsForConflict` si no tiene otros llamadores.

**Añadir: aplicación de acumuladores transaccionales tras el save exitoso.**

Localiza el punto donde el grupo nuevo se guarda (líneas ~1613–1680). El save ocurre
con `await repo.save(group)` o equivalente. Inmediatamente después del save exitoso,
antes del `if (!context.mounted) return;` que cierra el flujo, añade:

```dart
// Aplicar destructive actions transaccionales SOLO tras save exitoso del grupo nuevo.
// Si el save falló, el flujo ya habrá hecho return por el catch — no llegamos aquí.
await _applyPlanningDestructiveActions(
  planningResult: planningResult,
  repo: repo,
  allGroups: ref.read(taskRunGroupStreamProvider).value ?? const [],
);
```

Añade este método privado al archivo:

```dart
Future<void> _applyPlanningDestructiveActions({
  required TaskGroupPlanningResult planningResult,
  required TaskRunGroupRepository repo,
  required List<TaskRunGroup> allGroups,
}) async {
  if (planningResult.pendingCancelIds.isEmpty &&
      planningResult.pendingDeleteIds.isEmpty) return;
  final now = DateTime.now();
  for (final group in allGroups) {
    if (planningResult.pendingCancelIds.contains(group.id)) {
      await repo.save(
        group.copyWith(
          status: TaskRunStatus.canceled,
          canceledReason: TaskRunCanceledReason.user,
          updatedAt: now,
        ),
      );
    } else if (planningResult.pendingDeleteIds.contains(group.id)) {
      await repo.delete(group.id);
    }
  }
}
```

**Mantener intacto:**
- La función `_showSnackBar` — sigue usándose.
- Todo el flujo de construcción y guardado del grupo (líneas ~1613–1680).

**Verificar:** tras los cambios, el flujo del método que procesa el resultado
del planning queda: validar sesión activa → calcular duraciones → construir grupo
→ `await repo.save(group)` → `await _applyPlanningDestructiveActions(...)` →
resto del flujo. Sin fetch de grupos previo, sin resolución de conflictos previa.

**Comportamiento en caso de fallo parcial en `_applyPlanningDestructiveActions`:**
Este flujo es "best-effort transaccional", no atómico. Si `repo.save(group)` falla,
el catch interrumpe el flujo antes de `_applyPlanningDestructiveActions` — los grupos
conflictivos se conservan (caso seguro). Si `_applyPlanningDestructiveActions` falla
a mitad (ej. cancela el grupo A pero falla al eliminar el grupo B), el estado quedará
parcialmente modificado. Este riesgo es aceptable por diseño: los grupos que ya se
cancelaron/eliminaron tenían conflicto real con el plan nuevo que acaba de guardarse,
y el usuario los marcó explícitamente para eliminar. No hay que añadir rollback.
Documéntalo con un comentario en el código junto a la llamada.

**Tests a pasar después del Commit 4:**
```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/utils/scheduled_group_timing_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```

---

## Resumen de archivos modificados

| Commit | Archivos |
|--------|----------|
| 1 | `lib/presentation/utils/scheduling_conflict_helpers.dart` (nuevo), `lib/presentation/screens/task_list_screen.dart` (refactor) |
| 2 | `lib/presentation/screens/task_group_planning_screen.dart` (migración ConsumerStatefulWidget) |
| 3 | `lib/presentation/screens/task_group_planning_screen.dart` (Layer 1 + Layer 2) |
| 4 | `lib/presentation/screens/task_list_screen.dart` (limpieza) |

---

## Mensajes de commit (plantillas)

```
refactor(conflicts): extract conflict detection helpers to shared utility
feat(planning): migrate TaskGroupPlanningScreen to ConsumerStatefulWidget
feat(idea039): add inline conflict indicators and unified conflict modal to Plan Group
refactor(task-list): remove legacy conflict dialogs superseded by Plan Group flow
```

---

## Tests a ejecutar antes de entregar a Claude para QA

```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/utils/scheduled_group_timing_test.dart
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart
```

Todos deben pasar. No hay tests nuevos en este handoff — los tests de IDEA-039
se añadirán en un handoff separado tras la QA review de Claude.

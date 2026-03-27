# Codex Handoff — BUG-016 Patch 1: Correctness fix (baseline freeze + blur overwrite)

## Branch
`fix/bug016-weight-edit-preview-modes`

## Reference commit
`fa907c9`

## Regla obligatoria
Leer `CLAUDE.md` secciones 3 y 4 antes de escribir cualquier línea de código.

---

## Overview

Un solo archivo modificado: `lib/presentation/screens/task_editor_screen.dart`.
Dos commits en orden. No tocar ningún otro archivo.

Este patch NO implementa el preview UI de dos modos (Fixed/Flexible total) — eso es un
paso futuro. Solo corrige el comportamiento incorrecto actual: el campo Task weight (%)
se sobreescribe con un valor equivocado al perder el foco, y la redistribución usa una
baseline contaminada por los keystrokes intermedios.

---

## Diagnóstico confirmado (Claude verificó el código fuente)

### Defecto 1 — Baseline contaminada por keystrokes

`weightScopeTasks` se pasa al método `_weightRow()` desde `build()` (línea 632),
construido a partir de `ref.watch(taskEditorProvider)` (línea 392). Cada keystroke en
el campo llama `_update(task.copyWith(totalPomodoros: newPomodoros))` (línea 2106), que
actualiza `taskEditorProvider`, dispara un rebuild, y en ese rebuild `weightScopeTasks`
se reconstruye con el valor intermedio. El siguiente keystroke usa una baseline ya
contaminada.

No existe ningún "baseline freeze" en el código actual. Solo existe
`_weightPercentStartValue` (línea 68) que guarda el porcentaje inicial como `int`, pero
nunca la lista de tareas.

### Defecto 2 — Overwrite del campo al perder foco (causa exacta del 69→43)

En el focus listener (línea 97), al perder foco se llama `_syncWeightPercentFromTask()`
(línea 1366). Esa función lee `ref.read(taskEditorProvider)` (la tarea editada con los
pomodoros ya mutados por keystrokes) pero `_currentWeightPercent` (línea 1243) lee
`taskListProvider` para las demás tareas — que aún tienen sus valores ORIGINALES porque
`_pendingRedistribution` no se aplica hasta Save (línea 316). El cálculo combina estado
mixto: G3 con pomodoros modificados + G1/G2/G4 con pomodoros originales →
`normalizeTaskWeightPercents` devuelve 43% (el porcentaje de G3 sobre el total
no-redistribuido), no el 69% que el usuario ingresó.

El mismo problema afecta `_maybeSyncWeightPercent()` (línea 1357), que se llama desde
`build()` en cada rebuild posterior al blur y puede sobreescribir el campo con el mismo
valor contaminado.

---

## Cambios — Commit 1: Freeze del baseline al ganar foco

**Archivo:** `lib/presentation/screens/task_editor_screen.dart`

### Cambio 1A — Declarar el campo `_weightScopeBaseline`

Agregar el nuevo campo justo después de la línea 73 (`bool _weightPercentEdited = false;`):

```dart
// CÓDIGO ACTUAL (línea 73):
  bool _weightPercentEdited = false;

// REEMPLAZAR CON:
  bool _weightPercentEdited = false;
  List<PomodoroTask>? _weightScopeBaseline;
```

### Cambio 1B — Capturar el baseline y limpiar `_lastResultWeightPercent` al ganar foco

El bloque completo del focus listener (líneas 97–107):

```dart
// CÓDIGO ACTUAL:
    _weightPercentFocus.addListener(() {
      if (_weightPercentFocus.hasFocus) {
        _weightPercentStartValue =
            int.tryParse(_weightPercentCtrl.text.trim());
        _weightPercentEdited = false;
        _lastWeightNoticeKey = null;
        return;
      }
      _maybeShowWeightPrecisionNotice();
      _syncWeightPercentFromTask();
    });

// REEMPLAZAR CON:
    _weightPercentFocus.addListener(() {
      if (_weightPercentFocus.hasFocus) {
        // Freeze the task-list baseline at focus-gain time.
        // This prevents per-keystroke rebuild from contaminating the scope
        // used for weight redistribution calculations.
        final focusTask = ref.read(taskEditorProvider);
        if (focusTask != null) {
          final selectedIds = ref.read(taskSelectionProvider);
          final tasks =
              ref.read(taskListProvider).asData?.value ?? const [];
          _weightScopeBaseline = _selectedTasksForWeight(
            orderedTasks: _orderTasks(tasks),
            selectedIds: selectedIds,
            edited: focusTask,
          );
        }
        _lastResultWeightPercent = null;
        _weightPercentStartValue =
            int.tryParse(_weightPercentCtrl.text.trim());
        _weightPercentEdited = false;
        _lastWeightNoticeKey = null;
        return;
      }
      _maybeShowWeightPrecisionNotice();
      _syncWeightPercentFromTask();
    });
```

### Cambio 1C — Usar el baseline congelado en el call site de `_weightRow`

Línea 631–637 (dentro de `build()`, el bloque que llama `_weightRow`):

```dart
// CÓDIGO ACTUAL:
              _weightRow(
                task: task,
                weightScopeTasks: selectedWeightTasks,
                showWeightPercent: showWeightField,
                onInfoTap: () =>
                    _showWeightInfoDialog(includeDontShowAgain: false),
              ),

// REEMPLAZAR CON:
              _weightRow(
                task: task,
                weightScopeTasks: _weightScopeBaseline ?? selectedWeightTasks,
                showWeightPercent: showWeightField,
                onInfoTap: () =>
                    _showWeightInfoDialog(includeDontShowAgain: false),
              ),
```

**Invariante a mantener:** No tocar el cuerpo de `_weightRow` ni el método
`redistributeWeightPercent` del ViewModel. El único cambio es qué lista se pasa como
argumento.

---

## Cambios — Commit 2: Fix del overwrite al perder foco

**Archivo:** `lib/presentation/screens/task_editor_screen.dart`

### Cambio 2A — `_maybeSyncWeightPercent`: guard contra overwrite post-edit

Líneas 1357–1364:

```dart
// CÓDIGO ACTUAL:
  void _maybeSyncWeightPercent(int percent) {
    if (_syncingWeight) return;
    if (_weightPercentFocus.hasFocus) return;
    final current = _weightPercentCtrl.text.trim();
    final target = percent.toString();
    if (current == target) return;
    _weightPercentCtrl.text = target;
  }

// REEMPLAZAR CON:
  void _maybeSyncWeightPercent(int percent) {
    if (_syncingWeight) return;
    if (_weightPercentFocus.hasFocus) return;
    if (_lastResultWeightPercent != null) return;
    final current = _weightPercentCtrl.text.trim();
    final target = percent.toString();
    if (current == target) return;
    _weightPercentCtrl.text = target;
  }
```

### Cambio 2B — `_syncWeightPercentFromTask`: usar el resultado de redistribución, no el estado mixto

Líneas 1366–1372:

```dart
// CÓDIGO ACTUAL:
  void _syncWeightPercentFromTask() {
    final task = ref.read(taskEditorProvider);
    if (task == null) return;
    final percent = _currentWeightPercent(task);
    if (percent == null) return;
    _weightPercentCtrl.text = percent.toString();
  }

// REEMPLAZAR CON:
  void _syncWeightPercentFromTask() {
    // If the user edited the weight field this focus cycle, show the actual
    // redistribution result instead of recomputing from mixed provider state
    // (edited task updated per-keystroke, other tasks still at original values
    // in taskListProvider until Save applies _pendingRedistribution).
    if (_lastResultWeightPercent != null) {
      _weightPercentCtrl.text = _lastResultWeightPercent.toString();
      return;
    }
    final task = ref.read(taskEditorProvider);
    if (task == null) return;
    final percent = _currentWeightPercent(task);
    if (percent == null) return;
    _weightPercentCtrl.text = percent.toString();
  }
```

### Cambio 2C — Limpiar `_weightScopeBaseline` y `_lastResultWeightPercent` en todos los reset points

`_pendingRedistribution` se limpia en 5 lugares. En cada uno, agregar las dos asignaciones
`null` adicionales. Los cambios son idénticos en estructura — agregar dos líneas después de
`_pendingRedistribution = null`.

**Sitio 1 — línea 316** (dentro de `_handleSave`, after applying redistribution):
```dart
// CÓDIGO ACTUAL:
      _pendingRedistribution = null;
    }
    return true;

// REEMPLAZAR CON:
      _pendingRedistribution = null;
      _weightScopeBaseline = null;
      _lastResultWeightPercent = null;
    }
    return true;
```

**Sitio 2 — línea 356** (dentro de `_handleDiscard`):
```dart
// CÓDIGO ACTUAL:
    _pendingRedistribution = null;
    ref.read(taskEditorProvider.notifier).update(baseline);

// REEMPLAZAR CON:
    _pendingRedistribution = null;
    _weightScopeBaseline = null;
    _lastResultWeightPercent = null;
    ref.read(taskEditorProvider.notifier).update(baseline);
```

**Sitio 3 — línea 649** (dentro de pomodoro duration `onChanged`):
```dart
// CÓDIGO ACTUAL:
                _pendingRedistribution = null;
                final pomodoroGuidance = buildPomodoroDurationGuidance(

// REEMPLAZAR CON:
                _pendingRedistribution = null;
                _weightScopeBaseline = null;
                _lastResultWeightPercent = null;
                final pomodoroGuidance = buildPomodoroDurationGuidance(
```

**Sitio 4 — línea 1034** (dentro de `_syncControllers`):
```dart
// CÓDIGO ACTUAL:
    _pendingRedistribution = null;
    _loadedTaskId = task.id;

// REEMPLAZAR CON:
    _pendingRedistribution = null;
    _weightScopeBaseline = null;
    _lastResultWeightPercent = null;
    _loadedTaskId = task.id;
```

**Sitio 5 — línea 2029** (dentro de Total pomodoros `onChanged` en `_weightRow`):
```dart
// CÓDIGO ACTUAL:
          _pendingRedistribution = null;
          _update(task.copyWith(totalPomodoros: v));

// REEMPLAZAR CON:
          _pendingRedistribution = null;
          _weightScopeBaseline = null;
          _lastResultWeightPercent = null;
          _update(task.copyWith(totalPomodoros: v));
```

**Razón de este cambio:** `_lastResultWeightPercent != null` actúa como lock del campo
después de un edit. Limpiarlo en estos puntos asegura que cuando el usuario cambia el
total de pomodoros directamente, o cuando se guarda/descarta, el campo vuelve a sincronizar
normalmente en el siguiente rebuild.

---

## Orden de commits

```
Commit 1: fix(bug016): freeze weight baseline at focus-gain to prevent per-keystroke contamination
Commit 2: fix(bug016): use redistribution result on blur instead of mixed-state recomputation
```

No agrupar los dos commits en uno. Si uno causa regresión, deben ser revertibles
individualmente.

---

## Constraints — NO tocar

- No modificar `redistributeWeightPercent` ni ningún método en `task_editor_view_model.dart`.
- No modificar la lógica de `_currentWeightPercent` ni `_computeWeightPercentFromRedistribution`.
- No cambiar el comportamiento del snackbar de precisión (`_maybeShowWeightPrecisionNotice`).
- No agregar ningún campo nuevo más allá de `_weightScopeBaseline`.
- No cambiar la firma de `_weightRow`.
- No modificar el flujo de Save ni el flujo de Apply redistribution.

---

## Tests a ejecutar antes de entregar a Claude para QA

```bash
flutter analyze
flutter test test/presentation/viewmodels/task_editor_view_model_test.dart
flutter test test/domain/task_weighting_test.dart
```

Ambos tests deben pasar sin modificaciones. Si alguno falla, reportar a Claude antes
de continuar — NO ajustar los tests para que pasen.

La verificación de comportamiento en device es responsabilidad de Claude QA + validación
del usuario (los unit tests no cubren el blur-time behavior del State, que está en la
capa de Screen).

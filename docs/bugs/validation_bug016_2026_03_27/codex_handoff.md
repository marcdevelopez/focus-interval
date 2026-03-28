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

---

# Codex Handoff — BUG-016 Patch 2: Preview sheet UX

## Branch
`fix/bug016-weight-edit-preview-modes`

## Reference commit
`3f534e8` (last docs-only commit; Patch 1 code is at `8bad479`)

## Regla obligatoria
Leer `CLAUDE.md` secciones 3 y 4 antes de escribir cualquier línea de código.
Todas las decisiones de diseño UX están cerradas en `docs/bugs/bug_log.md` BUG-016
(decisiones a–p) y `docs/specs.md` (preview sheet specification). No tomar ninguna
decisión arquitectural o de UX sin aprobación de Claude.

---

## Overview

Cuatro archivos, cuatro commits en orden. Patch 2 reemplaza el flujo de edición
inline per-keystroke por una preview sheet dedicada. Los campos `Task weight (%)` y
`Total pomodoros` en el editor dejan de ser campos editables y pasan a ser tap targets
de solo lectura que abren la sheet.

Archivos en orden de commits:
1. `lib/presentation/viewmodels/task_editor_view_model.dart` — enum + nuevos métodos
2. `lib/presentation/screens/task_weight_preview_sheet.dart` — nuevo widget (archivo nuevo)
3. `lib/presentation/screens/task_editor_screen.dart` — eliminar maquinaria Patch 1, convertir campos a tap targets, integrar sheet
4. Tests — `task_editor_view_model_test.dart` + `task_weighting_test.dart`

---

## Commit 1 — ViewModel: WeightEditMode + modos en redistributeWeightPercent + redistributeTotalPomodoros

**Archivo:** `lib/presentation/viewmodels/task_editor_view_model.dart`

### Cambio 1A — Agregar enum `WeightEditMode`

Agregar después de los enums existentes (después de línea 28, antes de `class SoundPickResult`):

```dart
enum WeightEditMode { fixed, flexible }
```

### Cambio 1B — Agregar parámetro `mode` a `redistributeWeightPercent`

Firma actual (línea 240):
```dart
Map<String, int> redistributeWeightPercent({
  required PomodoroTask edited,
  required int targetPercent,
  required List<PomodoroTask> tasks,
})
```

Nueva firma (agregar `mode` con default `fixed` para backwards compat con Patch 1):
```dart
Map<String, int> redistributeWeightPercent({
  required PomodoroTask edited,
  required int targetPercent,
  required List<PomodoroTask> tasks,
  WeightEditMode mode = WeightEditMode.fixed,
})
```

Cuerpo actualizado — añadir despacho por modo al final de la validación de baseline,
antes de llamar `_redistributeFromBaseline`:

```dart
// CÓDIGO ACTUAL (líneas 258–263):
    return _redistributeFromBaseline(
      edited: edited,
      targetPercent: targetPercent,
      baselineTasks: tasks,
    );
  }

// REEMPLAZAR CON:
    if (mode == WeightEditMode.flexible) {
      return _redistributeFlexible(
        edited: edited,
        targetPercent: targetPercent,
        baselineTasks: tasks,
      );
    }
    return _redistributeFromBaseline(
      edited: edited,
      targetPercent: targetPercent,
      baselineTasks: tasks,
    );
  }
```

Y hacer lo mismo con el bloque `if (baselineEdited.isEmpty)` para el camino merged
(líneas 250–256):
```dart
// CÓDIGO ACTUAL:
      return _redistributeFromBaseline(
        edited: edited,
        targetPercent: targetPercent,
        baselineTasks: merged,
      );

// REEMPLAZAR CON:
      if (mode == WeightEditMode.flexible) {
        return _redistributeFlexible(
          edited: edited,
          targetPercent: targetPercent,
          baselineTasks: merged,
        );
      }
      return _redistributeFromBaseline(
        edited: edited,
        targetPercent: targetPercent,
        baselineTasks: merged,
      );
```

### Cambio 1C — Agregar `_redistributeFlexible` (método privado)

Agregar después del cierre de `_redistributeFromBaseline` (después de línea 357):

```dart
  Map<String, int> _redistributeFlexible({
    required PomodoroTask edited,
    required int targetPercent,
    required List<PomodoroTask> baselineTasks,
  }) {
    final others =
        baselineTasks.where((t) => t.id != edited.id).toList();
    final othersTotal = others.fold<int>(0, (s, t) => s + t.totalPomodoros);
    final currentPom = edited.totalPomodoros;
    // min(99, max(current*3, current+12)) — take the larger of the two growth
    // heuristics, then cap at 99. dart:math import required.
    final cap = min(99, max(currentPom * 3, currentPom + 12));

    int? bestCandidate;
    int bestDeviation = 999;
    int bestGroupDiff = 999999;
    int bestEditedDiff = 999999;
    int bestGroupTotal = 999999;

    for (var candidate = 1; candidate <= cap; candidate++) {
      // Build projection with others unchanged.
      final projected = [
        ...others,
        edited.copyWith(totalPomodoros: candidate),
      ];
      final percents = normalizeTaskWeightPercents(projected);
      final resultPct = percents[edited.id] ?? 0;
      final deviation = (resultPct - targetPercent).abs();
      final groupTotal = othersTotal + candidate;
      final groupDiff = (groupTotal - (othersTotal + currentPom)).abs();
      final editedDiff = (candidate - currentPom).abs();

      final better = bestCandidate == null ||
          deviation < bestDeviation ||
          (deviation == bestDeviation && groupDiff < bestGroupDiff) ||
          (deviation == bestDeviation && groupDiff == bestGroupDiff &&
              editedDiff < bestEditedDiff) ||
          (deviation == bestDeviation && groupDiff == bestGroupDiff &&
              editedDiff == bestEditedDiff && groupTotal < bestGroupTotal);

      if (better) {
        bestCandidate = candidate;
        bestDeviation = deviation;
        bestGroupDiff = groupDiff;
        bestEditedDiff = editedDiff;
        bestGroupTotal = groupTotal;
      }
    }

    final result = <String, int>{
      edited.id: bestCandidate ?? currentPom,
    };
    for (final t in others) {
      result[t.id] = t.totalPomodoros;
    }
    return result;
  }
```

**Import requerido:** `normalizeTaskWeightPercents` ya está en `task_weighting.dart`.
Agregar el import si no está ya presente:
```dart
import '../../domain/task_weighting.dart';
```
(verificar antes — puede que ya exista)

### Cambio 1D — Agregar `redistributeTotalPomodoros` (método público)

Agregar después del cierre de `redistributeWeightPercent` (después de línea 263):

```dart
  Map<String, int> redistributeTotalPomodoros({
    required PomodoroTask edited,
    required int targetPomodoros,
    required List<PomodoroTask> tasks,
    WeightEditMode mode = WeightEditMode.fixed,
  }) {
    final clamped = targetPomodoros < 1 ? 1 : targetPomodoros;
    if (mode == WeightEditMode.flexible) {
      // Flexible: only edited task changes, others stay put.
      final result = <String, int>{edited.id: clamped};
      for (final t in tasks) {
        if (t.id != edited.id) result[t.id] = t.totalPomodoros;
      }
      return result;
    }
    // Fixed: set edited task to target, redistribute others to preserve group total.
    final merged = tasks.any((t) => t.id == edited.id)
        ? tasks
        : _mergeEditedTask(edited, tasks);
    final others = merged.where((t) => t.id != edited.id).toList();
    final totalWork = _totalWorkMinutes(merged);
    final editedWork = clamped * edited.pomodoroMinutes;
    final minOthersWork =
        others.fold<int>(0, (s, t) => s + t.pomodoroMinutes);

    // If editedWork leaves less than min for others, clamp edited down.
    var editedPomodoros = clamped;
    var actualEditedWork = editedWork;
    if (totalWork - actualEditedWork < minOthersWork) {
      actualEditedWork = totalWork - minOthersWork;
      editedPomodoros =
          _roundHalfUp(actualEditedWork / edited.pomodoroMinutes);
      if (editedPomodoros < 1) editedPomodoros = 1;
      actualEditedWork = editedPomodoros * edited.pomodoroMinutes;
    }

    // Redistribute others for the remaining work.
    final remainingWork = totalWork - actualEditedWork;
    final othersWork = _totalWorkMinutes(others);
    final targets = <String, _TargetAllocation>{};
    var sumWork = 0;
    for (final task in others) {
      final share = othersWork <= 0
          ? (1 / others.length)
          : (_workMinutes(task) / othersWork);
      final targetWork = remainingWork * share;
      final targetPom = targetWork / task.pomodoroMinutes;
      var rounded = _roundHalfUp(targetPom);
      if (rounded < 1) rounded = 1;
      sumWork += rounded * task.pomodoroMinutes;
      targets[task.id] = _TargetAllocation(
        task: task,
        targetPomodoros: targetPom,
        pomodoros: rounded,
      );
    }

    // Apply rounding correction (same as _redistributeFromBaseline).
    var diff = totalWork - (actualEditedWork + sumWork);
    if (diff != 0) {
      final allocations = targets.values.toList();
      allocations.sort((a, b) => a.fraction.compareTo(b.fraction));
      var guard = 0;
      while (diff != 0 && guard < 10000) {
        guard += 1;
        if (diff > 0) {
          final candidate = allocations.reversed.first;
          candidate.pomodoros += 1;
          diff -= candidate.task.pomodoroMinutes;
          allocations.sort((a, b) => a.fraction.compareTo(b.fraction));
          continue;
        }
        final removable =
            allocations.where((e) => e.pomodoros > 1).toList();
        if (removable.isEmpty) break;
        removable.sort((a, b) => a.fraction.compareTo(b.fraction));
        final candidate = removable.first;
        candidate.pomodoros -= 1;
        diff += candidate.task.pomodoroMinutes;
        allocations.sort((a, b) => a.fraction.compareTo(b.fraction));
      }
    }

    final result = <String, int>{edited.id: editedPomodoros};
    for (final e in targets.entries) {
      result[e.key] = e.value.pomodoros;
    }
    return result;
  }
```

**Constraints:**
- No tocar `_redistributeFromBaseline` ni `applyRedistributedPomodoros`.
- No tocar `_TargetAllocation` ni los helpers privados existentes.
- `normalizeTaskWeightPercents` en `_redistributeFlexible` usa la misma normalización
  que la UI (`.round()`), que es la función de `task_weighting.dart`. NO usar
  `_roundHalfUp` para comparación de porcentajes mostrados.

---

## Commit 2 — Nuevo widget: TaskWeightPreviewSheet

**Archivo (nuevo):** `lib/presentation/screens/task_weight_preview_sheet.dart`

### Interfaz pública del widget

```dart
/// Which field triggered the sheet.
enum TaskWeightField { percent, pomodoros }

/// Callback signature for preview computation.
/// [value]: the integer the user typed (percent 1-100 or pomodoros ≥1).
/// [mode]: Fixed or Flexible.
/// Returns the redistribution map (taskId → newPomodoros).
typedef WeightPreviewComputer = Map<String, int> Function(
    int value, WeightEditMode mode);

class TaskWeightPreviewSheet extends StatefulWidget {
  const TaskWeightPreviewSheet({
    super.key,
    required this.editedTask,
    required this.baselineTasks,   // frozen snapshot, never mutated
    required this.field,
    required this.computePreview,  // pure fn, no provider access
    required this.onApply,         // called with redistribution map
  });

  final PomodoroTask editedTask;
  final List<PomodoroTask> baselineTasks;
  final TaskWeightField field;
  final WeightPreviewComputer computePreview;
  final void Function(Map<String, int> result) onApply;

  @override
  State<TaskWeightPreviewSheet> createState() => _TaskWeightPreviewSheetState();
}
```

### Estado interno

```dart
class _TaskWeightPreviewSheetState extends State<TaskWeightPreviewSheet> {
  late TextEditingController _inputCtrl;
  WeightEditMode _mode = WeightEditMode.fixed;
  Map<String, int>? _result;         // last valid redistribution
  String? _precisionMessage;         // inline notice if deviation ≥ 10pp or no change
}
```

### Ciclo de vida

- `initState`: inicializar `_inputCtrl` con el valor actual de la tarea.
  Para `TaskWeightField.percent`: valor inicial = porcentaje actual del task
  (calculado con `normalizeTaskWeightPercents(widget.baselineTasks)[widget.editedTask.id]`).
  Para `TaskWeightField.pomodoros`: valor inicial = `widget.editedTask.totalPomodoros.toString()`.
  Agregar listener al controller → `_recalculate`.

- `_recalculate`: parsear `_inputCtrl.text`, llamar `widget.computePreview(value, _mode)`,
  actualizar `_result` y `_precisionMessage` con `setState`.
  Si el input no es válido (null, ≤0, >100 para %): `_result = null`.

- Al cambiar `_mode` en el segmented control: llamar `_recalculate`.

### Layout (tres niveles)

```
Column(
  children: [
    // Input + segmented control
    NumericInputField(controller: _inputCtrl, suffix: field == percent ? '%' : null),
    SegmentedButton<WeightEditMode>(
      segments: [Fixed total, Flexible total],
      selected: {_mode},
      onSelectionChanged: (s) { _mode = s.first; _recalculate(); },
    ),

    // Tier 1: result line
    Text('Result: ${resultPomodoros} pom · ${resultPercent}%'),
    if (_precisionMessage != null) Text(_precisionMessage!, style: warningStyle),

    // Tier 2: group impact
    Text('Group total: ${baselineGroupPom} → ${resultGroupPom} pom'),
    Text('Group work: ${baselineGroupMin} → ${resultGroupMin} min'),

    // Tier 3: mini-table — one row per selected task
    for (final task in widget.baselineTasks)
      _TaskRow(
        task: task,
        baseline: task.totalPomodoros,
        result: _result?[task.id] ?? task.totalPomodoros,
        isEdited: task.id == widget.editedTask.id,
        baselinePercent: baselinePercents[task.id] ?? 0,
        resultPercent: resultPercents[task.id] ?? 0,
      ),

    // Fixed footer
    Row(
      children: [
        TextButton('Cancel', onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          'Apply',
          onPressed: _result == null ? null : () {
            widget.onApply(_result!);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ],
)
```

### Lógica de `_precisionMessage`

Calcular resultPercent = `normalizeTaskWeightPercents(resultTasks)[editedTask.id]`.
Para `field == percent`:
- Si resultPercent == inputValue: sin mensaje.
- Si `(resultPercent - inputValue).abs() >= 10`: mensaje "Exact result not possible.
  Closest achievable: ${resultPercent}%."
- Si resultado == baseline (sin cambio): mensaje "No change possible with current
  pomodoros. Add more pomodoros or tasks for finer weights."

Para `field == pomodoros`: mensajes equivalentes con pomodoros en lugar de %.

### Constraints del widget

- `baselineTasks` debe usarse como snapshot de lectura únicamente. No mutar.
- `computePreview` no tiene acceso a providers — es una función pura pasada desde
  el screen. No llamar a ref dentro del widget.
- Apply está deshabilitado (`onPressed: null`) mientras `_result == null`.
- El widget NO importa `task_editor_view_model.dart` directamente. Solo usa los tipos
  públicos `WeightEditMode`, `TaskWeightField`, `PomodoroTask`.
- Si `widget.baselineTasks.length <= 1` (solo la tarea editada, sin otras seleccionadas),
  ocultar el mode selector y la mini-tabla. La sheet sigue abriendo para Total pomodoros
  (el usuario puede cambiar su valor con Apply/Cancel) pero no hay redistribución posible.
  Para Task weight (%), la apertura está bloqueada en el screen antes de llegar aquí.

---

## Commit 3 — Editor screen: remover maquinaria Patch 1, convertir campos a tap targets

**Archivo:** `lib/presentation/screens/task_editor_screen.dart`

### Cambio 3A — Remover campos de estado de Patch 1

Eliminar estas declaraciones de campos del State (área líneas 65–75):

```dart
// ELIMINAR ESTOS CAMPOS:
  int? _weightPercentStartValue;
  int? _lastRequestedWeightPercent;
  int? _lastResultWeightPercent;
  bool _lastRedistributionChanged = false;
  String? _lastWeightNoticeKey;
  bool _weightPercentEdited = false;
  List<PomodoroTask>? _weightScopeBaseline;
  bool _syncingWeight = false;
```

Mantener (son usados por el Save flow y otros):
```dart
  Map<String, int>? _pendingRedistribution;  // MANTENER — usado en _handleSave
  bool _weightSheetOpen = false;             // AGREGAR — true mientras la preview sheet esté abierta
```

### Cambio 3B — Remover `_weightPercentCtrl` y `_totalPomodorosCtrl`

En la declaración de controllers (área líneas 88–93):
```dart
// ELIMINAR:
  late TextEditingController _totalPomodorosCtrl;
  late TextEditingController _weightPercentCtrl;
```

En `initState`: eliminar las líneas que crean y asignan esos controllers.
En `dispose`: eliminar sus `.dispose()` calls.

También:
```dart
// ELIMINAR en initState:
  late FocusNode _weightPercentFocus;
  // y su addListener block completo (líneas 97–107)
// ELIMINAR en dispose:
  _weightPercentFocus.dispose();
```

### Cambio 3C — Limpiar `_syncControllers`

En `_syncControllers` (línea 1054), eliminar:
```dart
// ELIMINAR:
    _totalPomodorosCtrl.text = task.totalPomodoros.toString();
    final percent = _currentWeightPercent(task);
    if (percent != null) {
      _weightPercentCtrl.text = percent.toString();
    }
// También eliminar las líneas que limpian campos de Patch 1:
    _weightScopeBaseline = null;
    _lastResultWeightPercent = null;
```

Mantener solo `_pendingRedistribution = null;` en `_syncControllers`.

### Cambio 3D — Remover métodos de Patch 1 del State

Eliminar estos métodos completos:
- `_maybeSyncWeightPercent` (líneas 1357–1364)
- `_syncWeightPercentFromTask` (líneas 1366–1372)
- `_currentWeightPercent` (líneas 1243–1255)
- `_computeWeightPercentFromRedistribution` (líneas 1257–1273)
- `_hasRedistributionChanges` (líneas 1275–1286)
- `_maybeShowWeightPrecisionNotice` (líneas 1288–1315)
- `_showWeightNotice` (línea 1317 y su cuerpo)

### Cambio 3E — Remover `_maybeSyncWeightPercent` de `build()`

En `build()`, eliminar el bloque (líneas 417–419):
```dart
// ELIMINAR:
    if (weightPercent != null) {
      _maybeSyncWeightPercent(weightPercent);
    }
```

También eliminar `_maybePromptWeightInfoDialog` call si depende de estado eliminado
(verificar antes). Si `_maybePromptWeightInfoDialog` es independiente, mantenerla.

### Cambio 3F — Remover `_weightScopeBaseline` del call site de `_weightRow`

En la llamada a `_weightRow` (línea 631):
```dart
// CÓDIGO ACTUAL:
              _weightRow(
                task: task,
                weightScopeTasks: _weightScopeBaseline ?? selectedWeightTasks,

// REEMPLAZAR CON:
              _weightRow(
                task: task,
                weightScopeTasks: selectedWeightTasks,
```

(La congelación de baseline ahora ocurre al abrir la sheet, no en el editor.)

### Cambio 3G — Reescribir `_weightRow`

El método `_weightRow` (líneas 2019–2112) se reescribe completamente.
Reemplazar TODO el cuerpo con tap-target displays:

```dart
  Widget _weightRow({
    required PomodoroTask task,
    required List<PomodoroTask> weightScopeTasks,
    required bool showWeightPercent,
    required VoidCallback onInfoTap,
    required int? weightPercent,
  }) {
    // Total pomodoros: ALWAYS tappable and enabled regardless of weight context.
    // The sheet handles the no-redistribution case (scope.length <= 1) internally.
    final totalField = Expanded(
      child: InkWell(
        onTap: () => _openPomodorosPreviewSheet(task, weightScopeTasks),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Total pomodoros',
            enabled: true,
          ),
          child: Text(task.totalPomodoros.toString()),
        ),
      ),
    );
    if (!showWeightPercent) {
      return Row(children: [totalField]);
    }
    // Task weight (%): only tappable when 2+ tasks are selected.
    // With 1 task selected: field is visible but disabled, shows 100%.
    final singleTask = weightScopeTasks.length <= 1;
    return Row(
      children: [
        totalField,
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: singleTask
                ? null
                : () => _openWeightPreviewSheet(task, weightScopeTasks),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Task weight (%)',
                enabled: !singleTask,
                suffixIcon: _infoButton(
                  tooltip: 'How task weight works',
                  onPressed: onInfoTap,
                ),
              ),
              child: Text(
                singleTask
                    ? '100%'
                    : (weightPercent != null ? '$weightPercent%' : '—'),
              ),
            ),
          ),
        ),
      ],
    );
  }
```

**Nota:** agregar `required int? weightPercent` al parámetro del método y actualizar
el call site en `build()` para pasar `weightPercent: weightPercent` (ya computado
en `build()` como `selectedWeightPercents[selectedTask.id]`).

También, en `build()`, eliminar la referencia a `selectedWeightTasks` como `_weightScopeBaseline ?? ...`
(ya eliminado en 3F); y eliminar `_maybeSyncWeightPercent` (eliminado en 3E).

### Cambio 3H — Agregar `_openWeightPreviewSheet` y `_openPomodorosPreviewSheet`

Agregar dos métodos al State (en cualquier lugar después de `_update`):

```dart
  void _openWeightPreviewSheet(
      PomodoroTask task, List<PomodoroTask> scope) {
    // Guard: sheet is meaningless with only one task (no redistribution possible).
    // The InkWell onTap is already null for singleTask, but guard defensively here too.
    if (scope.length <= 1) return;
    final frozenScope = List<PomodoroTask>.unmodifiable(scope);
    final editor = ref.read(taskEditorProvider.notifier);
    setState(() => _weightSheetOpen = true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskWeightPreviewSheet(
        editedTask: task,
        baselineTasks: frozenScope,
        field: TaskWeightField.percent,
        computePreview: (value, mode) => editor.redistributeWeightPercent(
          edited: task,
          targetPercent: value,
          tasks: frozenScope,
          mode: mode,
        ),
        onApply: (result) {
          _pendingRedistribution = result;
          _update(task.copyWith(totalPomodoros: result[task.id]!));
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _weightSheetOpen = false);
    });
  }

  void _openPomodorosPreviewSheet(
      PomodoroTask task, List<PomodoroTask> scope) {
    final frozenScope = List<PomodoroTask>.unmodifiable(scope);
    final editor = ref.read(taskEditorProvider.notifier);
    setState(() => _weightSheetOpen = true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskWeightPreviewSheet(
        editedTask: task,
        baselineTasks: frozenScope,
        field: TaskWeightField.pomodoros,
        computePreview: (value, mode) => editor.redistributeTotalPomodoros(
          edited: task,
          targetPomodoros: value,
          tasks: frozenScope,
          mode: mode,
        ),
        onApply: (result) {
          _pendingRedistribution = result;
          _update(task.copyWith(totalPomodoros: result[task.id]!));
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _weightSheetOpen = false);
    });
  }
```

**Import requerido en el screen:**
```dart
import 'task_weight_preview_sheet.dart';
```

### Cambio 3I — Limpiar `_handleSave` y otros reset points

En `_handleSave` (línea 295), ya NO hay `_weightScopeBaseline` ni `_lastResultWeightPercent`.
Eliminar esas dos líneas de null-assignment que quedaron del Patch 1.
Mantener `_pendingRedistribution = null;` (sigue siendo necesario).

Hacer lo mismo en `_handleDiscard` (línea 356), `_syncControllers` (línea 1034),
y pomodoro duration `onChanged` (línea 649):
- Eliminar `_weightScopeBaseline = null;` y `_lastResultWeightPercent = null;`
- Mantener `_pendingRedistribution = null;`

En el Total pomodoros `onChanged` en `_weightRow` — este handler desaparece completamente
porque el campo ahora es InkWell con `_openPomodorosPreviewSheet`. Ya no hay `onChanged`.

### Cambio 3J — Detectar cambio de selección con sheet abierta (en `build()`)

Agregar este `ref.listen` en `build()`, junto a los otros `ref.listen` existentes
(área líneas 410–430, después de los `ref.watch` iniciales):

```dart
    // Close weight preview sheet if selection changes while it is open.
    ref.listen<Set<String>>(taskSelectionProvider, (prev, next) {
      if (!_weightSheetOpen) return;
      if (prev == null || prev == next) return;
      // Selection changed while sheet is open: dismiss without applying.
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selection changed — weight edit discarded.'),
          duration: Duration(seconds: 3),
        ),
      );
    });
```

**Por qué `maybePop` y no `pop`:** el sheet puede ya haber sido cerrada por el usuario
(Cancel/Apply) antes de que llegue el evento de selección. `maybePop` es seguro si no
hay nada que cerrar; `pop` lanzaría una excepción. El `.then()` en los métodos de apertura
ya borra `_weightSheetOpen` cuando la sheet se cierra normalmente, por lo que el guard
`if (!_weightSheetOpen) return;` previene falsos disparos.

**Constraint:** no extraer este bloque a un método separado. Debe vivir en `build()`
como `ref.listen`, no como `ref.watch` ni como listener imperativo, para que Riverpod
gestione el ciclo de vida del listener correctamente.

### Constraints — NO tocar

- No modificar `_handleSave` más allá de eliminar las líneas de Patch 1 ya indicadas.
- No modificar `applyRedistributedPomodoros`.
- No modificar el flujo de Save/Discard excepto para remover las líneas indicadas.
- No cambiar el comportamiento de los demás campos del editor (nombre, duración pomodoro,
  breaks, etc.).
- No remover `_maybePromptWeightInfoDialog` (modal de info de primera exposición).
- No remover el info icon button ni el diálogo de info (`_showWeightInfoDialog`).

---

## Commit 4 — Tests

**Archivos:**
- `test/presentation/viewmodels/task_editor_view_model_test.dart`
- `test/domain/task_weighting_test.dart`

### Tests para Commit 4

Agregar en `task_editor_view_model_test.dart`:

1. **redistributeWeightPercent Fixed mode (existing behavior preserved):**
   verificar que el modo fixed produce el mismo resultado que el método antes de Patch 2.

2. **redistributeWeightPercent Flexible mode:**
   - caso base: 4 tareas seleccionadas, editar A de 5 a 80% → solo A cambia, B/C/D intactos.
   - verificar que el total de A está dentro del rango buscado y la aproximación es la
     más cercana posible.

3. **redistributeTotalPomodoros Fixed mode:**
   - editar A de 5 a 8 pomodoros con grupo de 11 total → otros se redistribuyen para
     mantener 11 total.

4. **redistributeTotalPomodoros Flexible mode:**
   - editar A de 5 a 8 pomodoros → solo A cambia a 8, B/C/D intactos.

5. **Tiebreaker determinista en Flexible:**
   - caso donde dos candidatos tienen igual desviación % → verificar que el de menor
     cambio en grupo gana.

Agregar en `task_weighting_test.dart`:

6. **normalizeTaskWeightPercents con lista post-flexible:**
   verificar que la normalización es coherente con el % mostrado al usuario cuando
   el grupo total cambia en modo flexible.

---

## Orden de commits

```
Commit 1: feat(bug016-p2): add WeightEditMode enum and mode-aware redistribution methods to ViewModel
Commit 2: feat(bug016-p2): implement TaskWeightPreviewSheet widget
Commit 3: feat(bug016-p2): convert weight/pomodoros fields to tap targets and integrate preview sheet
Commit 4: test(bug016-p2): add mode-aware redistribution tests
```

---

## Tests a ejecutar antes de entregar a Claude para QA

```bash
flutter analyze
flutter test test/presentation/viewmodels/task_editor_view_model_test.dart
flutter test test/domain/task_weighting_test.dart
```

Todos deben pasar. Si alguno falla, reportar a Claude antes de continuar.
No ajustar tests para que pasen — si un test falla, hay un bug en la implementación.

La verificación de comportamiento en device (sheet abre correctamente, Apply funciona,
Cancel restaura, modo selector recalcula en vivo, 1-task muestra disabled) es
responsabilidad de Claude QA + validación del usuario.

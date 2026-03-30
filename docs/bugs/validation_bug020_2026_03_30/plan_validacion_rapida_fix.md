## Header

- Date: 30/03/2026
- Branch: fix/task-editor-preview-context-duration-feedback
- Commit: 78b72db
- Bugs covered: BUG-020
- Devices: Android RMX3771 (debug), macOS (debug)

## Objetivo

Corregir las incoherencias del editor de Total pomodoros y Task weight (%) en Edit Task:
terminología Task vs Group según contexto real de selección, mostrar duración de trabajo
sin descansos y duración total con descansos, aviso de umbral siempre visible cuando aplica,
modal de confirmación al salir con cambios sin aplicar, y mensajes de snackbar correctos
según el resultado de cada acción.

## Síntoma original

- El sheet mostraba "Group work" incluso cuando la tarea no estaba seleccionada para grupo.
- Solo se mostraba la duración de trabajo (sin descansos); los umbrales 11h/24h/72h se
  evalúan sobre el total con descansos pero ese dato no era visible.
- El aviso Unusual/Superhuman/Machine dejaba de aparecer tras la primera vez dentro de la
  sesión del sheet, dando sensación de comportamiento erróneo.
- Al salir del sheet, el snackbar decía siempre "No changes applied" aunque se hubieran
  aplicado cambios con el botón Apply.
- No había modal de confirmación al pulsar Back con cambios pendientes sin aplicar.

## Root cause

- `isGroupContext` no se pasaba al sheet; siempre se usaba terminología de grupo.
- Solo `_groupMinutes` (work-only) era visible en UI; `continuousGroupDurationSecondsForTasks`
  / `continuousTaskDurationsSecondsForTasks` (total con breaks) no se exponía.
- `showContinuousCaution` guardado por `_hasUserInteracted`, causando desaparición errática.
- La lógica de salida no distinguía entre applied / unapplied / sin cambios.

## Protocolo de validación

### Escenario A — Tarea no seleccionada: terminología Task

Precondiciones: app abierta, ≥1 tarea en lista, ninguna tarea seleccionada.
Pasos:
1. Abrir Edit Task de cualquier tarea.
2. Tocar el campo Total pomodoros.
3. Observar las etiquetas del preview.

Resultado esperado: "Task total pomodoros", "Task work", "Total task duration".
Sin el fix: "Group total pomodoros", "Group work" — incorrecto.

### Escenario B — Tarea seleccionada: terminología Group

Precondiciones: ≥1 tarea seleccionada en la lista (botón de selección activo).
Pasos:
1. Abrir Edit Task de la tarea seleccionada.
2. Tocar el campo Total pomodoros.
3. Observar las etiquetas del preview.

Resultado esperado: "Group total pomodoros", "Group work", "Total group duration".

### Escenario C — Dos líneas de duración

Precondiciones: cualquier contexto (Task o Group).
Pasos:
1. Abrir preview sheet de Total pomodoros.
2. Ingresar un valor que produzca resultado válido.
3. Observar el bloque de métricas.

Resultado esperado:
- Línea 1: "<Task/Group> work: Xh Ym → Xh Ym" (solo trabajo, sin descansos).
- Línea 2: "Total <task/group> duration: Xh Ym → Xh Ym" (con descansos).

### Escenario D — Aviso de umbral siempre visible

Precondiciones: tarea con pomodoros suficientes para superar 11h de trabajo total.
Pasos:
1. Abrir preview sheet con valor que supere umbral.
2. Reducir a valor bajo el umbral (aviso desaparece — correcto).
3. Volver a valor sobre umbral.

Resultado esperado: aviso reaparece. Sin el fix: no reaparecía.

### Escenario E — Back con cambios sin aplicar: modal de confirmación

Precondiciones: cualquier contexto.
Pasos:
1. Abrir preview sheet.
2. Cambiar el valor (no pulsar Apply).
3. Pulsar Back.

Resultado esperado: modal con 3 opciones: "Apply and close", "Discard and close",
"Continue editing". Sin el fix: cierre directo con snackbar incorrecto.

### Escenario F — Apply: snackbar correcto

Pasos:
1. Abrir preview sheet, cambiar valor, pulsar Apply.

Resultado esperado: snackbar "Changes applied." (corto, desaparece solo).
Sin el fix: snackbar "No changes applied" — incorrecto.

### Escenario G — Sin cambios: cierre sin modal

Pasos:
1. Abrir preview sheet, no cambiar nada, pulsar Back.

Resultado esperado: cierre directo + snackbar "No changes made."
Sin el fix: snackbar "No changes applied" igualmente.

## Comandos de ejecución

```bash
# Android
flutter run -d <device_id> 2>&1 | tee docs/bugs/validation_bug020_2026_03_30/logs/2026-03-30_bug020_78b72db_android_RMX3771_debug.log

# macOS
flutter run -d macos 2>&1 | tee docs/bugs/validation_bug020_2026_03_30/logs/2026-03-30_bug020_78b72db_macos_debug.log
```

## Log analysis — quick scan

Señales de fix funcionando (no hay señales de log específicas para cambios de UI puro;
verificación visual directa en device).

## Verificación local

- [x] `flutter analyze` — PASS (0 issues)
- [x] `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart` — PASS
- [x] `flutter test test/domain/continuous_plan_load_test.dart` — PASS

## Criterios de cierre

- [ ] Escenario A PASS: terminología Task cuando no seleccionada.
- [ ] Escenario B PASS: terminología Group cuando seleccionada.
- [ ] Escenario C PASS: dos líneas de duración (work + total con breaks).
- [ ] Escenario D PASS: aviso reaparece al re-entrar en umbral.
- [ ] Escenario E PASS: modal de confirmación al salir con cambios sin aplicar.
- [ ] Escenario F PASS: snackbar "Changes applied." tras Apply.
- [ ] Escenario G PASS: cierre silencioso + "No changes made." sin cambios.
- [ ] `flutter analyze` PASS.

## Status

Closed/OK — Device validation PASS 30/03/2026 (Android RMX3771 + macOS).
Todos los escenarios A–G PASS confirmados por el usuario.

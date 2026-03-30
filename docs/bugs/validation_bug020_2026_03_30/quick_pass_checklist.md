## Exact repro

- [x] Escenario A PASS: "Task total pomodoros" / "Task work" / "Total task duration" cuando tarea no seleccionada.
- [x] Escenario B PASS: "Group total pomodoros" / "Group work" / "Total group duration" cuando tarea seleccionada.
- [x] Escenario C PASS: dos líneas de duración (work sin breaks + total con breaks).
- [x] Escenario D PASS: aviso Unusual/Superhuman/Machine reaparece al volver a umbral.
- [x] Escenario E PASS: modal "Apply and close / Discard and close / Continue editing" al salir con cambios sin aplicar.
- [x] Escenario F PASS: snackbar "Changes applied." tras Apply.
- [x] Escenario G PASS: "No changes made." al salir sin cambios.

## Regression smoke

- [x] Edición de pomodoros tarea suelta: guardado correcto.
- [x] Edición de weight % tarea en grupo: guardado correcto.
- [x] flutter test task_editor_view_model_test.dart PASS.
- [x] flutter test continuous_plan_load_test.dart PASS.

## Local gate

- [x] flutter analyze PASS (0 issues).

## Closure rule

Cerrar solo cuando todos los boxes están marcados con evidencia.

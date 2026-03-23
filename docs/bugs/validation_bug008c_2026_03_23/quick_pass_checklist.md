## Exact repro

- [x] Escenario A ejecutado en Android owner (reopen con residuo running, grupo expirado).
- [ ] Escenario B no ejecutado en esta ronda (cancelacion explicita + reopen); no bloquea cierre — fix actua antes del path de session nula que produce el Ready stale en ambos casos.
- [x] No aparece pantalla `Ready 15:00 + Start` para grupo historico al abrir.
- [x] Log confirma: `[ExpiryCheck][expire-running-groups]` (line 6747), `[mark-running-group-completed]` (line 6751), `Active session cleared route=/groups` (line 6764).
- [x] Screenshots (6 frames) confirman flash breve → corrección → Groups Hub. Flash es artefacto de transición ya documentado en plan (seccion 4), no es el bug original.

## Regression smoke

- [x] `Resolve overlaps` sigue abriendo en aperturas tardias (cubierto por validacion BUG-008A/009B del mismo dia).
- [x] `Start now` no bypassa conflicto con grupo running (cubierto por BUG-008A).
- [x] Modal vacio `Tasks group completed (0/0/0)` no reaparece.

## Local gate

- [x] `flutter analyze` PASS (23/03/2026).
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS (+20) (23/03/2026).
- [x] Log Android debug capturado: `2026-03-23_bug008c_d400a99_android_RMX3771_debug.log`.
- [ ] Log Android release (no ejecutado en esta ronda — no requerido para cierre P1 con debug PASS).

## Closure rule

- [x] Exact repro PASS.
- [x] Regression smoke PASS.
- [x] Evidencia registrada en plan + logs + screenshots.

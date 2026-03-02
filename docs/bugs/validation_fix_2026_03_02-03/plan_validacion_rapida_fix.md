# Plan — Rapid Validation Fix (2026-03-02)

Date: 2026-03-02
Scope: Owner freeze while running (Account Mode).

## Contexto
- En Account Mode, el owner se congela (timer fijo) aunque `activeSession/current.lastUpdatedAt`
  sigue avanzando.
- `remainingSeconds` no cambia en Firestore cuando `sessionRevision` no sube (idempotente).
  Eso es esperado; el UI debe proyectar desde `phaseStartedAt` + server offset.
- En el owner, el VM ignora el stream local y aplica proyeccion remota en cada snapshot,
  lo que puede fijar el estado al `remainingSeconds` del snapshot.

## Repro exacto (antes del fix)
1. Dos dispositivos en Account Mode: Android owner, macOS mirror.
2. Iniciar un grupo de 60 min (1 pomodoro) en Android.
3. Esperar >10 min.
4. Observar:
   - Firestore `activeSession/current.lastUpdatedAt` avanza.
   - `remainingSeconds` permanece fijo.
   - Android muestra el timer congelado (no baja segundos).
   - macOS puede re-sync al enfocar, pero Android queda congelado.

## Hipotesis tecnica confirmada
- `_shouldIgnoreMachineStream()` ignora el stream local siempre que exista activeSession,
  incluso si el dispositivo es owner.
- En owner, se aplica proyeccion remota (`_setMirrorSession`) en cada snapshot,
  que puede caer en fallback (remaining fijo) y sobrescribir el estado local.

## Cambios requeridos
1. Owner no debe ignorar el stream local del PomodoroMachine.
2. Owner no debe usar `_setMirrorSession()` ni iniciar mirror timer.
3. En owner, si no hay server offset, permitir proyeccion con reloj local
   (evitar fallback a `remainingSeconds` fijo).

## Validacion rapida (despues del fix)
1. Repetir el repro: Android owner + macOS mirror, run de 60 min.
2. Confirmar:
   - Android countdown sigue bajando siempre.
   - `activeSession/current.lastUpdatedAt` avanza.
   - `remainingSeconds` puede quedar fijo, pero **no congela** el UI.
   - Mirror sigue proyectando correctamente.

## Tracking
- Estado: En progreso.
- Commits: (pendiente)

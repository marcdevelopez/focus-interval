# Plan — Rapid Validation Fix (2026-03-02)

Date: 2026-03-02
Scope: TimeSync deadlock + auth gating (Account Mode, web/mac).

## Contexto
- En Account Mode, el UI queda en "Syncing session..." y `activeSession/current` no
  se actualiza (`lastUpdatedAt` fijo, `sessionRevision` estancada).
- No se crea `users/{uid}/timeSync/anchor` aunque la regla exista.

## Repro exacto (antes del fix)
1. Chrome debug con prod:
   `flutter run -d chrome --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
2. Login Account Mode con Google.
3. Iniciar un grupo (Start now).
4. Ver en Firestore:
   - `users/{uid}/timeSync` NO existe.
   - `users/{uid}/activeSession/current.lastUpdatedAt` queda fijo en el momento
     del start (ej. 2026-03-02 01:52:08 UTC+1).
5. UI permanece en "Syncing session...".

## Hipotesis tecnica confirmada
- Deadlock: la UI entra en Syncing cuando falta time sync y `_publishCurrentSession`
  sale temprano.
- Gating fragil: `timeSyncServiceProvider` y `pomodoroSessionRepositoryProvider`
  dependen de `authStateProvider.value` (puede ser null transitorio), lo que
  deshabilita TimeSync y el repo real aunque `currentUser` exista.
- `NoopPomodoroSessionRepository` permite `tryClaim` pero no publica, dejando
  `activeSession` congelada.

## Cambios requeridos
1. Providers:
   - Usar `currentUserProvider` (o `authState ?? auth.currentUser`) para habilitar
     TimeSync y el repo de sesiones cuando el usuario exista.
2. Publish:
   - `_publishCurrentSession()` no debe hacer return si falta time sync.
   - Debe publicar con `DateTime.now()` como fallback mientras reintenta sync.
   - Permitir publish cuando falta session pero el owner esta activo (evitar freeze).
   - Permitir heartbeats mientras esperamos confirmacion de sesion (awaiting).
3. Specs:
   - Documentar el fallback de publish/heartbeat cuando time sync no esta listo.
   - Mantener bloqueo de start/resume/auto-start sin time sync.

## Validacion rapida (despues del fix)
1. Chrome debug + prod + override:
   - Confirmar que se crea `users/{uid}/timeSync/anchor`.
   - Confirmar que `activeSession/current.lastUpdatedAt` sube cada ~30s.
   - El overlay "Syncing session..." desaparece.
2. Start/resume siguen bloqueados si time sync no esta listo.
3. Mirror sigue proyectando desde serverTime cuando time sync esta listo.

## Tracking
- Estado: Implementado (validacion pendiente).
- Commits:
  - 1945594 "Fix time sync deadlock and auth gating"
  - 9916204 "Allow owner heartbeats while awaiting session"

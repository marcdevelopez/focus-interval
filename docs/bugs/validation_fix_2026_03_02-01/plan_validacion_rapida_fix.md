# Plan — Rapid Validation Fix (2026-03-02)

Date: 2026-03-02
Scope: Permitir override de prod en debug en todas las plataformas (temporal).

## Contexto
- En debug, `APP_ENV=prod` esta bloqueado y la app queda en "Starting Focus Interval...".
- Se necesita un override temporal en debug para pruebas reales mientras no hay staging.

## Repro exacto (antes del fix)
1. Ejecuta en Chrome (debug):
   `flutter run -d chrome --dart-define=APP_ENV=prod`
2. Ejecuta en macOS (debug):
   `flutter run -d macos --dart-define=APP_ENV=prod`
3. Resultado actual: la app queda en "Starting Focus Interval...".

## Cambio requerido
- Permitir `APP_ENV=prod` en debug solo cuando `ALLOW_PROD_IN_DEBUG=true`.
- Mantener el bloqueo cuando el flag no esta presente.
- Debe revertirse cuando exista staging.

## Validacion rapida (despues del fix)
1. Chrome debug con prod + override:
   `flutter run -d chrome --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
   Esperado: la app inicia y permite login en Account Mode.
2. macOS debug con prod + override:
   `flutter run -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
   Esperado: la app inicia y permite login en Account Mode.
3. Chrome debug con prod sin override:
   `flutter run -d chrome --dart-define=APP_ENV=prod`
   Esperado: sigue bloqueando prod en debug (StateError).
4. Release prod sin override:
   `flutter run -d chrome --release --dart-define=APP_ENV=prod`
   Esperado: comportamiento sin cambios.

## Tracking
- Estado: Implementado (validacion pendiente).
- Commit: d5e08ae "Allow prod debug override on all platforms"

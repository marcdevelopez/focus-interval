# Plan de validación rápida — BUG-005

**Fecha:** 24/03/2026
**Rama:** `fix/buglog-005-validation`
**Commit base:** `e906c54`
**Bug cubierto:** BUG-005
**Dispositivos:** Android RMX3771 + macOS (ambos requeridos, roles intercambiados entre escenarios)

---

## Objetivo

Confirmar que las solicitudes de ownership se muestran en el dispositivo receptor
sin necesitar click/focus manual ni navegar a Groups Hub.

---

## Síntoma original

Las solicitudes de ownership no aparecen en el dispositivo receptor hasta que:
- **Variant A:** el usuario hace click en la ventana macOS para darle foco.
- **Variant B/D/E:** el usuario navega a Groups Hub y vuelve, o pone la app en
  background y la recupera.

**Lo que ve el usuario:** el mirror espera el modal de "Ownership request" y no
llega; tiene que forzar un resubscribe manual para verlo.

---

## Root cause

### Variant A (macOS owner sin foco)
El receptor macOS no actualizaba su estado de sesión mientras la ventana estaba
inactiva — el listener de stream seguía vivo pero ningún refresh explícito forzaba
la lectura del campo `ownershipRequest` actualizado.

### Variant B/D/E (Android owner en foreground)
El listener de sesión en el ViewModel tenía gaps de suscripción (AP-1: suscripción
cancelada en `build()`). Al producirse un rebuild de provider por token refresh,
el listener se cerraba y la nueva suscripción emitía `null` antes de re-sincronizarse,
dejando la ventana donde el request no era visible.

---

## Fix aplicado

### Variant A — `_startInactiveResync()` (implementado en el rewrite de Fix 26)
`timer_screen.dart:308` — cuando `AppLifecycleState.inactive` llega (incluye
pérdida de foco en macOS), se llama `vm.handleAppPaused()`.

`pomodoro_view_model.dart:2863` — `handleAppPaused()` en Account Mode arranca
`_startInactiveResync()`: timer periódico de **15 segundos** que ejecuta
`syncWithRemoteSession(preferServer: true, reason: 'inactive-resync')`.

`syncWithRemoteSession` hace fetch del documento de sesión desde el servidor.
El campo `ownershipRequest` viene incluido en ese snapshot. Si hay un request
pending, `_didOwnershipMetaChange` lo detecta → `_notifySessionMetaChanged()` →
`state = state` → UI reconstruye → modal aparece.

En macOS: `_keepClockActiveOutOfFocus()` devuelve `true` (el reloj sigue), pero
`handleAppPaused()` sí se llama → inactive-resync arranca correctamente.

### Variant B — Fix 26 architecture rewrite (`cbd800a`)
`SessionSyncService` mantiene la suscripción al stream de sesión de forma
persistente e independiente del lifecycle del ViewModel. AP-1 eliminado: ya no
se cancela `_sessionSub` en `build()`. Cualquier write en el documento de sesión
(incluyendo `ownershipRequest`) llega por stream al ViewModel en tiempo real.

---

## Protocolo de validación

### Escenario A — Variant A: macOS owner sin foco (≤15s)

**Setup:** macOS como owner, Android como mirror. Grupo running activo en ambos.

**Precondiciones:**
- Run Mode activo en macOS (owner) y Android (mirror).
- Confirmar que ambos ven el timer corriendo.

**Pasos:**
1. En macOS: mueve el foco a otra aplicación (cualquier otra ventana).
   La app sigue corriendo en background — **no cierres ni minimices**, solo cambia de foco.
2. Espera **sin tocar macOS**.
3. Desde Android mirror: pulsa el botón para solicitar ownership (icono de ownership
   en Run Mode → "Request ownership").
4. Observa macOS sin tocarlo. El modal debe aparecer **en ≤15 segundos**.

**Resultado esperado (PASS):**
- El modal de ownership request aparece en macOS sin que el usuario le dé foco.
- Tiempo desde la solicitud hasta que aparece el modal: ≤15s.

**Resultado sin fix (FAIL):**
- El modal no aparece. Solo aparece tras clickar la ventana macOS.

---

### Escenario B — Variant B: Android owner en foreground, request llega en tiempo real

**Setup:** Android como owner, macOS como mirror. Grupo running activo en ambos.

**Precondiciones:**
- Run Mode activo en Android (owner) y macOS (mirror).
- Android en foreground, pantalla encendida.

**Pasos:**
1. Confirma que Android está en Run Mode como owner (muestra el control de pausa).
2. Desde macOS mirror: solicita ownership (ownership sheet → "Request ownership").
3. Observa Android **sin navigar a Groups Hub ni hacer background**.

**Resultado esperado (PASS):**
- El banner/modal de ownership request aparece en Android en <5 segundos.
- No es necesario navegar a Groups Hub ni poner la app en background.

**Resultado sin fix (FAIL):**
- Android no muestra ningún modal/banner.
- Solo aparece tras navegar a Groups Hub y volver, o tras background/foreground.

---

## Comandos de ejecución

### Android (debug, prod env)
```bash
cd /Users/devcodex/development/focus_interval
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug005_2026_03_24/logs/2026-03-24_bug005_e906c54_android_RMX3771_debug.log
```

### macOS (debug, prod env)
```bash
cd /Users/devcodex/development/focus_interval
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug005_2026_03_24/logs/2026-03-24_bug005_e906c54_macos_debug.log
```

---

## Log analysis — quick scan

### Escenario A — confirmar inactive-resync en macOS tras perder foco

```bash
# macOS log: debe aparecer cada ~15s tras perder foco
rg -n "Resync start \(inactive-resync\)" \
  docs/bugs/validation_bug005_2026_03_24/logs/2026-03-24_bug005_e906c54_macos_debug.log
```

Señal de PASS: aparecen líneas `[ActiveSession] Resync start (inactive-resync).`
mientras la ventana está sin foco (antes de que el usuario haga click).

### Escenario B — confirmar que el stream entrega el request en Android

```bash
# Android log: cambio de sesión con ownership request
rg -n "Active session change|RunModeDiag" \
  docs/bugs/validation_bug005_2026_03_24/logs/2026-03-24_bug005_e906c54_android_RMX3771_debug.log \
  | grep -i "pomodoroRunning"
```

Señal de PASS: aparece `[RunModeDiag] Active session change` al mismo tiempo que
el request es visible en la UI de Android — sin `inactive-resync` previo (el stream
lo entregó directamente).

### Señal de FAIL (cualquier escenario)

```bash
# Solo aparece Groups Hub resync — indicaría que el stream/resync no lo entregó solo
rg -n "Resync start \(load-group\)|resume-rebind" \
  docs/bugs/validation_bug005_2026_03_24/logs/2026-03-24_bug005_e906c54_android_RMX3771_debug.log \
  | head -5
```

Si el resync solo aparece tras una navegación, sería indicador de fallo.

---

## Verificación local

```bash
flutter analyze
# Expected: No issues found!

flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
```

---

## Criterios de cierre

### BUG-005 cerrado cuando:
- [ ] Escenario A PASS: modal en macOS sin foco aparece en ≤15s.
  Log macOS muestra `[ActiveSession] Resync start (inactive-resync).` durante ventana inactiva.
- [ ] Escenario B PASS: banner/modal en Android owner aparece en <5s sin Groups Hub.
  Log Android muestra `[RunModeDiag] Active session change` sin navegación previa.

### Regla de cierre
Ambos escenarios con PASS confirmado + log evidence.

---

## Status

Open — pendiente de ejecución de device run.

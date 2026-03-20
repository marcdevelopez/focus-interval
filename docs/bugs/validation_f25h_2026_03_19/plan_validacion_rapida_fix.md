# Plan de Validación Rápida — BUG-F25-H

**Fecha:** 19/03/2026
**Branch:** fix-f25-h-cancel-syncing-hold
**Commits del fix:** 9a52405 / e2a69b3 / ba8db6f (baseline diagnóstico: 3cb2f6c)
**Bugs cubiertos:** BUG-F25-H
**Dispositivos objetivo:** Chrome (web) + iOS (iPhone 17 Pro)

---

## 1. Objetivo

Verificar que el fix de tres componentes para BUG-F25-H elimina el bloqueo indefinido
"Syncing session..." que ocurre cuando se cancela un segundo grupo (G2) dentro de un
flujo G1→cancelar→replanificar→G2→cancelar. Los dos dispositivos deben navegar de
vuelta a Groups Hub sin necesidad de reiniciar la app. No debe introducirse ninguna
regresión en el flujo de cancelación simple ni en los flujos de recuperación de sesión
ante cortes de red.

---

## 2. Síntoma original

Después de cancelar G2 (segundo grupo en el flujo G1→cancel→G2), ambos dispositivos
quedan atascados en la pantalla del timer mostrando "Syncing session..." con el
temporizador aún corriendo. El documento `activeSession/current` en Firestore ya no
existe. Los dispositivos nunca navegan a Groups Hub ni se recuperan solos. Se requiere
reinicio manual de la app.

El usuario ve: pantalla del timer congelada, overlay "Syncing session..." permanente,
temporizador sigue contando aunque el grupo fue cancelado.

---

## 3. Root cause

**Componente 1 — `_cancelNavigationHandled` bloqueado por datos obsoletos del ViewModel
(timer_screen.dart:680-682):**
`pomodoroViewModelProvider` es `NotifierProvider.autoDispose` no parametrizado por
groupId — singleton global. Al navegar de G1 a G2, `_currentGroup` del ViewModel aún
contiene datos de G1 (status=canceled) durante el primer frame de build de G2. El check
de cancelación en `timer_screen.dart:680` dispara con datos de G1 (canceled), establece
`_cancelNavigationHandled = true` de forma permanente y lanza una excepción Flutter
("setState()/markNeedsBuild() called during build" — confirmado Chrome log línea 2238).
La navegación falla (excepción), pero el flag queda bloqueado. Todos los signals
posteriores de cancelación de G2 son descartados silenciosamente.

**Componente 2 — `_recoverFromServer()` sin condición de salida para grupo terminal
(session_sync_service.dart):**
Al cancelarse G2, el documento Firestore `activeSession/current` se elimina. El debounce
de 3s dispara `holdActive = true` y arranca `_recoverFromServer()`. Con `serverSession
== null`, el método solo programa un reintento cada 5s — no verifica si el grupo adjunto
está en estado terminal (`canceled`/`completed`). El hold nunca se limpia.
Confirmado en Chrome log: `hold-extend reason=recovery-failed` repetido cada ~5s durante
40+ segundos sin salida (líneas 2824–2875).

**Componente 3 — `stopTick()` potencialmente faltante en el handler de cancelación
(pomodoro_view_model.dart):**
Si `_timerService.stopTick()` no se llama al recibir `status=canceled` del grupo stream,
`isTickingCandidate` permanece `true`. Cuando llega el primer null de sesión post-
cancelación, `_onSessionNull()` entra en el path de debounce de 3s en vez del
quiet-clear path, contribuyendo al disparo del latch en una cancelación legítima.

---

## 4. Protocolo de validación

### Escenario A — Repro principal: G1→cancel→G2→cancel (ambos dispositivos)

**Precondiciones:**
- Dos dispositivos activos: Chrome (web) + iOS.
- Al menos dos grupos configurados (G1, G2).
- Ambos dispositivos logueados con la misma cuenta.

**Pasos:**
1. Iniciar G1 en Run Mode desde Chrome o iOS.
   Esperar que ambos dispositivos muestren el timer corriendo.
2. Cancelar G1 desde Chrome (menú → Cancelar grupo → confirmar).
   Resultado esperado: ambos dispositivos navegan a Groups Hub.
3. Inmediatamente (sin esperar), iniciar G2 desde la lista de grupos.
   Resultado esperado: ambos dispositivos navegan a la pantalla del timer de G2.
4. Verificar que Chrome toma ownership de G2 (confirmar en logs o UI).
5. Cancelar G2 desde Chrome (menú → Cancelar grupo → confirmar).

**Resultado esperado CON fix:** ambos dispositivos navegan a Groups Hub en ≤5s.
**Resultado sin fix (baseline 3cb2f6c):** ambos dispositivos quedan atascados en
"Syncing session..." indefinidamente — el overlay nunca desaparece.

**Signal de éxito en logs:**
- Ausencia de `hold-extend reason=recovery-failed` en loop tras cancelación de G2.
- Presencia de `clearHold` con razón `terminal-group` o similar.
- Navegación a `/groups` confirmada en ambos dispositivos.

### Escenario B — Cancelación simple sin re-plan (regresión)

**Precondiciones:** Igual que Escenario A.

**Pasos:**
1. Iniciar G1 en Run Mode desde Chrome.
2. Cancelar G1 directamente (sin iniciar G2 después).

**Resultado esperado:** ambos dispositivos navegan a Groups Hub en ≤3s.
No debe aparecer "Syncing session..." hold tras la cancelación.

**Signal de éxito en logs:**
- `Cancel nav: group stream canceled` en Chrome e iOS.
- Navegación a `/groups` en ≤3s.
- Ausencia de `hold entered after debounce`.

### Escenario C — Corte de red durante sesión activa (regresión AP-2)

**Precondiciones:** G1 corriendo en Chrome + iOS con ownership activo.

**Pasos:**
1. Con G1 corriendo, cortar la red de Chrome por ~5s y restaurar.

**Resultado esperado:** Chrome puede entrar brevemente en "Syncing session..."
(debounce 3s) pero debe auto-recuperarse en ≤10s sin acción del usuario.

**Signal de éxito en logs:**
- `[SessionSync] null stream while ticking — debounce started` seguido de
  `clearHold` (o stream recovery antes del debounce).
- No debe aparecer `hold-extend reason=recovery-failed` en loop.

---

## 5. Comandos de ejecución

```bash
# Chrome (web) — debug
flutter run -d chrome 2>&1 | tee docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_<commit>_chrome_debug.log

# iOS (iPhone 17 Pro) — debug
flutter run -d <ios-device-id> 2>&1 | tee docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_<commit>_ios_iPhone17Pro_debug.log
```

Sustituir `<commit>` con los primeros 7 caracteres del commit hash del fix.
Sustituir `<ios-device-id>` con el ID del dispositivo iOS (ver `flutter devices`).

---

## 6. Log analysis — quick scan

### Señales de que el bug AÚN está presente (sin fix):

```bash
# Hold infinito post-cancelación
grep "hold-extend reason=recovery-failed" <logfile>

# Flag bloqueado (flutter assertion exception en build)
grep "setState.*called during build\|markNeedsBuild.*called during build" <logfile>

# Hold entra pero nunca sale — si hold-enter sin clearHold posterior, el bug persiste
grep "hold-enter\|clearHold" <logfile>
```

### Señales de que el fix está funcionando:

```bash
# Salida limpia del hold por grupo terminal
grep "clearHold\|terminal\|group canceled\|group completed" <logfile>

# Navegación exitosa a Groups Hub tras cancelación de G2
grep "Cancel nav\|navigat.*groups\|GoRouter.*groups" <logfile>

# Hold sale en ≤10s tras debounce (Escenario A)
grep -A5 "hold-enter" <logfile>

# Ausencia de exception en timer_screen.dart
grep "Exception\|Error" <logfile> | grep "timer_screen"
```

---

## 7. Verificación local

- [x] `flutter analyze` → PASS (0 issues)
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS

---

## 8. Criterios de cierre

Para cerrar BUG-F25-H se requieren TODOS los siguientes:

1. **Escenario A PASS** en Chrome + iOS: ambos dispositivos navegan a Groups Hub en
   ≤5s tras cancelar G2 en el flujo G1→cancel→G2→cancel.
   Evidencia: logs muestran navegación y ausencia de `hold-extend` loop.
2. **Escenario B PASS** en Chrome + iOS: cancelación simple sin re-plan sigue
   funcionando correctamente (no hay regresión).
3. **Escenario C PASS** (o confirmación de no-regresión): corte de red breve no
   produce hold permanente.
4. **Local gate PASS**: `flutter analyze` PASS + 3 tests de regresión PASS.
5. **Sin nuevas excepciones Flutter** del tipo "setState/markNeedsBuild called during
   build" en `timer_screen.dart` relacionadas con la cancelación.

---

## 9. Status

**Closed/OK** — validación PASS 19/03/2026.

Escenario A PASS: Chrome cancela G2 → navegación a Groups Hub confirmada en ambos dispositivos.
Log evidence Chrome: `2026-03-19_f25h_ba8db6f_chrome_debug.log` líneas 2261 (cancel nav), 2265 (Groups Hub).
Log evidence iOS: `2026-03-19_f25h_ba8db6f_ios_iPhone17Pro_9A6B6687_debug.log` líneas 51753 (cancel reflejado), 51758 (Groups Hub).
Sin `hold entered after debounce` / sin `hold-extend reason=recovery-failed` / sin setState/build exception.

Escenario B PASS: cancelación simple de G1 sin re-plan → navegación correcta a Groups Hub.

Escenario C PASS: Chrome offline ~5s → recuperación sin "Syncing session..." permanente.
Sin null-stream latch ni loop de recovery. Log evidence Chrome: líneas 2283, 2284, 2286.

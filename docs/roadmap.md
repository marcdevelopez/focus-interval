# 📍 **Roadmap Oficial de Desarrollo — Focus Interval (MVP 1.0)**

**Versión inicial — 100% sincronizado con `/docs/specs.md`**

Este documento define el plan de desarrollo **paso a paso**, en orden cronológico, para implementar completamente la aplicación Focus Interval según las especificaciones oficiales del MVP 1.0.

La IA (ChatGPT) debe consultar este documento **SIEMPRE** antes de continuar el desarrollo, para mantener coherencia técnica y de progreso.

Este proyecto incluye un documento oficial de roles de equipo en:
[docs/team_roles.md](team_roles.md)

---

# 🟦 **Estado Global del Proyecto**

```
FASE ACTUAL: 10 — Editor de Tarea
NOTA: TimerScreen ya depende del ViewModel (sin timer local/config demo).
      PomodoroViewModel expuesto como Notifier auto-dispose y suscrito a la máquina.
      Estrategia Auth completada: Google Sign-In en iOS/Android/Web/Win/Linux; email/password en macOS.
      Firestore integrado por usuario autenticado; tareas aisladas por uid.
      Fase 7 (Firestore integrado) completada el 24/11/2025.
      Fase 8 (CRUD + stream reactivo) completada el 17/12/2025.
      Fase 9 (Lista reactiva) completada el 17/12/2025. Test pendiente en Windows.
```
Actualizarse en cada commit, si es necesario.

---

# 🧩 **Estructura General del Roadmap**

El desarrollo está dividido en **18 fases principales**, ordenadas de forma óptima para evitar bloqueos, errores y reescrituras.

Cada fase contiene:

- ✔ **Objetivo**
- ⚙️ **Tareas**
- 📌 **Condiciones de avance**
- 📁 **Archivos que se crearán o modificarán**

---

# [✔] **FASE 1 — Crear proyecto Flutter y estructura de carpetas (Copmpleta)**

### ✔ Objetivo

Inicializar el proyecto con la estructura base del repositorio.

### ⚙️ Tareas

- `flutter create focus_interval`
- Crear estructura:

```
lib/
  app/
  data/
  domain/
  presentation/
  widgets/
docs/
assets/sounds/
```

### 📌 Condiciones para avanzar

- Proyecto compila en macOS
- Rutas creadas correctamente
- README inicial creado

---

# [✔] **FASE 2 — Implementar la Máquina de Estados del Pomodoro (Completa)**

_(Corazón de la app)_

### ⚙️ Tareas

- Crear: `domain/pomodoro_machine.dart`
- Implementar estados:

  - idle
  - pomodoroRunning
  - shortBreakRunning
  - longBreakRunning
  - paused
  - finished

- Implementar transiciones exactas según documento ()
- Temporizador interno

### 📌 Condiciones

- Tests básicos funcionando
- Máquina de estados estable y predecible

---

# [✔] **FASE 3 — Reloj Circular Premium (Completa)**

_(UI principal del MVP)_

### ⚙️ Tareas

- Crear `widgets/timer_display.dart`
- Implementar:

  - Círculo principal
  - Progreso animado
  - Aguja rotatoria (–90° → 360°)
  - Movimiento suave estilo reloj

- Colores dinámicos según estado:

  - Rojo para pomodoro
  - Azul para descanso

### 📌 Condiciones

- Animación estable a 60 fps
- Se adapta a diferentes tamaños de ventana
- Renderizado perfecto sin pixelación

---

# [✔] **FASE 4 — Pantalla de Ejecución (UI + integración parcial) (Completada)**

### ⚙️ Tareas

- Crear `presentation/screens/timer_screen.dart`
- Colocar `timer_display` dentro
- Botones mínimos:

  - Pausar
  - Reanudar
  - Cancelar

### 📌 Condiciones

- Pantalla funcional
- Temporizador no conectado aún a Firestore

---

# **FASE 5 — Integración Riverpod (MVVM) (detallada en sub-fases)**

### [✔] **5.1 — Crear el ViewModel del Pomodoro (Completada parcialmente)**

- Crear `PomodoroViewModel` extendiendo `AutoDisposeNotifier<PomodoroState>`.
- Definir estado inicial usando `PomodoroState.idle()`.
- Incluir una única instancia interna de `PomodoroMachine`.
- Exponer métodos públicos:

  - `configureTask(...)`

- `start()`
- `pause()`
- `resume()`
- `cancel()`

- Migración a AutoDisposeNotifier completada en Fase 5.3.

### [✔] **5.2 — Conectar el stream de la máquina de estados (Completa)**

- Suscribirse al stream que emite los estados del Pomodoro.
- Mapear cada evento → actualizar `state = s`.
- Manejar `dispose()` correctamente para cerrar el stream.
- Asegurar que:

  - Pausa → mantiene progreso actual
  - Resume → continúa desde progreso
  - Cancel → vuelve a estado idle

### [✔] **5.3 — Unificar toda la lógica del temporizador dentro del ViewModel (Completa)**

- Eliminar el `Timer.periodic` manual de `TimerScreen`.
- Controlar el tiempo exclusivamente desde `PomodoroMachine`.
- Cualquier cambio (segundos restantes, progreso, fase) debe provenir del stream.
- Asegurar que el UI:

  - No calcula tiempo
  - No gestiona temporizadores
  - Se actualiza solo con `ref.watch(...)`

### 🟦 Estado real al 22/11/2025

- Providers principales (machine, vm, repos, lista, editor) están creados y compilando.
- `TaskListViewModel`, `TaskEditorViewModel` y pantallas asociadas funcionan correctamente.
- Dependencia `uuid` añadida para IDs de tareas.
- PomodoroViewModel expuesto con `NotifierProvider.autoDispose`, suscrito a `PomodoroMachine.stream`.
- TimerScreen sin configuración demo; carga la tarea real mediante `taskId` y usa el VM para estados.
- Subfase 5.3 completada; fase actual 8 (CRUD en curso).
- FASE 5.5 completada: TimerScreen conectado a tareas y popup final con color de finalización.
- Auth configurado: Google en iOS/Android/Web/Win/Linux y email/password en macOS. `firebase_options.dart` generado y bundles unificados (`com.marcdevelopez.focusinterval`).
- FASE 7 completada: repositorio Firestore activo por usuario autenticado, alternando a InMemory sin sesión; login/logout refresca tareas por uid.

### [✔] **5.4 — Crear los providers globales**

- `pomodoroViewModelProvider`
- `taskRepositoryProvider` (placeholder)
- `firebaseAuthProvider` y `firestoreProvider` (placeholders para Fase 6)
- Exportarlos todos desde `providers.dart`

### 🔄 Estado actualizado:

Providers placeholders creados (Fase 5.4 completada):

- firebaseAuthProvider
- firestoreProvider

Integración real pendiente para Fases 6–7.

### [✔] **5.5 — Refactorar TimerScreen (Completada)**

- Consumir estado desde Riverpod exclusivamente.
- Detectar transición a `PomodoroStatus.finished` mediante `ref.listen`.
- Eliminar totalmente la configuración demo.
- Preparar la pantalla para recibir una `PomodoroTask` real mediante `taskId`.
- Ajustar los botones dinámicos (Start/Pause/Resume/Cancel) a los métodos reales del ViewModel.
- Sincronizar la UI con el estado final:

  - Cambio de color del círculo
  - Mensaje “Tarea completada”
  - Popup final

### ✔ Condiciones

- La UI **no contiene ningún Timer** local.
- Todo el tiempo proviene del ViewModel.
- `TimerDisplay` se actualiza exclusivamente por Riverpod.
- `TimerScreen` funciona enteramente con lógica MVVM.
- La máquina de estados controla todo el ciclo Pomodoro/Descanso.
- Preparado para FASE 6 (Firebase Auth email/password en desktop).
- Reloj responde a cambios de estado
- Pausa/reanudar funciona correctamente

Estas subfases deben aparecer también en el **dev_log.md** conforme se vayan completando.

---

# [✔] **FASE 6 — Configurar Firebase Auth (Google en mobile/web/Win/Linux; Email/Password en macOS)**

### ⚙️ Tareas

- Integrar:

  - firebase_core
  - firebase_auth
  - google_sign_in (solo iOS/Android/Web/Windows/Linux)
  - flujo email/password para macOS

- Configurar:

  - macOS App ID
  - Windows config
  - Linux config

### 📌 Condiciones

- Login Google funcional en iOS/Android/Web/Windows/Linux
- Login email/password funcional en macOS
- UID persistente en app

### 📝 Mejoras pendientes (post-MVP)

- Recordar último email usado en cada dispositivo (almacenado localmente) y permitir autofill/gestores de contraseñas; nunca guardar la contraseña en texto plano.

---

# [✔] **FASE 7 — Integrar Firestore (completada 24/11/2025)**

### ⚙️ Tareas

- Crear `data/services/firestore_service.dart`
- Configurar rutas:

  ```
  users/{uid}/tasks/{taskId}
  ```

### 📌 Condiciones

- Firestore accesible
- Creación/lectura pruebas OK

---

# [✔] **FASE 8 — Implementar CRUD de Tareas (completada 17/12/2025)**

### ⚙️ Tareas

- Crear:

  - `task_repository.dart`

- Funciones:

  - addTask
  - updateTask
  - deleteTask
  - streamTasks

### 📌 Condiciones

- CRUD funcionando
- Datos persisten correctamente
- Lista de tareas actualizada en tiempo real vía stream del repositorio activo (Firestore o InMemory)

---

# [✔] **FASE 9 — Pantalla de Lista de Tareas (completada 17/12/2025)**

### ⚙️ Tareas

- Crear:

  - `task_list_screen.dart`
  - widget `task_card.dart`

- Mostrar:

  - Nombre
  - Duraciones
  - Total pomodoros

### 📌 Condiciones

- Lista actualizada en tiempo real

---

# 🚀 **FASE 10 — Editor de Tarea**

### ⚙️ Tareas

- Crear formulario:

  - Nombre
  - Duraciones
  - Total pomodoros
  - Intervalo de descanso largo
  - Sonidos (inicio de pomodoro, inicio de descanso; sonido final fijo por defecto en este MVP)

- Guardar en Firestore

### 📌 Condiciones

- Tareas editables completamente
- Selector de sonidos básico conectado (sin reproducción aún) y plan para implementar audio real en fase posterior

---

# 🚀 **FASE 11 — Audio de eventos (pendiente)**

### ⚙️ Tareas

- Añadir assets de sonido por defecto (inicio pomodoro, inicio descanso, fin de tarea).
- Integrar un servicio de audio y disparar sonidos en los eventos del Pomodoro.
- Configurar fallback silencioso en plataformas que no soporten reproducción.

### 📌 Condiciones

- Sonidos reproducidos en macOS/Android/Web para los eventos clave.
- Configuración de tareas respeta los sonidos seleccionados.

# 🚀 **FASE 11 — Conectar Editor → Lista → Ejecución**

### ⚙️ Tareas

- Pasar task seleccionada a `timer_screen`
- Cargar valores en el ViewModel

### 📌 Condiciones

- Ciclo completo funcionando

---

# 🚀 **FASE 12 — Sincronización en tiempo real del Pomodoro (multi-dispositivo)**

### ⚙️ Tareas

- Crear `PomodoroSession` (modelo + serialización) y `pomodoro_session_repository.dart` sobre Firestore (`users/{uid}/activeSession`).
- Exponer `pomodoroSessionRepositoryProvider` y dependencias necesarias (deviceId, helper de serverTimestamp).
- Extender `PomodoroViewModel` para publicar eventos start/pausa/reanudación/cancelación/cambio de fase/finalización en `activeSession` (un único escritor por `ownerDeviceId`).
- En TimerScreen, modo espejo: suscribirse a `activeSession` cuando no se es dueño y reflejar el estado calculando tiempo restante con `phaseStartedAt` + `phaseDurationSeconds`.
- Manejar conflictos: si ya existe sesión activa, permitir “Tomar control” (sobrescribir `ownerDeviceId`) o respetar la sesión remota.
- Limpiar `activeSession` al finalizar o cancelar la tarea.

### 📌 Condiciones

- Dos dispositivos con el mismo `uid` ven el mismo pomodoro en tiempo real (<1–2 s de retraso).
- Solo el dueño escribe; el resto muestra los cambios en vivo.
- Transiciones de fase, pausa/reanudación y finalización quedan persistidas y visibles al reabrir la app.

# 🚀 **FASE 13 — Sonidos y Notificaciones**

### ⚙️ Tareas

- Integrar `just_audio`
- Integrar `flutter_local_notifications`
- Añadir:

  - Inicio pomodoro
  - Fin pomodoro
  - Inicio descanso
  - Fin descanso
  - Finalización total (sonido especial)

### 📌 Condiciones

- Todos los sonidos funcionan
- Notificación final funciona en macOS/Win/Linux

---

# 🚀 **FASE 14 — Animación Final Obligatoria**

### ⚙️ Tareas

- Implementar:

  - Círculo verde/dorado completo
  - Texto grande “TAREA FINALIZADA”
  - Aguja detenida en 360°

- Animación suave

### 📌 Condiciones

- Totalmente fiel a especificaciones ()

---

# 🚀 **FASE 15 — Redimensionado + Responsive Completo**

### ⚙️ Tareas

- Implementar tamaño mínimo calculado dinámicamente
- Escalado proporcional del reloj
- Reacomodar botones
- Fondo negro completo

### 📌 Condiciones

- App usable desde ¼ de pantalla

---

# 🚀 **FASE 16 — Pruebas Unitarias y de Integración**

### ⚙️ Tareas

- Tests para máquina de estados
- Tests para lógica de pausa/reanudación
- Tests para finalización estricta

### 📌 Condiciones

- Test suite estable

---

# 🚀 **FASE 17 — Pulido UI / UX**

### ⚙️ Tareas

- Refactorizar widgets
- Ajustar sombras, padding, bordes
- Mantener estilo minimalista oscuro
- Recordar el último email usado en el dispositivo (almacenado localmente) y habilitar autofill/gestores de contraseñas; nunca guardar la contraseña en claro.

---

# 🚀 **FASE 18 — Preparación de Release Interno**

### ⚙️ Tareas

- Empaquetar app para:

  - macOS `.app`
  - Windows `.exe`
  - Linux `.AppImage`

- Crear instrucciones de instalación
- Test de ejecución en todas las plataformas

### 📌 Condiciones

- MVP 1.0 listo y funcional

---

# 🧾 **Notas Finales**

- Este documento **controla el orden obligatorio del desarrollo**.
- La IA debe usarlo **para avanzar paso a paso sin saltarse fases**.
- Cualquier modificación futura debe anotarse aquí y en `docs/dev_log.md`.

---

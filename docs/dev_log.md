# 📝 Focus Interval — Dev Log (MVP 1.0)

Historial cronológico del desarrollo del MVP usando bloques de trabajo.  
Cada bloque representa un avance significativo dentro de la misma jornada o sprint.

Este documento sirve para:

- Mantener trazabilidad real del progreso
- Alinear la arquitectura con el roadmap
- Informar a la IA del punto exacto del proyecto
- Servir como prueba profesional de trabajo con IA colaborativa
- Evidenciar cómo se construyó el MVP a ritmo acelerado

---

# 📍 Estado actual

Fase activa: **5.4 — Providers Firebase placeholders**  
Última actualización: **22/11/2025**

---

# 📅 Diario de desarrollo

# 🔹 Bloque 1 — Configuración inicial (21/11/2025)

### ✔ Trabajo realizado:

- Estructura inicial `/docs` creada
- Añadido `specs.md` completo
- Añadido `roadmap.md` completo

### 🧠 Decisiones tomadas:

- La animación final del reloj será **obligatoria** en el MVP
- El fondo será **100% negro**
- Ventana redimensionable con tamaño mínimo dinámico

### ⚠️ Problemas encontrados:

_(rellenar cuando ocurran)_

### 🎯 Próximos pasos:

- Crear proyecto Flutter
- Crear estructura base del proyecto (`lib/app`, `lib/data`, etc.)

---

# 🔹 Bloque 2 — Máquina de estados Pomodoro (21/11/2025)

### ✔ Trabajo realizado:

- Creada la máquina de estados completa (`pomodoro_machine.dart`)
- Probada manualmente con un test en `main.dart`
- Confirmado: los estados, transiciones y finalización estricta funcionan según specs
- Validado que la máquina rechaza configuraciones inválidas (valores <= 0)

### 🧠 Decisiones tomadas:

- Se ejecutarán tests ligeros directamente en consola por ahora
- La lógica permanece completamente independiente de UI y Firebase, tal como dicta la arquitectura

### ⚠️ Problemas encontrados:

- Configuración inicial con valores 0 generó excepción, pero era esperado

### 🎯 Próximos pasos:

- Crear el widget del reloj circular (FASE 3)
- Preparar la estructura de `timer_display.dart`
- Definir painter + animaciones base

---

# 🔹 Bloque 3 — Reloj circular premium (TimerDisplay) (21/11/2025)

### ✔ Trabajo realizado:

- Implementado el reloj circular completo (TimerDisplay)
- Animación continua 60fps con AnimationController
- Aguja en sentido horario estilo analógico
- Colores dinámicos: rojo, azul y verde/dorado al finalizar
- Diseño responsive según tamaño de ventana
- CustomPainter optimizado para escritorio
- Demostración visual funcional con controles Start/Pause/Resume/Cancel

### 🧠 Decisiones tomadas:

- Se prioriza animación premium continua según specs (no por ticks)
- TimerDisplay se mantiene independiente de UI principal
- Se validará la UI final del reloj dentro de la estructura MVVM

### 🎯 Próximos pasos:

- Crear estructura base de navegación y pantallas principales
- Implementar TimerScreen que integre TimerDisplay + lógica real

# 🔹 Bloque 4 — Pantalla TimerScreen + Navegación (21/11/2025)

### ✔ Trabajo realizado:

- Integrada `TimerScreen` con `TimerDisplay`
- Añadido reloj premium operativo con aguja animada
- Añadido minutero digital superior sin duplicados
- Añadida barra de controles dinámica (Start / Pause / Resume / Cancel)
- Sincronización parcial con Riverpod lograda
- Transición a pantalla de ejecución vía GoRouter
- Comportamiento final al terminar la tarea funcionando con popup

### 🧠 Decisiones tomadas:

- El ViewModel del Pomodoro se gestionará con Riverpod (FASE 5)
- La lógica de ejecución ahora depende de `pomodoro_view_model.dart`, no de pruebas locales
- La pantalla de ejecución reemplaza al demo provisional

### ⚠️ Problemas encontrados:

- Minutero duplicado en pantalla (resuelto)
- Import y parámetro inexistente `style:` dentro de `_CenterContent` (corregido)

### 🎯 Próximos pasos:

- Iniciar la FASE 5: Riverpod MVVM completo
- Crear estructura de estado global para tareas
- Preparar providers para Firebase Auth y Firestore (sin conectar aún)

# 🔹 Bloque 5 — Documentación de roles (22/11/2025)

### ✔ Trabajo realizado:

- Creado `docs/team_roles.md` con:
  - Lead Flutter Engineer (Marcos)
  - Staff AI Engineer (ChatGPT)
  - AI Implementation Engineer (Codex)
- Actualizado README para enlazarlo
- Añadida estructura profesional para reclutadores

### 🧠 Decisiones tomadas:

- Mantener este archivo como documento oficial del equipo IA+Humano
- Usarlo como referencia profesional en entrevistas

### 🎯 Próximos pasos:

- Finalizar FASE 5 (integración total con Riverpod)
- Preparar la FASE 6 (Firebase Auth)

# 🔹 Bloque 6 — Riverpod MVVM (Subfases 5.1 y 5.2) — 22/11/2025

### ✔ Trabajo realizado:

- Creado PomodoroViewModel con implementación inicial basada en `Notifier`
  (la migración a `AutoDisposeNotifier` queda pendiente para Fase 5.3).
- Conectado el stream principal de PomodoroMachine.
- Estados sincronizados correctamente con la UI mediante Riverpod.
- Primera versión estable de integración sin crashes.
- Corregido error “Tried to modify a provider while the widget tree was building”
  moviendo llamadas fuera de lifecycle.

### ❗ Estado real actualizado:

- **TimerScreen todavía contiene:**
  - `_clockTimer` local
  - `configureTask(...)` temporal en `initState`
- Esto será eliminado en la Fase **5.3** cuando toda la lógica pase al ViewModel.

### 🧠 Decisiones tomadas:

- Mantener `Notifier` temporalmente para evitar romper TimerScreen
  antes de realizar la migración completa.
- Aplazar la eliminación de timers locales hasta que el VM gestione de forma total
  progreso, segundos restantes y fases.

### 🎯 Próximos pasos:

- Completar la Fase **5.3**, moviendo TODA la lógica de tiempo al ViewModel.
- Migrar PomodoroViewModel a `AutoDisposeNotifier`.
- Eliminar por completo `_clockTimer` y la configuración demo de TimerScreen.

---

## 🔹 Bloque 7 — Sincronización real del estado del proyecto (22/11/2025)

### ✔ Trabajo realizado:

- Correcciones estructurales en `providers.dart`:

  - Añadido el import faltante de `pomodoro_task.dart`
  - Reparados errores de tipos en `taskListProvider` y `taskEditorProvider`

- Alineado el estado del código con Riverpod 2.x:

  - `TaskListViewModel` como `AsyncNotifier<List<PomodoroTask>>`
  - `TaskEditorViewModel` como `Notifier<PomodoroTask?>`

- Confirmado que la compilación vuelve a ser estable tras los fixes
- Revisada la estructura global de providers en la arquitectura MVVM

### 🧠 Decisiones tomadas:

- Mantener temporalmente `PomodoroViewModel` como `Notifier` mientras se completa la subfase 5.3
- Postergar la migración a `AutoDisposeNotifier` hasta que TimerScreen esté totalmente unificado con el ViewModel
- Priorizar coherencia entre roadmap y código REAL en lugar de seguir ciegamente la planificación previa

### ⚠️ Problemas encontrados:

- Varias inconsistencias entre código y roadmap causaban:

  - Tipos no reconocidos en generics
  - Providers desincronizados
  - Errores de compilación en cascada

### 🎯 Próximos pasos:

- Completar FASE 5.3: unificar reloj + temporizador + stream en el ViewModel
- Eliminar completamente la configuración demo de TimerScreen
- Actualizar PomodoroViewModel → `AutoDisposeNotifier` según roadmap

### 🔄 Ajustes importantes de documentación:

- Se han detectado discrepancias entre roadmap y código real.
- dev_log.md se ha actualizado para reflejar que:
  - PomodoroViewModel sigue siendo `Notifier` (no AutoDispose aún).
  - TimerScreen conserva lógica temporal (timer local + config demo).
- Todo esto será corregido durante la Fase 5.3.

# 🔹 Bloque 8 — Fase 5.3 (Unificación TimerScreen + ViewModel) — 22/11/2025

### ✔ Trabajo realizado:

- `pomodoroMachineProvider` ahora es `Provider.autoDispose` con cleanup en `onDispose`.
- `PomodoroViewModel` expuesto vía `NotifierProvider.autoDispose`, suscrito a `PomodoroMachine.stream` y limpiando la suscripción en `onDispose`.
- `TimerScreen` carga la tarea real mediante `loadTask(taskId)` y elimina la configuración demo.
- Hora del sistema restaurada con `_clockTimer` y `FontFeature` para dígitos tabulares en la appbar.

### 🧠 Decisiones:

- Mantener `_clockTimer` exclusivamente para la hora del sistema; toda la lógica del pomodoro vive en ViewModel/Machine.
- `loadTask` mapea `PomodoroTask` → `configureFromTask` para inicializar la máquina.

### 🎯 Próximos pasos:

- Añadir providers placeholders `firebaseAuthProvider` y `firestoreProvider` (Fase 5.4).
- Conectar TimerScreen con selección de tarea real desde lista/editor y estados finales (Fase 5.5).

---

# 🧾 Notas generales

- Actualiza este documento al **final de cada sesión de desarrollo**
- Usa viñetas cortas, no es narrativa larga
- Esto permite a la IA entrar en cualquier día y continuar directamente

---

# 🚀 Fin del archivo

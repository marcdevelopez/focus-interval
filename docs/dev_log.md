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

Fase activa: **8 — Implementar CRUD de Tareas**  
Última actualización: **28/11/2025**

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

# 🔹 Bloque 9 — Fase 5.4 (Placeholders Firebase) — 22/11/2025

### ✔ Trabajo realizado:

- Añadidos providers placeholders `firebaseAuthProvider` y `firestoreProvider` en `providers.dart` (referencias nulas, sin integración real).
- Dependencias `firebase_auth` y `cloud_firestore` añadidas al `pubspec.yaml` (pendiente integración real en fases 6–7).
- Mantenida la compatibilidad de imports con Riverpod (ocultando `Provider` en los imports de Firebase).

### 🎯 Próximos pasos:

- Implementar servicios reales de Auth/Firestore en `data/services` (Fases 6–7).
- Conectar TaskRepository a Firestore cuando se integren servicios reales.

---

# 🔹 Bloque 10 — Fase 5.5 (Refactor TimerScreen + conexión tareas) — 22/11/2025

### ✔ Trabajo realizado:

- TimerScreen carga la tarea real por `taskId`, muestra loader hasta configurarla y deshabilita Start si no carga.
- Manejo de tarea inexistente con snackbar + back automático.
- `ref.listen` integrado en build para detectar `PomodoroStatus.finished` y mostrar popup final.
- TimerDisplay fuerza progreso al 100% y color final (verde/dorado) en estado `finished`.

### 🧠 Decisiones:

- Mantener InMemoryTaskRepository como fuente de datos local mientras llega Firestore (Fase 6–7).
- Popup final cierra a la lista; se mostrará animación final en el círculo.

### 🎯 Próximos pasos:

- Iniciar Fase 6: configurar Firebase Auth (Google Sign-In) y providers reales.
- Conectar TaskRepository a Firestore cuando estén listos los servicios.

---

# 🔹 Bloque 11 — Fase 6 (Inicio Auth) — 23/11/2025

### ✔ Trabajo realizado:

- Añadido override para desactivar `google_sign_in` en macOS (se mantiene en Win/Linux/iOS/Android/Web).
- Creado esqueleto `FirebaseAuthService` (Google + email/password) y `FirestoreService` con stubs de seguridad.
- Providers expuestos para servicios (`firebaseAuthServiceProvider`, `firestoreServiceProvider`) usando stub por defecto hasta configurar credenciales reales.
- Bundle ID de macOS actualizado a `com.marcdevelopez.focusinterval` (unificar namespace).

### 🧠 Decisiones:

- Mantener stub para evitar crashes en local hasta configurar Firebase (en este bloque inicial).
- Estrategia Auth: Google Sign-In para iOS/Android/Web/Win/Linux; email/password para macOS.
- No se inicializa Firebase aún; integración real se hará con credenciales en fases 6–7.

### 🎯 Próximos pasos:

- Configurar Firebase Core/Auth con credenciales reales; usar email/password en macOS y Google en las demás.
- Sustituir los providers stub por las instancias reales una vez configurado Firebase.
- Ajustar bundle IDs en otras plataformas al namespace unificado cuando toque.

---

# 🔹 Bloque 12 — Fase 6 (Auth configurada) — 23/11/2025

### ✔ Trabajo realizado:

- Ejecutado FlutterFire con bundles unificados `com.marcdevelopez.focusinterval` (android/ios/macos/windows/web) y generado `firebase_options.dart`.
- Añadido `GoogleService-Info.plist` correcto al target macOS (Build Phases → Copy Bundle Resources) y eliminado duplicados.
- Providers apuntan a servicios reales (`FirebaseAuthService`, `FirebaseFirestoreService`); Firebase inicializa en `main.dart`.
- Estrategia Auth activa: Google en iOS/Android/Web/Windows, email/password en macOS.
- Config habilitada en consola: Google + Email/Password.

### 🧠 Decisiones:

- Reutilizar config web para Linux hasta generar app específica; sin UnsupportedError en `DefaultFirebaseOptions`.
- Mantener namespace único `com.marcdevelopez.focusinterval` en todas las plataformas.

### 🎯 Próximos pasos:

- Fase 7: integrar Firestore real y conectar repositorios a datos remotos.
- Añadir UI de login (email/password en macOS, Google en el resto) para validar flujos.

---

# 🔹 Bloque 13 — Fase 7 (Firestore integrado) — 24/11/2025

### ✔ Trabajo realizado:

- Creado `FirestoreTaskRepository` implementando `TaskRepository` sobre `users/{uid}/tasks`.
- `taskRepositoryProvider` alterna Firestore/InMemory según sesión; refresco de lista al cambiar usuario.
- Login/registro refresca tareas y logout invalida estado; tareas aisladas por uid.
- UI muestra email y botón de logout; repo de Firestore activo cuando hay usuario autenticado.

### 🧠 Decisiones:

- Mantener InMemory como fallback sin sesión.
- Reglas en Firestore para aislar datos por `uid` (aplicar en consola).

### 🎯 Próximos pasos:

- Fase 8: pulir CRUD/streams y conectar completamente UI con Firestore.

---

# 🔹 Bloque 14 — Fase 8 (Bugfix repositorio reactivo a Auth) — 28/11/2025

### ✔ Trabajo realizado:

- `AuthService` expone `authStateChanges` y `authStateProvider` escucha login/logout.
- `taskRepositoryProvider` se reconstruye al cambiar usuario y usa `FirestoreTaskRepository` cuando hay sesión.
- `TaskListViewModel` refresca la lista al cambiar de `uid`; las tareas ya se sincronizan entre dispositivos con el mismo email/contraseña.

### ⚠️ Problemas encontrados:

- El repo se instanciaba antes de login y quedaba en memoria local; las tareas no subían a Firestore ni se compartían entre plataformas.

### 🎯 Próximos pasos:

- Continuar Fase 8: CRUD completo y streams sobre Firestore.
- Re-crear tareas de prueba tras login para persistirlas en `users/{uid}/tasks`.

# 🔹 Bloque 15 — Fase 8 (CRUD reactivo con streams) — 17/12/2025

### ✔ Trabajo realizado:

- `TaskRepository` ahora expone `watchAll()`; InMemory y Firestore emiten cambios en tiempo real.
- `TaskListViewModel` se suscribe al stream del repo activo y actualiza la UI sin `refresh` manual.
- Eliminados refrescos forzados desde `LoginScreen` y `TaskEditorViewModel`; la lista depende solo del stream.

### 🧠 Decisiones tomadas:

- Mantener InMemory como fallback sin sesión, pero también con stream para coherencia y pruebas locales.
- Centralizar la fuente de verdad en `watchAll()` para reducir lecturas puntuales y evitar estados inconsistentes.

### 🎯 Próximos pasos:

- Validar latencia y errores de Firestore en streams; considerar manejo optimista para ediciones/borrados.
- Revisar validaciones del editor y estados de carga/errores en la lista.

# 🔹 Bloque 16 — Fase 9 (lista reactiva y UX login) — 17/12/2025

### ✔ Trabajo realizado:

- `InMemoryTaskRepository.watchAll()` ahora emite inmediatamente al suscribirse; evita loaders infinitos sin sesión.
- Ajustado `LoginScreen` con `SafeArea + SingleChildScrollView + padding` dinámico para eliminar el rectángulo de overflow al mostrar teclado en Android.
- Verificado en macOS, IOs, Android y Web: lista de tareas reactiva; loader desaparece sin sesión. Windows pendiente de prueba.

### 🧠 Decisiones tomadas:

- Mantener comportamiento reactivo en todos los repos (InMemory/Firestore) como fuente única de verdad.
- El login permanece con email/contraseña en macOS/Android/web; Google en web/desktop Win/Linux pendiente de probar.

### 🎯 Próximos pasos:

- Probar en Windows (Google Sign-In) y validar CRUD/streams.
- Iniciar Fase 10: revisar formulario del editor según roadmap (campos completos, sonidos) y pulir validaciones.

# 🔹 Bloque 17 — Fase 10 (validaciones editor) — 17/12/2025

### ✔ Trabajo realizado:

- `TaskEditorViewModel.load` devuelve `bool` y los flujos de edición muestran snackbar/cierran si la tarea no existe.
- Validación de negocio: el intervalo de descanso largo no puede superar el total de pomodoros; se bloquea el guardado y se informa al usuario.
- Manejo UX: al editar desde la lista, si falla la carga, se notifica y no navega al editor.
- Añadido selector de sonidos por evento en el editor (opciones placeholder, pendientes assets reales) y persistencia de strings en el modelo/repos.

### 🧠 Decisiones tomadas:

- Priorizar validaciones y UX del editor antes de añadir campos nuevos (p.ej. sonidos) en esta fase.
- Mantener el editor reactivo a repositorio activo (Firestore/InMemory) sin cambios adicionales.
- Reducir la configuración de sonidos a lo esencial (inicio pomodoro, inicio descanso) y dejar el sonido final como valor por defecto para evitar confusión.

### 🎯 Próximos pasos:

- Añadir selección de sonido (cuando tengamos assets/definición) y persistirlo en el modelo.
- Probar en Windows pendiente; si pasa, ajustar roadmap/dev_log con fecha.

# 🔹 Bloque 18 — Fase 10 (Editor completado) — 17/12/2025

### ✔ Trabajo realizado:

- Editor completo con sonidos configurables mínimos (inicio pomodoro, inicio descanso) y sonido final fijo por defecto.
- Validaciones de negocio activas y manejo de errores al cargar/editar tareas inexistentes.
- Roadmap actualizado: Fase 10 marcada como completada; Fase actual → 11 (audio de eventos).

### 🎯 Próximos pasos:

- Implementar reproducción de audio (Fase 11) con assets por defecto.
- Probar en Windows pendiente y ajustar documentación cuando se valide.

# 🔹 Bloque 19 — Fase 11 (Audio de eventos, setup) — 17/12/2025

### ✔ Trabajo realizado:

- Añadido `just_audio` y `SoundService` con mapa id→asset y fallback silencioso si falta el archivo.
- Integrado el servicio vía provider y callbacks del `PomodoroMachine` para disparar sonidos en: inicio pomodoro, inicio descanso, fin de tarea.
- Creada carpeta `assets/sounds/` con README e incluida en `pubspec.yaml`; pub get ejecutado.
- Añadidos los audios por defecto: `default_chime.mp3`, `default_chime_break.mp3`, `default_chime_finish.mp3`.

### 🧠 Decisiones tomadas:

- Mantener tres sonidos en el MVP: inicio pomodoro, inicio descanso y fin de tarea (fijo), evitando duplicidad con fin de descanso.
- Si el asset falta o falla la carga, se ignora y se registra en debug; no se muestra error al usuario.

### 🎯 Próximos pasos:

- Probar reproducción en macOS/Android/Web con los audios añadidos.
- Ajustar dev_log/roadmap con la fecha cuando se confirme la reproducción en plataformas.

---

# 🧾 Notas generales

- Actualiza este documento al **final de cada sesión de desarrollo**
- Usa viñetas cortas, no es narrativa larga
- Esto permite a la IA entrar en cualquier día y continuar directamente

---

# 🚀 Fin del archivo

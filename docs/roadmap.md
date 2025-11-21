# 📍 **Roadmap Oficial de Desarrollo — Focus Interval (MVP 1.0)**

**Versión inicial — 100% sincronizado con `/docs/specs.md`**

Este documento define el plan de desarrollo **paso a paso**, en orden cronológico, para implementar completamente la aplicación Focus Interval según las especificaciones oficiales del MVP 1.0.

La IA (ChatGPT) debe consultar este documento **SIEMPRE** antes de continuar el desarrollo, para mantener coherencia técnica y de progreso.

---

# 🟦 **Estado Global del Proyecto**

```
FASE ACTUAL: 3 — Crear el Reloj Circular Base
```

La IA deberá actualizar esta línea cuando tú lo indiques.

---

# 🧩 **Estructura General del Roadmap**

El desarrollo está dividido en **17 fases principales**, ordenadas de forma óptima para evitar bloqueos, errores y reescrituras.

Cada fase contiene:

- ✔ **Objetivo**
- ⚙️ **Tareas**
- 📌 **Condiciones de avance**
- 📁 **Archivos que se crearán o modificarán**

---

# 🚀 **FASE 1 — Crear proyecto Flutter y estructura de carpetas**

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

# 🚀 **FASE 2 — Implementar la Máquina de Estados del Pomodoro**

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

# 🚀 **FASE 3 — Crear el Reloj Circular Base**

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

# 🚀 **FASE 4 — Pantalla de Ejecución (UI + integración parcial)**

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

# 🚀 **FASE 5 — Integrar Riverpod (State Management)**

### ⚙️ Tareas

- Crear `pomodoro_view_model.dart`
- Conectar estado de la máquina con la UI
- Crear providers globales

### 📌 Condiciones

- Reloj responde a cambios de estado
- Pausa/reanudar funciona correctamente

---

# 🚀 **FASE 6 — Configurar Firebase Auth (Google Sign-In)**

### ⚙️ Tareas

- Integrar:

  - firebase_core
  - firebase_auth
  - google_sign_in

- Configurar:

  - macOS App ID
  - Windows config
  - Linux config

### 📌 Condiciones

- Login Google funcional
- UID persistente en app

---

# 🚀 **FASE 7 — Integrar Firestore**

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

# 🚀 **FASE 8 — Implementar CRUD de Tareas**

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

---

# 🚀 **FASE 9 — Pantalla de Lista de Tareas**

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
  - Sonidos

- Guardar en Firestore

### 📌 Condiciones

- Tareas editables completamente

---

# 🚀 **FASE 11 — Conectar Editor → Lista → Ejecución**

### ⚙️ Tareas

- Pasar task seleccionada a `timer_screen`
- Cargar valores en el ViewModel

### 📌 Condiciones

- Ciclo completo funcionando

---

# 🚀 **FASE 12 — Sonidos y Notificaciones**

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

# 🚀 **FASE 13 — Animación Final Obligatoria**

### ⚙️ Tareas

- Implementar:

  - Círculo verde/dorado completo
  - Texto grande “TAREA FINALIZADA”
  - Aguja detenida en 360°

- Animación suave

### 📌 Condiciones

- Totalmente fiel a especificaciones ()

---

# 🚀 **FASE 14 — Redimensionado + Responsive Completo**

### ⚙️ Tareas

- Implementar tamaño mínimo calculado dinámicamente
- Escalado proporcional del reloj
- Reacomodar botones
- Fondo negro completo

### 📌 Condiciones

- App usable desde ¼ de pantalla

---

# 🚀 **FASE 15 — Pruebas Unitarias y de Integración**

### ⚙️ Tareas

- Tests para máquina de estados
- Tests para lógica de pausa/reanudación
- Tests para finalización estricta

### 📌 Condiciones

- Test suite estable

---

# 🚀 **FASE 16 — Pulido UI / UX**

### ⚙️ Tareas

- Refactorizar widgets
- Ajustar sombras, padding, bordes
- Mantener estilo minimalista oscuro

---

# 🚀 **FASE 17 — Preparación de Release Interno**

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

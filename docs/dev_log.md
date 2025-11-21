# 📝 Focus Interval — Dev Log

Historial cronológico del desarrollo de la aplicación Focus Interval (MVP 1.0).

Este documento sirve como referencia diaria para:

- Saber en qué fase exacta se encuentra el proyecto
- Qué decisiones se han tomado
- Qué problemas se han encontrado
- Qué tareas quedan por completar
- Ayudar a la IA a continuar el trabajo sin pérdida de contexto

---

# 📍 Estado actual

Fase activa: **1 — Configuración inicial del proyecto**
Última actualización: _(rellenar manualmente)_

---

# 📅 Diario de desarrollo

## 🗓️ Día 1 — 21/11/2025

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

## 🗓️ Día 2 — 21/11/2025

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

## 🗓️ Día 3 — 21/11/2025

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

# 🧾 Notas generales

- Actualiza este documento al **final de cada sesión de desarrollo**
- Usa viñetas cortas, no es narrativa larga
- Esto permite a la IA entrar en cualquier día y continuar directamente

---

# 🚀 Fin del archivo

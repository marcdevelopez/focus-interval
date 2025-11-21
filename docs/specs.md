# 📘 **Especificaciones Funcionales – Aplicación de Pomodoro Multiplataforma (macOS / Windows / Linux)**

**Versión 1.0 — Documento MVP Completo**

---

# 🧭 **1. Descripción general del proyecto**

La aplicación es un **gestor avanzado de sesiones Pomodoro**, diseñada para **escritorio** en **macOS**, **Windows** y **Linux**, desarrollada completamente con **Flutter**.

El objetivo principal es permitir al usuario:

- Crear tareas Pomodoro totalmente configurables
- Guardarlas en la nube (Firestore)
- Reutilizarlas en cualquier dispositivo
- Ejecutarlas con precisión y sonidos personalizados
- Detener automáticamente la ejecución al completar todos los pomodoros
- Recibir alertas y notificaciones del sistema

La aplicación se sincroniza con **Firebase** mediante login con **Google / Gmail**.

---

# 🖥️ **2. Plataformas objetivo**

- macOS (Intel & Apple Silicon)
- Windows 10/11 Desktop
- Linux distros basadas en GTK (Ubuntu, Fedora, etc.)

---

# 🔥 **3. Tecnologías principales**

| Área                   | Tecnología                               |
| ---------------------- | ---------------------------------------- |
| Framework UI           | Flutter 3.x                              |
| Auth                   | Firebase Authentication (Google Sign-In) |
| Backend                | Firestore                                |
| Local Cache (opcional) | Hive                                     |
| State Management       | Riverpod                                 |
| Navigation             | GoRouter                                 |
| Audio                  | just_audio                               |
| Notifications          | flutter_local_notifications              |
| Logging                | logger                                   |
| Arquitectura           | MVVM (Model–View–ViewModel)              |

---

# 📦 **4. Arquitectura general**

```
lib/
├─ app/
│   ├─ router.dart
│   ├─ theme.dart
│   └─ app.dart
├─ data/
│   ├─ models/
│   │   └─ pomodoro_task.dart
│   ├─ repositories/
│   │   └─ task_repository.dart
│   └─ services/
│       ├─ firebase_auth_service.dart
│       ├─ firestore_service.dart
│       └─ sound_service.dart
├─ domain/
│   ├─ pomodoro_machine.dart
│   └─ validators.dart
├─ presentation/
│   ├─ screens/
│   │   ├─ login_screen.dart
│   │   ├─ task_list_screen.dart
│   │   ├─ task_editor_screen.dart
│   │   └─ timer_screen.dart
│   └─ widgets/
│       ├─ timer_display.dart
│       ├─ task_card.dart
│       └─ sound_selector.dart
└─ main.dart
```

---

# 🧩 **5. Modelo de datos**

## **5.1. Modelo `PomodoroTask`**

```dart
class PomodoroTask {
  String id;
  String name;

  int pomodoroDuration; // minutos
  int shortBreakDuration;
  int longBreakDuration;

  int totalPomodoros;
  int longBreakInterval; // cada cuántos pomodoros va el descanso largo

  String startSound;
  String endPomodoroSound;
  String startBreakSound;
  String endBreakSound;
  String finishTaskSound;

  DateTime createdAt;
  DateTime updatedAt;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.startSound,
    required this.endPomodoroSound,
    required this.startBreakSound,
    required this.endBreakSound,
    required this.finishTaskSound,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

# 🧠 **6. Lógica del Pomodoro (máquina de estados)**

## **6.1. Estados**

- `pomodoroRunning`
- `shortBreakRunning`
- `longBreakRunning`
- `paused`
- `finished`
- `idle`

## **6.2. Transiciones**

1. Iniciar pomodoro → `pomodoroRunning`
2. Terminar pomodoro:

   - Si el número actual % `longBreakInterval` == 0 → `longBreakRunning`
   - Si no → `shortBreakRunning`

3. Terminar descanso → siguiente pomodoro
4. Terminar el último pomodoro → `finished` + sonido final
5. Usuario puede:

   - Pausar
   - Reanudar
   - Cancelar

---

# 🔊 **7. Sistema de sonidos**

**Eventos con sonido configurable:**

| Evento                     | Sonido             |
| -------------------------- | ------------------ |
| Inicio de pomodoro         | `startSound`       |
| Fin de pomodoro            | `endPomodoroSound` |
| Inicio de descanso         | `startBreakSound`  |
| Fin de descanso            | `endBreakSound`    |
| Fin de todos los pomodoros | `finishTaskSound`  |

Formatos permitidos:

- `.mp3`
- `.wav`

Los sonidos pueden ser:

- Incluidos en la app (assets)
- O cargados por el usuario (local file picker)

---

# 💾 **8. Persistencia y sincronización**

### **8.1. Firestore (principal)**

```
users/{uid}/tasks/{taskId}
```

### **8.2. Hive (opcional)**

Tabla local `task_cache`:

- Carga instantánea
- Sincronización en background
- Modo offline

---

# 🔐 **9. Autenticación**

## **Login obligatorio**

Para acceder a la app:

- Botón: “Continuar con Google”
- Abre navegador o WebView
- Obtiene `uid`, `email`, `displayName`, `photoURL`

## **Persistencia**

La sesión permanece activa en todos los dispositivos.

---

# 🖼️ **10. Interfaz de usuario**

## **10.1. Pantalla de Login**

- Logo
- Botón Google
- Texto: “Sincroniza tus tareas en la nube”

---

## **10.2. Pantalla de Lista de Tareas**

- Lista tipo tarjetas
- Cada task muestra:

  - Nombre
  - Pomodoros totales
  - Duraciones

- Botones:

  - ▶ Ejecutar
  - ✏ Editar
  - 🗑 Eliminar

- Botón flotante **“+ Nueva tarea”**

---

## **10.3. Editor de Tarea**

Inputs:

- Nombre
- Duración Pomodoro (minutos)
- Duración descanso corto
- Duración descanso largo
- Total de pomodoros
- Intervalo para descanso largo
- Seleccionar sonidos para cada evento

Botones:

- Guardar
- Cancelar

---

## **10.4. Pantalla de Ejecución**

La pantalla de ejecución mostrará un **temporizador circular estilo reloj analógico**, con los siguientes requisitos visuales y funcionales:

### 🎯 **Elementos principales**

1. **Reloj circular grande** (al estilo “progress ring”).
2. **Aguja animada**:

   - Gira **en sentido horario**, como un reloj real.
   - Representa el tiempo restante del ciclo actual (pomodoro o descanso).

3. **Colores según el estado**:

   - **Rojo (#E53935)** → Pomodoro
   - **Azul (#1E88E5)** → Descanso corto o largo

4. **Borde circular externo** que muestra el progreso general del ciclo.
5. **Centro del reloj** muestra:

   - Tiempo restante (MM:SS)
   - Estado actual (“Pomodoro”, “Descanso corto”, “Descanso largo”)
   - Pomodoro actual / total

---

### 🎨 **Requisitos visuales del reloj**

#### **1. Círculo principal (progreso)**

- Grosor del trazo: 12–18 px
- Redondeado en los extremos
- Color dinámico (rojo/azul según estado)
- Debe animarse suavemente con `TweenAnimationBuilder` o `AnimationController`

#### **2. Aguja animada**

- Forma: línea fina desde el centro hacia el borde
- Longitud: 90% del radio
- Color: blanco o gris claro
- Movimiento: **rotación continua** basada en:

```
ángulo = 360° * (1 - (tiempoRestante / tiempoTotal))
```

- Refrescado a 60 fps (AnimationController)

---

### 🕒 **Lógica del movimiento de la aguja**

- Al iniciar un pomodoro o descanso, la aguja se coloca en la posición de las 12 (–90°).
- Gira gradualmente hasta cerrar el círculo completo al llegar a cero.
- En pomodoro → color rojo
- En descanso → color azul
- Al cambiar de estado:

  - Se reinicia la posición de la aguja
  - Cambia el color
  - Cambia el tiempo total

---

### 🔊 **Sonidos**

(ya definidos en tu documento original, se mantienen)

---

### 🧩 **Eventos que afectan al reloj**

| Evento           | Acción sobre el reloj                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| Iniciar pomodoro | Reset aguja, color rojo, animación hasta fin                                                      |
| Fin pomodoro     | Cambio a descanso (color azul), reset aguja                                                       |
| Fin descanso     | Cambio a pomodoro (color rojo), reset aguja                                                       |
| Pausar           | Congela animación                                                                                 |
| Reanudar         | Continúa animación                                                                                |
| Cancelar         | Detiene animación y vuelve al estado idle                                                         |
| Finalizar tarea  | Sonido especial + popup + animación final obligatoria (círculo verde/dorado + “TAREA FINALIZADA”) |

La animación final descrita en la sección 12 forma parte del comportamiento obligatorio y debe implementarse dentro del propio reloj circular.

---

## **10.5. Requisitos extra para Desktop (importante)**

- Debe funcionar en pantallas grandes sin pixelarse (usar `CustomPainter`).
- Debe permitir redimensionar la ventana y ajustar el tamaño del reloj automáticamente.
- Animación fluida a 60fps en macOS / Windows / Linux.

---

# **10.6. Requisitos avanzados de ventana, adaptabilidad y accesibilidad visual**

## 🖥️ **A. Ventana redimensionable (obligatorio)**

La aplicación debe permitir **redimensionar libremente la ventana** en macOS, Windows y Linux, con las siguientes reglas:

1. **Se debe permitir cambiar el tamaño horizontal y vertical** en tiempo real.
2. El contenido debe **adaptarse automáticamente** (responsive).
3. La ventana no debe colapsar ni romper la UI al reducir su tamaño.
4. El temporizador circular debe **escalar dinámicamente** según el tamaño disponible.

---

## 📏 **B. Tamaño mínimo de ventana**

Para garantizar que el reloj sea siempre visible:

- El tamaño mínimo permitido debe ser:

  - **¼ de la pantalla del usuario en la dimensión menor**
  - Esto equivale aproximadamente a:

    - 480×480 mínimo (si pantalla Full HD)
    - 640×640 mínimo (si pantalla 1440p)

El tamaño real mínimo debe calcularse dinámicamente usando:

```
minSize = screen.shortestSide / 4
```

Y la aplicación debe **bloquear** tamaños menores a este límite.

---

## 🎛️ **C. El reloj debe ser completamente responsive**

El temporizador circular debe:

1. Escalar proporcionalmente según el tamaño de la ventana.
2. Mantener siempre:

   - La aguja centrada
   - El círculo visible y completo
   - El texto central legible

3. No debe superponerse con botones ni textos al reducirse el tamaño.
4. Usar `LayoutBuilder` o `MediaQuery` para calcular tamaños basados en ancho/alto actual.

---

## ⏸️ **D. Función de pausa y reanudación (obligatoria)**

El usuario debe poder:

### **1. Pausar en cualquier momento**

- La aguja se congela.
- El temporizador se detiene.
- No se pierde el conteo actual.
- Se guarda el estado internamente en el ViewModel.

### **2. Reanudar cuando quiera**

- La aguja continúa desde el punto exacto.
- El tiempo restante y el estado se restauran sin saltos.

### **3. Indicadores visuales**

- Botón “Pausar” → se transforma en “Reanudar”.
- Icono de pausa visible dentro del reloj (opcional).

### **4. Comportamiento sonido/alertas**

- Pausar no emite sonido.
- Reanudar tampoco.
- Solo eventos naturales del ciclo emiten audio.

---

## 🌑 **E. Fondo totalmente negro (modo ahorro visual)**

El modo por defecto debe ser:

- **Fondo 100% negro (#000000)**
- Sin degradados
- Sin transparencias
- Textos y trazos del reloj en:

  - Blanco
  - Gris claro
  - Colores asignados (rojo/azul)

### Motivación:

- Reduce fatiga visual
- Ideal para trabajar con poca luz
- En monitores OLED (MacBook Pro modernos, monitores QD-OLED) ahorra energía
- En Linux/macOS/Windows proporciona sensación de app profesional de productividad

---

## 🎯 **F. Visibilidad garantizada del reloj**

Independientemente del tamaño de ventana:

- El reloj debe ocupar mínimo el **60% del ancho disponible**.
- Los controles (Pausar, Reanudar, Cancelar) deben reacomodarse para no invadir el círculo.
- El texto central debe tener tamaño mínimo de:

  - **32 px** para el tiempo
  - **18 px** para el estado

Si no cabe → se escala proporcionalmente, pero nunca desaparece.

---

# 🔔 **11. Notificaciones**

- Notificación al terminar cada pomodoro
- Notificación al finalizar la tarea completa
- Posible vibración si el sistema lo permite (Linux no, Windows/macOS sí ocasionalmente)

---

# 🚨 **12. Comportamiento clave obligatorio (versión ampliada y definitiva)**

### ✔ **Finalización automática estricta de la tarea**

Cuando el temporizador complete el **último pomodoro** de la tarea:

1. **La aplicación debe detenerse automáticamente**.

   - No debe iniciar otro descanso.
   - No debe iniciar un nuevo pomodoro.
   - No debe permitir que el temporizador siga corriendo.

2. Debe reproducir un **sonido final especial**, configurado por el usuario, diferente al resto de eventos.

3. Debe mostrar un **popup modal** con el mensaje:

   - “**Tarea completada**”
   - Información opcional: duración total trabajada, número de pomodoros completados.

4. Debe enviar una **notificación del sistema**:

   - macOS → Notification Center
   - Windows → Windows Notification
   - Linux → libnotify

5. El estado de la máquina de estados debe pasar obligatoriamente a:

   - `finished`

6. La pantalla del reloj debe:

   - Detener animación
   - Mantener la aguja en su posición final (360°)
   - Cambiar el color del círculo a **verde** o **dorado** (definido en la especificación del reloj)
   - Mostrar visualmente “**Tarea Finalizada**” en el centro del círculo

7. No debe permitir iniciar otra sesión automáticamente.
   El usuario debe pulsar:

   - “Cerrar”
   - “Volver a la lista de tareas”
   - “Iniciar nuevamente tarea” (opcional)

---

# 📈 **13. Funcionalidades futuras (no incluidas en el MVP)**

- Estadísticas (gráfico de tareas completadas por día/semana)
- Exportar tareas como archivo
- Widgets flotantes “always on top”
- Atajos de teclado globales
- Modo minimalista
- Modo oscuro/ligero personalizado

---

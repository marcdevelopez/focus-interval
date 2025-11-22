# 🟣 Guía de Uso de Codex — Flujo Perfecto para Trabajo Diario

Para que Codex analice SIEMPRE la versión real y actualizada del proyecto, usa esta secuencia **ANTES de preguntar por el estado del proyecto** o pedir diagnósticos.

---

## 🥇 1. Reset del índice

Resetea el contexto previo de Codex para asegurar que no haya basura o memoria de sesiones anteriores:

```perl
@codex reset index
```

---

## 🥈 2. Cargar la carpeta completa `lib`

Esto permite que Codex vea todo tu código real:

```kotlin
@codex open lib
```

---

## 🥉 3. Preguntar

Ahora sí, Codex analiza la versión verdadera del proyecto.

Ejemplos:

```text
¿Cómo ves el estado del proyecto?
¿Algún defecto?
¿Qué parte está pendiente según el roadmap?
```

Usa esta secuencia SIEMPRE que necesites análisis profundo del proyecto.

---

## 🟪 Nota personal

Este archivo debe revisarse cada cierto tiempo y actualizarse si cambia el flujo de trabajo para Codex o si se añaden nuevas herramientas.

---

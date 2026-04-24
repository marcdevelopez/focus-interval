## Nota para añadir a las specs — Preparación para sustitución futura de Firestore / backend de sincronización

### **Desacoplamiento obligatorio del backend de sincronización**

Aunque en la versión actual el proyecto use **Firestore como backend principal de persistencia y sincronización**, la arquitectura debe prepararse **antes del lanzamiento** para permitir, si fuera necesario, sustituir Firestore por otro backend de sincronización sin tener que rehacer la app completa. Esto es especialmente importante porque la app no usa Firestore solo para CRUD de datos, sino también para sincronización en tiempo real, ownership de sesión, heartbeats, time sync, revisión de sesión y coordinación entre dispositivos.

### **Objetivo**

El objetivo no es migrar ahora obligatoriamente a otro backend, sino **evitar que la app quede estructuralmente bloqueada a Firestore**. Debe quedar preparada para que, antes del lanzamiento o en una fase posterior, pueda adoptarse un backend propio u otro sistema de sincronización con un coste razonable.

---

## **Reglas obligatorias para los agentes**

### 1. **Firestore debe tratarse como implementación, no como contrato del dominio**

- No diseñar nuevas pantallas, viewmodels o lógica de dominio asumiendo Firestore como dependencia directa.
- Firestore debe quedar detrás de interfaces propias del proyecto.

### 2. **Prohibido acceder a Firestore directamente desde UI, screens, widgets o viewmodels**

Toda interacción con sincronización y persistencia debe pasar por capas específicas, por ejemplo:

- `TaskRepository`
- `TaskRunGroupRepository`
- `PomodoroSessionRepository`
- `SessionSyncService`
- `TimeSyncService`

Esto es coherente con la arquitectura ya definida en las specs y debe reforzarse en toda implementación futura.

### 3. **Separar claramente dominio, sincronización y proveedor**

Deben distinguirse estas capas:

- **Dominio**: reglas de Pomodoro, transiciones, ownership conceptual, conflictos, pausas, sesión, ejecución.
- **Sincronización**: protocolo de publicación, suscripción, heartbeats, time sync, ownership request, stale detection.
- **Proveedor**: Firestore/Firebase hoy; backend propio u otro proveedor mañana.

La lógica de negocio no debe depender de detalles concretos de Firestore.

### 4. **Encapsular la sincronización en un motor sustituible**

Toda la lógica de sincronización en tiempo real debe centralizarse en una capa explícita, por ejemplo:

- `SessionSyncEngine`
- `PomodoroRealtimeCoordinator`
- `SyncSessionService`

Esta capa será la única que conozca detalles como:

- snapshots remotos
- listeners
- timestamps remotos
- heartbeats
- ownership transfer
- resolución de staleness
- auto-claim

La UI no debe conocer esos detalles.

### 5. **No modelar el sistema alrededor de documentos Firestore**

Los modelos del dominio (`PomodoroTask`, `TaskRunGroup`, `PomodoroSession`, etc.) deben mantenerse como entidades del proyecto, no como reflejos de paths o documentos Firestore. Las transformaciones entre dominio y backend deben vivir en adapters/mappers.

### 6. **Sustituir dependencia implícita de `serverTimestamp` por abstracción de tiempo autoritativo**

Actualmente el diseño usa timestamps del servidor para sincronización y proyección temporal. Esa necesidad debe mantenerse, pero la fuente de tiempo debe abstraerse detrás de un servicio, por ejemplo:

- `AuthoritativeClock`
- `TimeAuthority`
- `ServerTimeProvider`

De este modo, Firestore `serverTimestamp` podrá cambiarse en el futuro por tiempo autoritativo de un backend propio.

### 7. **Toda operación multi-documento crítica debe abstraerse como comando de dominio**

Las operaciones hoy resueltas con batch/transaction de Firestore no deben estar embebidas en lógica de UI. Deben exponerse como operaciones de alto nivel, por ejemplo:

- `pauseSession()`
- `resumeSession()`
- `claimOwnershipIfStale()`
- `resolveLateStartConflict()`
- `completeSession()`

La implementación actual puede usar Firestore; una futura podrá usar API propia o comandos de servidor.

### 8. **Definir desde ya un contrato de sincronización independiente**

Debe existir un contrato interno claro para:

- publicación de sesión activa,
- observación de sesión,
- heartbeats,
- ownership requests,
- resolución de conflictos,
- actualización de grupos,
- limpieza de sesiones terminales.

Ese contrato debe estar documentado de forma que pueda implementarse tanto con Firestore como con otro backend.

### 9. **Preparar soporte para una futura migración gradual**

El sistema debe poder tolerar, si fuese necesario:

- doble escritura temporal,
- lectura desde una fuente y escritura en otra,
- coexistencia transitoria entre Firestore y un backend nuevo,
- migración progresiva por feature flag o por versión.

No es obligatorio implementarlo ya, pero la arquitectura no debe impedirlo.

### 10. **Evitar que los agentes introduzcan nuevo acoplamiento**

A partir de ahora, cualquier cambio que:

- añada acceso directo a Firestore desde presentation,
- haga depender el dominio de detalles de snapshot/path,
- mezcle lógica de ownership con UI,
- o asuma Firestore como única opción futura,

debe considerarse **arquitectónicamente incorrecto** y debe rechazarse.

---

## **Prioridades prácticas antes del lanzamiento**

Si no se va a migrar ahora, al menos debe hacerse esto antes de lanzar:

1. Revisar que los `repositories` sean la única puerta de entrada a datos remotos.
2. Crear una capa explícita de sincronización de sesión activa separada de Firestore.
3. Aislar time sync y ownership en servicios sustituibles.
4. Mover cualquier lógica Firestore-específica fuera de UI/viewmodels.
5. Documentar un contrato interno para futura implementación con backend propio.

---

## **Versión corta para dar a los agentes**

> A partir de ahora, Firestore debe tratarse como implementación inicial, no como dependencia estructural del dominio. No se permitirá acceso directo a Firestore desde UI, screens, widgets o viewmodels. Toda persistencia y sincronización deberá pasar por repositorios y servicios específicos. La lógica de sesión activa, ownership, heartbeats, time sync, revisiones y resolución de conflictos debe quedar encapsulada en una capa de sincronización sustituible, de forma que antes del lanzamiento o en el futuro pueda adoptarse otro backend sin rehacer la app completa. Cualquier cambio nuevo que aumente el acoplamiento a Firestore debe evitarse.

## **Remate para las specs**

Puedes cerrar esta nota con una frase como esta:

> **Decisión arquitectónica:** el proyecto mantiene Firestore como backend actual del MVP, pero la implementación deberá preservar la posibilidad real de sustituirlo por otro backend de sincronización antes del lanzamiento o en una evolución posterior, sin rediseñar la capa de presentación ni el dominio principal.

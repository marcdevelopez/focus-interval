# Git Strategy — Focus Interval

Last updated: 2026-03-14

---

## Active branches

| Branch | Base | Status | Purpose |
|--------|------|--------|---------|
| `main` | — | stable | Releases only. No bug-open merges. |
| `fix26-reopen-black-syncing-2026-03-09` | `main` | frozen (ancestro de refactor) | Historical — Phases 1–3 of Fix 26 first cycle. Do not modify. |
| `refactor-run-mode-sync-core` | `fix26-reopen-black-syncing-2026-03-09` | active, ahead 11+ | Phases 2–6 refactor + all diagnostics. Current working branch. |

### Relationship
```
main
 └─ fix26-reopen-black-syncing-2026-03-09  (b085ea6)  ← ancestro
     └─ refactor-run-mode-sync-core         (1b1dc33)  ← HEAD actual
         └─ rewrite-sync-architecture       (TBD)      ← próxima rama
```

`fix26-reopen-black-syncing-2026-03-09` está completamente contenida en
`refactor-run-mode-sync-core`. No hay trabajo en ella que no esté ya en la rama activa.

---

## Política de merge a main

**Nunca mergear a main con un bug P0 abierto.**

Criterio de apertura de PR a main:
1. Bug P0 (`P0-F26-001` o equivalente) cerrado con exact repro PASS.
2. Regression smoke PASS en todos los devices del proyecto.
3. Soak ≥4h sin `Syncing session...` irrecuperable.
4. `flutter analyze` sin errores. `flutter test` suite completa sin fallos.
5. `CLAUDE.md` actualizado con nuevos anti-patterns si los hay.

---

## Próximos pasos (2026-03-14)

### 1. Push de rama activa a origin

`refactor-run-mode-sync-core` está ahead 11 commits. Pushear antes de crear la nueva rama:

```bash
git push origin refactor-run-mode-sync-core
```

### 2. Crear rama de rewrite

Desde el HEAD actual (`1b1dc33`), crear:

```bash
git checkout -b rewrite-sync-architecture
git push -u origin rewrite-sync-architecture
```

No crear desde `main` — el rewrite parte de la base de diagnósticos y contratos
acumulados en `refactor-run-mode-sync-core`, que son necesarios para la nueva suite.

### 3. Congelar snapshot de referencia

Tag ligero del estado fallido como referencia histórica:

```bash
git tag fix26-phase6-failed-2026-03-14 1b1cb17e
git push origin fix26-phase6-failed-2026-03-14
```

(Actualizar hash si el HEAD ha avanzado antes de ejecutarlo.)

### 4. Flujo de trabajo en rewrite-sync-architecture

- Diseño de contratos en `docs/specs.md` primero (docs-first como siempre).
- Tests `[REWRITE-CORE]` antes de implementación.
- Tests `[PHASE*]` se conservan como regresión histórica; marcar los que sean
  "legacy patch behavior" con comentario `// LEGACY: pre-rewrite patch behavior`.
- Solo retirar tests legacy cuando los `[REWRITE-CORE]` cubran explícitamente el mismo riesgo.

### 5. Cierre de ramas antiguas

Solo cerrar `fix26-reopen-black-syncing-2026-03-09` y `refactor-run-mode-sync-core`
cuando el rewrite esté validado y mergeado a main. Mantenerlas como historial hasta entonces.

---

## Archivos auto-modificados por Flutter (no commitear cambios a estos)

| Archivo | Motivo | Solución |
|---------|--------|----------|
| `ios/Flutter/AppFrameworkInfo.plist` | `flutter run -d ios` elimina `MinimumOSVersion` en cada run | Commiteado sin `MinimumOSVersion` en `1b1dc33`; no tocar |

Si `flutter run` vuelve a marcar este archivo como modificado, la causa es un cambio
de versión del Flutter SDK en el entorno local. Solución: `git checkout -- ios/Flutter/AppFrameworkInfo.plist`
para descartar el cambio, o commitear la nueva versión generada si el SDK ha sido actualizado.

---

## Comandos de referencia rápida

```bash
# Ver estado de todas las ramas (local + remote)
git branch -vv --all

# Ver grafo de commits
git log --oneline --graph --decorate --all

# Descartar cambio en plist si vuelve a aparecer
git checkout -- ios/Flutter/AppFrameworkInfo.plist

# Push de rama activa
git push origin refactor-run-mode-sync-core

# Crear rama de rewrite (cuando sea el momento)
git checkout -b rewrite-sync-architecture
git push -u origin rewrite-sync-architecture
```

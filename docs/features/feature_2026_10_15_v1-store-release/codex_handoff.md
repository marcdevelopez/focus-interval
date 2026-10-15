# Handoff Claude → Codex — Respaldo, tests (BUG-036) e integración main → develop

Versión: **v2 (2026-10-15)**, tras la revisión de Codex · Autor: Claude
Estado: alcance AUTORIZADO por el owner = respaldo + integración `main` → `develop` (opción A) + reparación de
los 2 tests + versionar estos documentos de planificación (petición del owner del 15/10).
**NO autorizados:** D1, D2, D3 ni la clasificación de producto
(`docs_reconciliation_proposal.md` y `docs/nuevas-funcionalidades/2026-10-15_matriz_trazabilidad_notas_42.md`).
Ubicación: `docs/features/feature_2026_10_15_v1-store-release/` (junto a `feature_plan.md`).
Hasta el paso 1.3 (§3b) estos archivos están SIN SEGUIMIENTO en el repo: no borrarlos y no limpiar el
directorio (`git clean`).

Cambios respecto a v1:
- Procedimiento de recuperación corregido (§8).
- Comprobaciones de diff separadas: árbol idéntico antes de documentar / solo docs permitidos después (§3, §5).
- Respaldo ampliado y verificado, con instantánea del merge pendiente (§2).
- Nueva verificación obligatoria del 219/219 en la rama real (§4.5).
- Contexto posterior incorporado (§0.2).

---

## 0. Contexto

### 0.1 Estado de Git (verificado 2026-10-15)

- `develop` = `origin/develop` = `ff30e15` (divergencia `0 0`).
- `origin/main` = `65552c4`: 7 commits exclusivos, con contenido ya presente en `develop`
  (`b10fa02` ≡ `0cc20e0`, `547c6f7` ≡ `79727a4`).
- Rama local `fix/sync-main-into-develop`:
  - merge de `origin/main` iniciado y resuelto, **sin commit**;
  - `HEAD=ff30e15`, `MERGE_HEAD=65552c4`;
  - árbol del índice = `89374764fc36ce853968b224390d7558cd4528df` = árbol de `develop`.
- Tag publicado: `safety-20261015-develop-ff30e15-pre-main-sync` → `ff30e15`.
- Sin seguimiento en la raíz (personales, nunca añadir a git): `FOCUSINTERVAL-notas-todo.txt`,
  `chatgpt-chat.md`, `chat-claude.md`.
  Usar siempre `git add <ruta exacta>`; nunca `git add -A` ni `git add .`.
- Prompt del owner `*2 merge ?3` = 2 stashes antiguos · merge pendiente · 3 ficheros sin seguimiento.

### 0.2 Hechos establecidos después de la respuesta anterior de Claude

- **Entorno: diagnóstico cerrado.** Los síntomas del 14/10 ("Loading group", no guarda en Cuenta) se
  debían a ejecutar en debug con `APP_ENV=dev` (valor por defecto) sin emuladores. Evidencia en el log:
  `AppConfig: env=dev emulator=true host=localhost`, `Server fetch failed`.
- **Cuenta con Firebase real.** Funciona en el simulador de iOS y en el emulador de Android (logs).
  Login confirmado en el log de Android: líneas 185 y 474,
  `Notifying auth state listeners about user (...)`, dos cuentas distintas; cierres de sesión en 59 y 423.
- **Modo Local.** Comprobación manual del owner, sin log: crear tarea → grupo → ejecutar → segundo plano →
  primer plano continúa correctamente; los grupos se inician bien.
- **Samsung físico.** Funciona según el owner (comprobación manual, sin log).
- **Pendiente en la lista de regresión.** Cerrar la app del todo durante una sesión y reabrirla en frío.
- **Candidato abierto.** Bucle de montaje/desmontaje de Run Mode cuando el backend no responde. Visto con
  DEV sin emuladores; falta probarlo con Firebase real y modo avión.
- **Logs y normas.** Claude los guardó primero fuera del repo, sin hash y con fecha 14 (error).
  Ya están en `docs/features/feature_2026_10_15_v1-store-release/logs/`, con nombre normativo y fecha real:
  - `2026-10-15_envdev_noemu_ff30e15_ios_iPhone17Pro_debug.log`
  - `2026-10-15_envprod_ff30e15_ios_iPhone17Pro_debug.log`
  - `2026-10-15_envprod_ff30e15_android_emulator_debug.log`

  `*.log` está ignorado por `.gitignore`, así que para versionarlos hace falta `git add -f`, como con los
  42 logs que ya están en git. El repo es público y el log de Android contiene uids de Firebase. **El owner
  aprobó publicarlos el 15/10**: se añaden con `git add -f` en el paso 1.3 (§3b).
- **Archivos fuera de git, por diseño.**
  - Matriz de ideas del owner en `docs/nuevas-funcionalidades/`, carpeta privada ignorada por
    `.gitignore` (convención del owner).
  - Notas personales del owner en la raíz.
  - Ambos van en el respaldo (§2).
- **Propuesta pendiente del owner.** Configuración local de VS Code "focus_interval (prod-debug)" con
  `--dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`. `.vscode/` está ignorado por git.
  No ejecutar sin aprobación.

## 1. Regla obligatoria

- Leer `CLAUDE.md` §3–4 y `AGENTS.md` (puertas de integración, checklist no-loss).
- Este trabajo no toca `lib/`, ni listeners de sesión, ni lógica de temporizador.
- Claude revisa el diff de cada PR antes del merge.

## 2. Paso 1.1 — Respaldo verificado (antes de tocar Git)

La etiqueta protege solo el estado versionado. No incluye:
- archivos personales;
- evidencias ignoradas por git;
- documentos aún sin commit;
- la resolución del merge pendiente.

El destino `~/FocusInterval-backups/` está fuera del repo **a propósito**: una copia dentro de la misma
carpeta que protege no sirve, y se podría versionar por error. Después hay que llevarla **fuera del Mac**.

```bash
STAMP=2026-10-15; B=~/FocusInterval-backups; mkdir -p "$B"
cd ~/development/focus_interval

# 2.1 Archivos ignorados de docs/ — 408, sin .DS_Store:
#     404 evidencias + 3 logs de entorno + 1 matriz privada. 15 nombres con espacios → lista separada por NUL.
#     (sin grep: en este Mac `grep` es ugrep y `-z` significa otra cosa)
git ls-files --others --ignored --exclude-standard -z -- docs ':(exclude,glob)**/.DS_Store' > "$B/${STAMP}_evidencias.list0"
tr '\0' '\n' < "$B/${STAMP}_evidencias.list0" | wc -l                       # esperado: 408
tar --null -czf "$B/${STAMP}_evidencias_locales.tgz" -T "$B/${STAMP}_evidencias.list0"

# 2.2 Personales + documentos de planificación aún sin commit
tar -czf "$B/${STAMP}_personales_y_planificacion.tgz" \
  FOCUSINTERVAL-notas-todo.txt chatgpt-chat.md chat-claude.md .env.local \
  docs/features/feature_2026_10_15_v1-store-release docs/nuevas-funcionalidades

# 2.3 Instantánea recuperable del merge pendiente
mkdir -p "$B/${STAMP}_merge_snapshot"
cp .git/MERGE_HEAD .git/MERGE_MSG .git/MERGE_MODE "$B/${STAMP}_merge_snapshot/"
{ echo "HEAD=$(git rev-parse HEAD)"; echo "MERGE_HEAD=$(cat .git/MERGE_HEAD)"; \
  echo "INDEX_TREE=$(git write-tree)"; echo "DEVELOP_TREE=$(git rev-parse 'develop^{tree}')"; \
  echo "RESOLUTION=checkout --ours: docs/bugs/bug_log.md docs/dev_log.md docs/validation/validation_ledger.md"; \
} > "$B/${STAMP}_merge_snapshot/state.txt"

# 2.4 Integridad
tar -tzf "$B/${STAMP}_evidencias_locales.tgz" | wc -l                        # 408
tar -tzf "$B/${STAMP}_personales_y_planificacion.tgz" | grep -c -v '/$'      # 4 personales + 3 md + 3 logs + 1 matriz = 11
( cd "$B" && shasum -a 256 *.tgz > "${STAMP}_SHA256SUMS" && shasum -a 256 -c "${STAMP}_SHA256SUMS" )
ls -lh "$B"
```

Después, el owner copia `~/FocusInterval-backups/` fuera del Mac y confirma la copia. Hasta entonces no se excluye
ni se borra nada.

**Estado (15/10/2026 13:32) — PASO 1.1 EJECUTADO POR CLAUDE. Codex NO debe repetirlo.**

- Copia local: `~/FocusInterval-backups/2026-10-15_pre-v1-stage1/`. Recuentos 408 / 12 / 4 y `shasum -a 256 -c` OK.
  La instantánea del merge va como `2026-10-15_merge_snapshot.tgz`.
- Destino fuera del Mac: Google Drive del owner, carpeta restringida (solo el propietario)
  `JORNADA/DEVELOP/3_PROYECTO-PERSONAL/focus-interval/backups/2026-10-15_pre-v1-stage1/`, con un `LEEME` que
  explica el contexto.
- Enlaces exactos y sumas: `docs/nuevas-funcionalidades/registro_copias_seguridad.md` (privado; los enlaces de Drive
  no se publican).
- **Condición para el paso 1.2: CUMPLIDA (15/10).** El owner subió los 5 ficheros y Claude verificó en Drive que
  están, con tamaño idéntico al byte. El paso 1.2 puede empezar.

**Receta de reconstrucción del merge pendiente**, si se perdiera antes del paso 1.2. El resultado debe
dar `INDEX_TREE` = `89374764…`:
```bash
git switch -c fix/sync-main-into-develop ff30e15
git merge --no-ff --no-commit 65552c4
git checkout --ours -- docs/bugs/bug_log.md docs/dev_log.md docs/validation/validation_ledger.md
git add docs/bugs/bug_log.md docs/dev_log.md docs/validation/validation_ledger.md
git write-tree   # 89374764fc36ce853968b224390d7558cd4528df
```

## 3. Paso 1.2 — Cerrar el merge local (sin publicar)

```bash
cd ~/development/focus_interval
git branch --show-current                          # fix/sync-main-into-develop
git rev-parse --short MERGE_HEAD                   # 65552c4
test "$(git write-tree)" = "$(git rev-parse 'develop^{tree}')" && echo "ÁRBOL = develop"   # obligatorio
git commit -F - <<'EOF'
merge(git): integrate origin/main into develop lineage (PR #159/#160 ancestry)

main carried 7 commits not in develop: the no-op merge of PR #159 and
PR #160 (BUG-018 fix merged into main instead of develop on 2026-03-29).
BUG-018 runtime/test changes were already re-applied in develop via PR #164
(patch-equivalent: b10fa02 = 0cc20e0, 547c6f7 = 79727a4).

Conflicts in docs/bugs/bug_log.md, docs/dev_log.md and
docs/validation/validation_ledger.md resolved keeping develop versions
(newest Closed/OK states; BUG-018 sections content-identical, whitespace only).
Resulting tree is identical to develop (git diff develop = empty).
The BUG-018 closure narrative recorded on main (Block 671) is backfilled
in a follow-up dev_log block.
EOF
git log -1 --format='%H%n%P'                       # padres: ff30e15… 65552c4…
git diff develop --quiet && echo "sin diferencias con develop"   # obligatorio en este paso
```
NO hacer push. Opcional, recomendado: `git bundle create ~/FocusInterval-backups/2026-10-15_repo_tras_paso1_2.bundle --all`
(copia de todas las referencias, incluida la rama local con el merge).

## 3b. Paso 1.3 — Versionar los documentos de planificación (rama propia, solo docs)

Objetivo: que el plan, este handoff y la propuesta documental queden en git y en GitHub cuanto antes.
Petición del owner del 15/10. Es solo documentación de planificación y propuestas: **no aplica** ningún
cambio de specs, roadmap, backlog, ledger ni reglas.

```bash
git fetch origin --prune
git switch develop                                   # los archivos sin seguimiento viajan con el cambio de rama
git rev-list --left-right --count develop...origin/develop    # 0 0
git switch -c fix/docs-v1-release-program
F=docs/features/feature_2026_10_15_v1-store-release
git add "$F/feature_plan.md" "$F/codex_handoff.md" "$F/docs_reconciliation_proposal.md"
# Logs: publicación APROBADA por el owner (15/10). *.log está ignorado, así que hay que forzarlo:
git add -f "$F/logs/"*.log
# Añadir el Block 770 (§6.0) y actualizar "Last update" en la cabecera del dev_log
git add docs/dev_log.md
git diff --cached --name-only                        # solo los 3 .md + los 3 logs de la carpeta de la feature y docs/dev_log.md
git commit -m "docs(v1-release): add v1.0 store-release program plan, Stage 1 handoff and doc-reconciliation proposal"
git push -u origin fix/docs-v1-release-program        # desde aquí ya están a salvo en GitHub
gh pr create --base develop --head fix/docs-v1-release-program \
  --title "docs(v1-release): v1.0 store-release program workspace (plan, handoff, proposals)" \
  --body-file <plantilla completa; indicar que D1/D2/D3 NO quedan aprobados por este PR>
```

Claude revisa el PR y entonces `gh pr merge <n> --merge`.

**Este PR debe mergearse ANTES de crear la rama de tests (paso 1.4).** Si no, al volver a `develop` los
documentos ya versionados en la rama de docs desaparecerían de la copia de trabajo.

No incluir en este PR:
- `docs/nuevas-funcionalidades/` (privada e ignorada);
- las notas personales de la raíz;
- cualquier archivo de código.

## 4. Paso 1.4 — Fix de tests (BUG-036), rama propia (tras mergear el paso 1.3)

### 4.1 Rama y base
```bash
git fetch origin --prune
git switch develop
git rev-list --left-right --count develop...origin/develop    # 0 0
git switch -c fix/planning-screen-test-provider-scope
```

### 4.2 Por qué

`ecbe87e` (Corte A, 07/05/2026) añadió en `_TaskGroupPlanningScreenState._maxNoticeAllowed`, alcanzable
desde `initState` (`_applyNoticeSuggestion`), estas lecturas:
- `ref.read(taskRunGroupStreamProvider)`;
- `ref.read(activePomodoroSessionProvider)`;
- `ref.read(preRunNoticeMinutesProvider)`.

El harness de `test/presentation/task_group_planning_screen_test.dart` monta la pantalla sin `ProviderScope`,
lo que provoca `Bad state: No ProviderScope found` en 2 tests.

### 4.3 Cambio exacto

Único archivo: `test/presentation/task_group_planning_screen_test.dart`. Validado por Claude en una copia
aislada fuera del repo.

```diff
@@ imports
 import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:shared_preferences/shared_preferences.dart';

 import 'package:focus_interval/data/models/selected_sound.dart';
 import 'package:focus_interval/data/models/task_run_group.dart';
+import 'package:focus_interval/presentation/providers.dart';
 import 'package:focus_interval/presentation/screens/task_group_planning_screen.dart';
+import 'package:focus_interval/presentation/viewmodels/pre_run_notice_view_model.dart';

+class _FixedPreRunNoticeViewModel extends PreRunNoticeViewModel {
+  _FixedPreRunNoticeViewModel(this.value);
+
+  final int value;
+
+  @override
+  Future<int> build() async => value;
+}
+
@@ _pumpPlanningScreen
   await tester.pumpWidget(
-    MaterialApp(
-      home: TaskGroupPlanningScreen(args: _buildArgs(option: option)),
+    ProviderScope(
+      overrides: [
+        taskRunGroupStreamProvider.overrideWith(
+          (_) => Stream.value(const <TaskRunGroup>[]),
+        ),
+        activePomodoroSessionProvider.overrideWith((_) => null),
+        preRunNoticeMinutesProvider.overrideWith(
+          () => _FixedPreRunNoticeViewModel(0),
+        ),
+      ],
+      child: MaterialApp(
+        home: TaskGroupPlanningScreen(args: _buildArgs(option: option)),
+      ),
     ),
   );
```

### 4.4 Restricciones

- No tocar `lib/` ni otros tests.
- Aserciones intactas: ambos tests siguen esperando `find.textContaining('Adjusted end:')`.
- No ejecutar `flutter pub upgrade` ni modificar `pubspec.lock`.
- Ante cualquier diferencia de comportamiento, PARAR y reportar a Claude.

### 4.5 Validación en la rama real (obligatoria y registrada)

El 219/219 de la copia aislada no basta: hay que repetirlo aquí y registrar el resultado.

```bash
flutter analyze
flutter test test/presentation/task_group_planning_screen_test.dart     # 2/2
flutter test 2>&1 | tee ~/FocusInterval-backups/2026-10-15_bug036_fulltest.txt | tail -3   # esperado 219/219
git diff --name-only develop                                             # solo el archivo de test
```

### 4.6 Commits, en este orden

```bash
git add test/presentation/task_group_planning_screen_test.dart
git commit -m "test(planning): wrap planning screen tests in ProviderScope with deterministic overrides"
# anotar <TESTFIX_HASH>; aplicar los textos de §6.1–6.3 sustituyendo el hash
git add docs/bugs/bug_log.md docs/validation/validation_ledger.md docs/dev_log.md
git commit -m "docs(bug036): register and close planning-screen test harness regression"
git diff --name-only develop      # test + 3 docs; nada en lib/ ni en otras rutas de código
```

### 4.7 Publicación y PR

```bash
git push -u origin fix/planning-screen-test-provider-scope
git rev-list --left-right --count HEAD...origin/fix/planning-screen-test-provider-scope   # 0 0
gh pr create --base develop --head fix/planning-screen-test-provider-scope \
  --title "test(bug036): restore green full suite (planning screen ProviderScope harness)" \
  --body-file <plantilla .github/pull_request_template.md completa, con el resultado de §4.5>
```

Claude revisa el diff y entonces: `gh pr merge <n> --merge` (merge commit).

## 5. Paso 1.5 — Completar la integración

```bash
git fetch origin --prune
git switch fix/sync-main-into-develop
git merge --no-ff origin/develop -m "merge(git): sync fix/sync-main-into-develop with develop (BUG-036 test fix)"

# 5.1 Comprobación A — ANTES del bloque documental: árbol idéntico a develop
test "$(git rev-parse 'HEAD^{tree}')" = "$(git rev-parse 'origin/develop^{tree}')" && echo "ÁRBOL = develop"

# 5.2 Añadir el bloque 772 + cabecera (§6.4–6.5) y commit
git add docs/dev_log.md
git commit -m "docs(devlog): record main->develop integration, BUG-018 closure backfill and safe restore point"

# 5.3 Comprobación B — DESPUÉS del bloque documental: solo diferencias documentales permitidas
git diff --name-only origin/develop                   # debe listar ÚNICAMENTE docs/dev_log.md
git diff --quiet origin/develop -- lib test android ios macos web windows linux pubspec.yaml pubspec.lock analysis_options.yaml \
  && echo "sin cambios en código/tests/config"
git diff origin/develop -- docs/dev_log.md            # revisar a mano: solo bloque 772 + cabecera

flutter analyze
flutter test                                          # 219/219
git push -u origin fix/sync-main-into-develop
gh pr create --base develop --head fix/sync-main-into-develop \
  --title "chore(git): integrate main lineage into develop (PR #160 ancestry) + BUG-018 record backfill" \
  --body-file <plantilla completa>
```

Claude revisa y entonces: `gh pr merge <n> --merge`. **Nunca `--squash` ni `--rebase`.**

### 5.4 Paso 1.6 — Verificaciones posteriores

```bash
git fetch origin --prune
git merge-base --is-ancestor origin/main origin/develop && echo "main contenido en develop: OK"
git rev-list --count origin/develop..origin/main      # 0
git switch develop && git pull --ff-only
git rev-list --left-right --count develop...origin/develop    # 0 0
flutter test                                          # 219/219 sobre develop
```

Opcional, con aprobación: `git switch main && git merge --ff-only origin/main` (solo actualiza el `main`
local atrasado).

## 6. Textos documentales del alcance autorizado (inglés)

Bloques del dev_log, en orden de merge:
- 770: documentos de planificación (paso 1.3);
- 771: BUG-036 (paso 1.4);
- 772: integración (paso 1.5).

Si el orden cambia, renumerar antes del merge (regla no-loss).

### 6.0 `docs/dev_log.md` — Block 770 (paso 1.3, al final) + `Last update: **15/10/2026**`

```markdown
## Block 770 — v1.0 store-release program workspace created; environment diagnosis and safe restore point recorded (15/10/2026)

**Current branch intent:** Process docs — version the v1.0 store-release planning artifacts (no code; no spec/roadmap/backlog/ledger/rule changes).
**Branch:** `fix/docs-v1-release-program`
**Commit:** `<DOCS_HASH>`

### Work completed

- Added `docs/features/feature_2026_10_15_v1-store-release/` (owner-facing, written in Spanish):
  - `feature_plan.md` — master plan: owner decisions, approval status, ordered stages to the v1.0 store release.
  - `codex_handoff.md` — authorized Stage 1 handoff (backup, merge closure, BUG-036, main → develop integration, recovery procedure).
  - `docs_reconciliation_proposal.md` — proposed D1/D2/D3 documentation changes. **Not approved; nothing applied.**
  - `logs/` — environment diagnosis logs (15/10/2026), force-added (`*.log` is git-ignored); publication approved by the owner.
- Owner's private feature-notes matrix kept in `docs/nuevas-funcionalidades/` (git-ignored private folder, by owner convention).

### Environment diagnosis (15/10/2026)

- The 14/10 symptoms ("Loading group", data not saved in Account Mode) were caused by debug runs with the
  default `APP_ENV=dev` while no Firebase emulators were running (`AppConfig: env=dev emulator=true`).
- With `APP_ENV=prod` + `ALLOW_PROD_IN_DEBUG=true`: Account Mode works on the iOS simulator and the Android
  emulator (logs; explicit FirebaseAuth sign-ins in the Android log).
- Local Mode and the physical Samsung device work (owner manual checks, no logs).
- Open: cold app kill + reopen during a run (regression list); Run Mode mount/dispose loop when the backend is
  unreachable (candidate, pending reproduction with prod + airplane mode).

### Safe restore point

- Tag `safety-20261015-develop-ff30e15-pre-main-sync` → `ff30e15` (develop before resuming v1.0 work and before the
  main → develop integration; last validated state 08/05/2026). Pushed to origin on 15/10/2026.
- The tag covers versioned state only (not personal files, ignored evidence or uncommitted work). Those are in the
  off-machine backup created on 15/10/2026 13:32: owner's Google Drive, restricted folder
  `JORNADA/DEVELOP/3_PROYECTO-PERSONAL/focus-interval/backups/2026-10-15_pre-v1-stage1/` (README inside; links and
  checksums in the owner's private, git-ignored registry). Restore via revert PR or explicit restore commit PR (`codex_handoff.md` §8); never force-push
  `develop` and never "merge the old tag back".
```

### 6.1 `docs/bugs/bug_log.md` — al final, tras BUG-035

```markdown
## BUG-036 — Planning screen widget tests fail without ProviderScope after deterministic Corte A

ID: BUG-036
Date: 15/10/2026 (UTC+2)
Platforms: Automated test suite only (no runtime impact)
Context: Full-suite audit (13/10/2026) while resuming v1.0 work on develop `ff30e15`.

Symptom:

- `flutter test` reported 217 passed / 2 failed.
- Both tests in `test/presentation/task_group_planning_screen_test.dart` failed with
  `Bad state: No ProviderScope found`.

Root cause:

- Commit `ecbe87e` (Corte A, 07/05/2026) added provider reads in
  `_TaskGroupPlanningScreenState._maxNoticeAllowed`, reachable from `initState`
  through `_applyNoticeSuggestion`. The test harness still pumped the screen in a bare
  `MaterialApp` without `ProviderScope`.
- Only targeted suites were run after Corte A, so the full-suite regression went unnoticed.

Impact:

- Runtime: none expected (the app always mounts the screen under the root `ProviderScope`).
- Coverage: the inline `Adjusted end:` notice (schedule-by-range / schedule-by-total) was
  not verified by automated tests between 07/05/2026 and this fix.

Fix:

- Test-only: wrap the harness in `ProviderScope` with deterministic overrides
  (`taskRunGroupStreamProvider` → empty list, `activePomodoroSessionProvider` → null,
  `preRunNoticeMinutesProvider` → 0), mirroring `task_group_planning_screen_conflict_test.dart`.
- No `lib/` changes; assertions unchanged.

Validation:

- `flutter analyze` PASS.
- `flutter test test/presentation/task_group_planning_screen_test.dart` PASS (2/2).
- `flutter test` PASS (219/219) on branch `fix/planning-screen-test-provider-scope`.
- No device validation required (test harness only; no user-facing behavior change).

Status:

Closed/OK (15/10/2026). closed_commit_hash: `<TESTFIX_HASH>`.
```

### 6.2 `docs/validation/validation_ledger.md` — junto a BUGLOG-035

```markdown
- [x] ID: `BUGLOG-036` | Type: bug | Priority: P2 | Status: Closed/OK | Source: `docs/bugs/bug_log.md` (BUG-036), `test/presentation/task_group_planning_screen_test.dart:1` | Item: Planning screen widget tests failed with `No ProviderScope found` after Corte A (`ecbe87e`) added provider reads reachable from `initState`; harness now uses `ProviderScope` with deterministic overrides (test-only, no runtime change). | closed_commit_hash: `<TESTFIX_HASH>` | closed_commit_message: `test(planning): wrap planning screen tests in ProviderScope with deterministic overrides` | evidence: `flutter analyze` PASS; targeted test 2/2 PASS; full suite 219/219 PASS on the fix branch (15/10/2026).
```

### 6.3 `docs/dev_log.md` — Block 771 (al final) + cabecera

```markdown
## Block 771 — BUG-036 planning screen test harness fixed; full suite green (15/10/2026)

**Current branch intent:** Test-only fix for BUG-036 (no runtime or `lib/` changes).
**Branch:** `fix/planning-screen-test-provider-scope`
**Commit:** `<TESTFIX_HASH>`

### Work completed

- `test/presentation/task_group_planning_screen_test.dart`: harness wrapped in `ProviderScope`
  with deterministic overrides (empty groups stream, no active session, pre-run notice 0).
  Assertions unchanged.
- `docs/bugs/bug_log.md`: BUG-036 registered and closed.
- `docs/validation/validation_ledger.md`: BUGLOG-036 added as Closed/OK.

### Local verification (on the fix branch)

- `flutter analyze` -> PASS
- `flutter test test/presentation/task_group_planning_screen_test.dart` -> PASS (2/2)
- `flutter test` -> PASS (219/219)

### Process note

- Late detection cause: only targeted suites were run after Corte A (`ecbe87e`).
  A full-suite gate rule is proposed separately (process docs PR D2, pending owner approval).
```

En la cabecera: `Last update: **15/10/2026**` y `Last closed bug fix: **BUG-036 ...**`.

### 6.4 `docs/dev_log.md` — Block 772 (rama de integración, después de traer develop)

```markdown
## Block 772 — main → develop lineage integration; BUG-018 closure record backfilled; safe restore point (15/10/2026)

**Current branch intent:** Integration/process — reconcile `main` ancestry into `develop` without content changes.
**Branch:** `fix/sync-main-into-develop`
**Merge commit:** `<MERGE_HASH>` (parents `ff30e15` + `65552c4`)

### Context

- `origin/main` held 7 commits not in `develop`: the no-op merge of PR #159 and PR #160
  (BUG-018 merged into `main` instead of `develop` on 29/03/2026 — deviation from rule R-2).
- BUG-018 runtime/test changes were re-applied to `develop` via PR #164
  (patch-equivalent: `b10fa02` ≡ `0cc20e0`, `547c6f7` ≡ `79727a4`); the validation packet
  `docs/bugs/validation_bug018_2026_03_27/` is identical on both branches.
- Merge conflicts (`bug_log.md`, `dev_log.md`, `validation_ledger.md`) were resolved keeping the
  `develop` versions (newest Closed/OK states; BUG-018 sections content-identical, whitespace only).
  Tree identical to `develop` before this block (no code or test change).

### BUG-018 closure record (backfilled from `main`)

- On `main`, the BUG-018 closure was recorded as **Block 671** (commit `2c19f8e`, 27/03/2026).
  On `develop`, Block 671 is a different entry (BUG-016 docs-first plan). Both histories are preserved:
  `develop` Block 671 stays unchanged; the `main` record is reproduced verbatim below.

> (pegar aquí, citado con `>`, el bloque completo "## Block 671 — BUG-018 closed after Android
> long-background revalidation (27/03/2026)" tal como está en `git show origin/main:docs/dev_log.md`)

### Safe restore point

- Recorded in Block 770: tag `safety-20261015-develop-ff30e15-pre-main-sync` → `ff30e15` (develop before
  this integration). To undo this integration specifically: revert PR of its merge commit
  (`git revert -m 1 <this PR merge commit>`), as described in
  `docs/features/feature_2026_10_15_v1-store-release/codex_handoff.md` §8.

### Verification

- Before this block: tree identical to `origin/develop`.
- After this block: only `docs/dev_log.md` differs from `origin/develop`; no changes under code, tests or
  config paths.
- `flutter analyze` PASS; `flutter test` 219/219 PASS.
- After merge: `git merge-base --is-ancestor origin/main origin/develop` → true;
  `git rev-list --count origin/develop..origin/main` → 0.
```

### 6.5 Cabecera del dev_log tras el 772

`Current focus: **v1.0 store release — Phase 1 stabilization (main lineage integrated, full suite green)**`
y `Last update: **15/10/2026**`.

## 7. Fuera de este handoff (esperan aprobación)

- Configuración local de VS Code "prod-debug".
- Registrar candidatos a bug (D1.5).
- D1, D2 y D3 completos.
- Enlazar esta carpeta de feature en `docs/features/feature_backlog.md` (regla de AGENTS; va con D1).
- Clasificación de producto (`docs/nuevas-funcionalidades/2026-10-15_matriz_trazabilidad_notas_42.md`).
- (Decidido 15/10: el repo sigue siendo público; publicar el plan y los logs está aprobado.)

## 8. Procedimiento de recuperación (corregido)

**Error de v1:** crear una rama desde el tag antiguo y fusionarla en `develop` NO deshace nada, porque ese
commit ya es antepasado de `develop`. Las dos vías correctas, siempre mediante PR y sin force-push:

**A) Revertir merges concretos.** Sirve para deshacer integraciones identificables.

```bash
git fetch origin --prune
git switch -c restore/<motivo> origin/develop
git log --first-parent --merges --oneline safety-20261015-develop-ff30e15-pre-main-sync..origin/develop   # lista lo que entró
git revert -m 1 <merge-más-reciente>      # repetir del más reciente al más antiguo, uno por merge a deshacer
git diff --stat origin/develop            # qué se revierte
```

En el PR se detalla:
- qué merges/PR se revierten;
- qué se conserva: los merges no revertidos, y la documentación y evidencias posteriores si se excluyen;
- el resultado de `flutter analyze` y de `flutter test`.

Ojo: revertir un merge hace que, para Git, esos cambios "ya entraron". Para volver a traerlos más tarde
hay que revertir el revert.

**B) Commit explícito de restauración del árbol.** Sirve para volver a un estado completo conocido.

```bash
git switch -c restore/<motivo> origin/develop
git restore --source=safety-20261015-develop-ff30e15-pre-main-sync --staged --worktree -- .
# opcional: conservar la documentación posterior
#   git restore --source=origin/develop --staged --worktree -- docs/
git status --short                        # revisar archivos restaurados, modificados y eliminados
git commit -m "restore: tree to safety-20261015-develop-ff30e15-pre-main-sync (<motivo>)"
git diff --stat origin/develop
```

El PR enumera:
- los archivos revertidos;
- los que se conservan (por ejemplo `docs/`);
- los tests ejecutados.

La historia no se reescribe: todo queda trazado.

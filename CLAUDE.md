# Focus Interval — Mandatory Context for Claude & Codex

Read this file **before touching any code**. It contains architectural invariants and
anti-patterns confirmed by real production bugs. Violating these has caused repeated
irrecoverable `Syncing session...` freezes.

---

## 1. Mandatory pre-read before touching timer/sync code

If you are about to edit any of these files, read the listed docs first:

| File to edit | Must read first |
|---|---|
| `lib/presentation/viewmodels/pomodoro_view_model.dart` | This file + [Anti-patterns](#3-confirmed-anti-patterns-do-not-repeat) + [Guardrails](#4-implementation-guardrails) |
| `lib/data/services/time_sync_service.dart` | This file + [TimeSyncService rules](#5-timesyncservice-invariants) |
| `lib/data/repositories/firestore_pomodoro_session_repository.dart` | This file + [Stream null semantics](#3-confirmed-anti-patterns-do-not-repeat) |
| Any sync/ownership/session code | `docs/specs.md` sections 8–10 + [Guardrails](#4-implementation-guardrails) |

---

## 2. Project orientation

- **Specs**: `docs/specs.md` — authoritative source of truth for all behavior
- **Active bugs**: `docs/bugs/bug_log.md`
- **Validation ledger**: `docs/validation/validation_ledger.md` — all open/closed P0/P1/P2
- **Dev log**: `docs/dev_log.md` — full history, use to understand context of past decisions
- **Roadmap**: `docs/roadmap.md` — active phase and open bugs
- **Log commands**: `docs/bugs/README.md` — flutter run + tee templates per platform
- **Mandatory preflight gate**: before proposing "what's next", reconcile all
  non-closed `bug_log.md` entries against `validation_ledger.md`; if mismatch
  exists, sync ledger first and document it in `dev_log.md`.

Active branch: `develop` (created 2026-03-18; fix/feature branches merge here)
Production branch: `main`

---

## 3. Confirmed anti-patterns — DO NOT REPEAT

These patterns caused real production bugs. Each one has been confirmed in device logs.

### AP-1 — Canceling session subscriptions inside `build()` [CRITICAL]

**Bug caused:** Fix 26 regression (10/03/2026). Android stuck in `Syncing session...` for 40+ min.

**The bad pattern:**
```dart
// ❌ NEVER DO THIS inside build()
_sessionSub?.close();
_sessionSub = null;
_subscribeToRemoteSession();
```

**Why it is wrong:** Riverpod `build()` re-runs on every `ref.watch()`ed provider emission,
including Firebase Auth token refreshes (which are unrelated to session state). Canceling
`_sessionSub` here kills the live Firestore listener. The new listener emits `null` during
the auth reconnect window → `_sessionMissingWhileRunning = true` → permanent freeze.

**The correct pattern:**
- Keep `_sessionSub` lifecycle only in `ref.onDispose()`, `loadGroup`, and explicit
  mode-switch/resume handlers.
- For deduplication: `if (_sessionSub != null) return;` — guard the re-subscribe, never
  cancel the existing one from `build()`.
- Riverpod-managed subscriptions (`ref.listen`) need no manual lifecycle in `build()`.

---

### AP-2 — Treating stream `null` as authoritative session deletion [CRITICAL]

**Bug caused:** Original Fix 26 vulnerability — present even at baseline `961f7eb`.

**The bad pattern:**
```dart
// ❌ NEVER treat stream null as proof of deletion without grace period
if (session == null) {
  _sessionMissingWhileRunning = true;
  _clearRunningState();
}
```

**Why it is wrong:** `pomodoroSessionStreamProvider` emits `AsyncData<null>` for transient
reasons unrelated to session deletion:
- Firestore SDK cache miss during reconnect
- SDK state reset during brief offline window
- `fireImmediately: true` emits `null` before the first real snapshot arrives

**The correct pattern:**
- Always debounce: wait ≥3s before latching `_sessionMissingWhileRunning = true`.
- For recovery after latch: always include a server-fetch fallback (`preferServer: true`)
  to confirm actual state before any destructive clear.
- Specs rule: `docs/specs.md` lines 669–672 — do not clear on single lookup null.

---

### AP-3 — Recovery paths that only write, never read

**Bug caused:** Missing-session hold never recovering when another device holds ownership.

**The bad pattern:**
```dart
// ❌ Incomplete recovery: only tries to claim/write
await tryClaimSession(snapshot);
await publishSession(snapshot);
// if both fail silently (other device is owner) → permanent freeze
```

**The correct pattern:**
- Write-only recovery fails when another device is owner (correct by design).
- After write fails: fetch from server (`preferServer: true`) to discover current owner,
  then apply discovered snapshot to unfreeze the latch.
- The `_sessionMissingWhileRunning` latch MUST be clearable by a server fetch that
  confirms a valid active session exists, even if this device is not the owner.

---

### AP-4 — Timeline gate must not block missing-session hold exit

**Bug caused:** Fix 26 reopen (Block 564, commit `b085ea6`).

**The bad pattern:**
```dart
if (!shouldApplyTimeline) {
  if (ownershipMetaChanged) { _notifySessionMetaChanged(); }
  return; // ❌ wasMissing=true: overlay clears but timer stays frozen
}
```

**The correct pattern (per specs 10.4.8.b — single-shot bypass):**

When `wasMissing=true` and a valid snapshot arrives (groupId match, active
`isActiveExecution` status, concrete `AsyncData` value), bypass the gate entirely:
- Apply the snapshot to the timer projection (not just notify)
- Remove `Syncing session...` overlay
- Update timer countdown, ring, status boxes, task list — all in the same frame
- Reset applied watermarks (revision/updatedAt) to the exit snapshot values

After this one event the gate resumes normally.

**Note:** `b085ea6` is a partial fix — it clears the overlay but does NOT apply
the timeline to the timer. The refactor must complete this.

**See:** `docs/specs.md` section 10.4.8.b, decision table.

---

## 4. Implementation guardrails

### G-1 Subscription lifecycle
- `_sessionSub?.close()` and `_subscribeToRemoteSession()` → **only** in:
  `loadGroup`, `ref.onDispose()`, resume handlers, mode-switch handlers.
- **Never** in `build()`.

### G-2 Change isolation
- Listener lifecycle changes must be in a dedicated commit. No unrelated UI or routing
  edits in the same commit. This enables surgical rollback.

### G-3 Regression test before merge
- Any change to `_subscribeToRemoteSession`, `_sessionMissingWhileRunning`, or
  `build()` must include/refresh a test proving that a provider rebuild
  (auth/token refresh equivalent) does NOT drop session-listener continuity.

### G-4 Validation before closure
- Required: exact degraded-network repro PASS + ≥4h soak window.
- Soak must include at least one Firebase id-token refresh event in logs
  without ending in indefinite `Syncing session...`.

### G-5 Stop-the-line
- If any run reproduces indefinite `Syncing session...` hold, stop new features,
  record logs, rollback the listener-lifecycle commit immediately.

### G-6 No destructive clear without corroboration
- Before calling any method that clears running state (`_clearRunningState`,
  `_sessionMissingWhileRunning = true` as permanent), first check:
  1. Is `wasMissing` already false? (stream recovered)
  2. Has `_groupRepo.getById` confirmed group is non-running?
  Only proceed if at least one corroborated signal exists.

---

## 5. TimeSyncService invariants

- Reject measurement when roundtrip > 3000ms.
- Reject abrupt offset jump > 5000ms delta when a previous offset exists.
- On rejection: keep previous offset, do NOT update last successful sync time.
- Apply 3s rejection cooldown to avoid tight retry loops on unstable network.
- These rules prevent offset-poisoning during reconnect (bug fixed in `418c75f`).

---

## 6. Specs coherence — known issues patched by Codex (2026-03)

Codex identified and patched 10 incoherencies in `docs/specs.md`. These are now aligned:
1. Write policy during `time sync unavailable` — unified (no contradictions)
2. Destructive clear rule — unified (no single-null-clear allowed)
3. `remainingSeconds` — compat/fallback only; timeline fields are authoritative
4. `actualStartTime` in `TaskRunGroup` model — now declared
5. `scheduledByDeviceId` ownership block — no longer split/broken
6. Reconciliation matrix `group.status` vs `session.status` — now explicit
7. "Source of truth for render" vs "timeline-anchored ranges" — prioritized
8. Finalisation without devices — aligned with modal completion in foreground
9. Sequencing (+1min vs round-up) — unified
10. `lastUpdatedAt` role (liveness vs tie-breaker) — explicit priority order

If you spot a contradiction in specs, **stop and report it before implementing**.
Do not resolve ambiguous spec sections by guessing — ask the user.

---

## 7. Testing commands

```bash
# Analyze + test before any PR/merge on session/timer code
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

---

## 8. AI agent roles — protocol for all three collaborators

This project uses three AI agents in a coordinated ecosystem. Each has a defined
role. **Do not overlap roles without explicit user approval.**

### Claude — Orchestrator and chief architect
- Receives the user's request and breaks it into tasks.
- Designs architecture, business logic, data-flow, and patterns (SOLID, DRY).
- **QA reviewer**: reads every Codex implementation before device validation.
  Never trust Codex's description — always read the actual `.dart` files.
- Resolves logical bugs where code "works" but business outcome is incorrect.
- Delegates to Gemini or Codex when appropriate. Has final say on design.

### Gemini — Context specialist and data analyst
- **When to invoke**: large-scale repository searches (entire codebase impact
  analysis), ingestion of large external docs (PDFs > 100 pages), analysis of
  heavy log files or JSON/CSV that exceed Claude's context, UI/UX screenshot
  analysis for visual bugs or design mock-ups.
- **When NOT to invoke**: single-file search, autocomplete, small code changes
  (use Codex or Claude directly — Gemini is slower).
- Gemini delivers a summary/report to Claude; Claude then plans and decides.

### Codex — Implementation engineer
- Writes the internal logic of functions, classes, and methods once Claude has
  defined the signature, purpose, and constraints.
- Writes unit/integration tests for isolated components.
- Converts code between languages or updates library syntax.
- Creates utility scripts (Bash/Python) for maintenance automation.
- **Does NOT make architectural decisions** — any structural suggestion from Codex
  must be validated by Claude before acceptance.
- **Reviews fix specifications before implementing.** Codex is a competent
  programmer, not a blind executor. If a handoff contains a technical error
  (wrong API, incorrect runtime assumption, logically insufficient fix), Codex
  must stop and report the error to Claude with a clear explanation before
  proceeding. Do not implement a spec that you know to be incorrect.

### Master workflow

```
1. User → Claude: feature or bug request
2. Claude → Gemini (if needed): "scan the full repo for impact of this change"
3. Claude: plans the attack with Gemini's report; writes spec/handoff
4. Claude → Codex: "implement these functions following this plan"
   → Codex reviews the spec first. If it spots a technical error, it reports
     it to Claude before implementing. Claude corrects and re-issues the handoff.
5. Claude: reads every modified .dart file, traces the flow, confirms correctness
6. Claude → user: ready for device validation
7. Gemini (optional close): confirms the resulting files are coherent with the system
```

---

## 9. Branching strategy — MANDATORY for all collaborators

This project uses a three-tier branching model. **All collaborators (Claude, Codex,
Gemini, human devs) must follow this model without exception.**

```
fix/xxx  or  feature/xxx
        ↓  (after device validation PASS)
     develop
        ↓  (only when zero known open P0/P1 bugs)
       main  (production)
```

### Rules — non-negotiable

**R-1 Never commit directly to `main` or `develop`.**
All work happens on short-lived branches (`fix/xxx`, `feature/xxx`).

**R-2 Fix/feature branches merge into `develop` only after device validation PASS.**
- `flutter analyze` must pass.
- All existing tests must pass.
- Device validation (Android + macOS minimum) must be documented in the
  corresponding validation folder with `quick_pass_checklist.md` marked PASS.

**R-3 `develop` merges into `main` only when zero known open P0/P1 bugs exist.**
- Check `docs/validation/validation_ledger.md` — no open `[ ]` P0/P1 entries.
- RVP roadmap items and P2 bugs do not block a `develop → main` merge.

**R-4 No known bug is ever silently skipped.**
- If a bug is discovered during a merge, stop, open a `fix/xxx` branch, fix it,
  validate it, then merge fix into `develop` before continuing.

**R-5 Before checking out any branch to implement:**
1. Run `git branch --show-current` to confirm you are NOT on `main` or `develop`.
2. If on `main` or `develop`, ask the user which branch to use.

**R-6 Branch naming:**
- Bug fixes: `fix/<short-description>` (e.g. `fix-ownership-cursor-stamp`)
- Features: `feature/<short-description>`
- Never use generic names like `patch`, `temp`, `wip`.

**R-7 Branch scope lock (mandatory):**
- A branch must keep one scope family only: bug fix, feature implementation,
  roadmap/validation closure, or process-governance docs.
- If the user asks for a different scope family, stop and create/switch to a
  dedicated branch before editing.

**R-8 Pre-commit branch check (mandatory):**
- Before each commit, confirm commit scope matches branch intent.
- If mismatch is detected, do not commit on the current branch; branch-split first.
- Before each commit, run `tools/check_doc_traceability.sh`.
- Commits must not introduce `pending-local` placeholders in:
  - `docs/dev_log.md` (`**Commit:**`)
  - `docs/validation/validation_ledger.md` (`closed_commit_hash`, `closed_commit_message`)
  - `docs/bugs/bug_log.md` (`closed_commit_hash`)

---

## 10. Validation folder structure — MANDATORY

Every bug fix or feature that requires device validation gets **one** validation folder
under `docs/bugs/`. The structure is fixed. Do not invent extra files.

### Folder naming

```
docs/bugs/validation_<bug-id>_YYYY_MM_DD/
```

Rules (non-negotiable):

- **`<bug-id>`**: normalized bug log ID in lower-case with hyphens removed.
  Derive from `docs/bugs/bug_log.md` ID field:
  `BUG-F25-E` → `f25e` · `BUG-F25-H` → `f25h` · `BUG-001` → `bug001`
- **Multiple bugs in one folder**: join with `_`.
  `BUG-001` + `BUG-002` → `bug001_bug002`
- **`YYYY_MM_DD`**: date the folder was created (underscores, not hyphens).
- **No `fix_` prefix.** No descriptive free names (no `ownership_cursor`,
  no `rounding`, no `phase6`). Bug ID is the only identifier.
- **No `-01` or `_b` date suffixes.** If you need two folders on the same day
  for different bugs, use their distinct bug IDs — they will already differ.
- **Grandfathered folders**: existing folders created before this convention
  (`validation_fix_2026_02_24`, `validation_ownership_cursor_2026_03_17`, etc.)
  keep their original names. Do not rename them.

Examples (correct):

```
validation_f25e_2026_03_19/
validation_f25g_2026_03_19/
validation_bug001_bug002_2026_03_17/
```

Examples (wrong — never use):

```
validation_fix_2026_03_19/         ← "fix_" prefix forbidden
validation_rounding_2026_03_19/    ← descriptive free name forbidden
validation_f25h_2026_03_19-01/     ← date suffix forbidden
```

### Permitted contents — exactly these, nothing else

```
validation_<name>_YYYY_MM_DD/
  plan_validacion_rapida_fix.md   ← living document (see below)
  quick_pass_checklist.md         ← checkboxes only
  codex_handoff.md                ← optional; created by Claude, consumed by Codex (see below)
  logs/                           ← .log files captured during runs
  screenshots/                    ← device screenshots used as evidence
```

**Never create additional `.md` files** beyond the three listed above (no `repro_steps.md`,
no `notes.md`, no `analysis.md`). Any non-handoff extra content goes inside
`plan_validacion_rapida_fix.md`.

### `plan_validacion_rapida_fix.md` — what it must contain

This is the single living document for the entire validation lifecycle.
It is updated in-place as evidence arrives. Required sections:

1. **Header**: date, branch, commit, bugs covered, devices.
2. **Objetivo**: one-paragraph scope.
3. **Síntoma original**: what the user sees without the fix.
4. **Root cause**: technical explanation (file + method level).
5. **Protocolo de validación**: numbered scenarios (A, B, C…) with exact
   preconditions, numbered steps, expected result, reference result without fix.
6. **Comandos de ejecución**: full `flutter run` commands with `tee` to
   the correct log path (see log naming below). Copy-pasteable, no placeholders.
7. **Log analysis — quick scan**: `grep` commands targeting the key signals for
   this specific bug. One block for "error present" signals, one for "fix working".
8. **Verificación local**: checklist of `flutter analyze` + `flutter test` results.
9. **Criterios de cierre**: explicit list of what must be PASS to close.
10. **Status** line (updated in-place): `Open` / `In validation` / `Closed/OK`.

Sections 5–7 are the ones most commonly omitted. They are not optional.

### `quick_pass_checklist.md` — what it must contain

Checkboxes only. No explanations, no repro steps. Example format:

```markdown
## Exact repro
- [ ] Scenario A PASS on owner+mirror.

## Regression smoke
- [ ] BUG-XXX still OK.
- [x] flutter test ... PASS.

## Local gate
- [x] flutter analyze PASS.

## Closure rule
Close only when all boxes above are checked with evidence.
```

### `codex_handoff.md` — what it must contain (optional file)

Created only when the fix requires Codex implementation (i.e. non-trivial code changes).
Written by Claude, consumed by Codex. Deleted or left as-is after implementation — it
is not updated with validation results (that belongs to `plan_validacion_rapida_fix.md`).

Required sections:

1. **Branch**: branch name to create/use.
2. **Reference commit**: baseline commit hash.
3. **Regla obligatoria**: reminder to read `CLAUDE.md` sections 3 and 4 before coding.
4. **Overview**: one paragraph — how many commits, which files, in what order.
5. **Per-fix sections** (one per commit): file path, why the change is needed,
   exact current code block (copy from source), exact replacement code block,
   constraints (what NOT to touch, what invariants to maintain).
6. **Commit order**: message template for each commit.
7. **Tests to run**: exact `flutter analyze` + `flutter test` commands. Must pass
   before handing back to Claude for QA review.

If a fix has only one line change and no invariant risk, the handoff can be in a
single section without per-fix subheadings.

### Log naming convention

```
YYYY-MM-DD_<fix-id>_<short-commit>_<device>_<mode>.log
```

- `<fix-id>`: short identifier, e.g. `f25d`, `ownership_cursor`, `f26_phase6`
- `<short-commit>`: 7-char commit hash, e.g. `07ac0cb`
- `<device>`: `android_RMX3771`, `macos`, `ios_iPhone17Pro_9A6B6687`, `chrome`
- `<mode>`: `debug` or `release`

Example: `2026-03-18_f25d_07ac0cb_android_RMX3771_debug.log`

---

## 11. Bug lifecycle — complete flow

Every bug follows this exact sequence. No step may be skipped.

```
0. PRE-FLIGHT SYNC
   → Scan docs/bugs/bug_log.md for non-closed statuses
   → Ensure each non-closed bug has an active entry in docs/validation/validation_ledger.md
      (stable ID, priority, status, source reference)
   → If mismatch exists: stop and sync ledger + dev_log before continuing

1. DISCOVERY
   → Add entry to docs/bugs/bug_log.md (status: Open, priority P0/P1/P2)
   → Add entry to docs/validation/validation_ledger.md (status: Open)

2. TRIAGE (Claude)
   → Confirm bug exists in current code (read the actual files, do not assume)
   → Explain: root cause + what the user sees/feels + proposed fix
   → Wait for user confirmation before implementing

3. IMPLEMENTATION (Codex)
   → Claude writes handoff: function signatures, constraints, expected behavior
   → Codex implements on fix/xxx or feature/xxx branch
   → Codex runs: flutter analyze + targeted flutter test suite

4. CLAUDE QA REVIEW (mandatory, before any device run)
   → Claude reads every modified .dart file
   → Traces the execution flow manually
   → Verifies guards: one-shot, dispose, stale-key, race conditions
   → Only after review: green light for device validation

5. VALIDATION FOLDER
   → Create docs/bugs/validation_<name>_YYYY_MM_DD/
   → Create plan_validacion_rapida_fix.md (sections 1–10 per section 10 above)
   → Create quick_pass_checklist.md
   → Create logs/ and screenshots/ directories

6. DEVICE VALIDATION
   → Run flutter run commands from plan (copy-paste, do not modify)
   → Save logs with correct naming convention
   → Update plan_validacion_rapida_fix.md with results in-place

7. CLOSURE (requires all 3)
   → Exact repro PASS (with log evidence)
   → Regression smoke PASS
   → Local gate PASS (flutter analyze + tests)
   Then:
   → Update bug_log.md: status = Closed/OK + closed_commit_hash
   → Update validation_ledger.md: status = Closed/OK + closed_commit_hash
   → Merge fix branch → develop (never directly to main)
   → Add Block to dev_log.md documenting the closure
   → Send user-facing closure recap per closed ID (concrete case validated:
     trigger/repro, expected behavior, PASS evidence) and ask for explicit
     final user confirmation

8. DEVELOP → MAIN
   → Only when validation_ledger.md shows zero open [ ] P0/P1 entries
   → P2 and RVP items do not block this merge
```

### Documents that must be updated at each step

| Step | Documents to update |
|---|---|
| Discovery | `bug_log.md`, `validation_ledger.md` |
| Implementation done | `bug_log.md` status → In validation; `roadmap.md` |
| Validation folder created | new `plan_validacion_rapida_fix.md`, `quick_pass_checklist.md` |
| Device run complete | `plan_validacion_rapida_fix.md` (results in-place) |
| Closure | `bug_log.md`, `validation_ledger.md`, `dev_log.md` |

---

## 12. When this file should be updated

- After each confirmed bug closure: add the anti-pattern summary to section 3.
- After each spec incoherence is patched: update section 6.
- When a new guardrail is confirmed necessary: add it to section 4.
- **Do not add speculative rules** — only add confirmed patterns from real incidents.

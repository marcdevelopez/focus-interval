# 🧭 Agent Guide — Focus Interval

This file defines **non-negotiable engineering rules** for developing Focus Interval.
Every human or AI agent must read and follow this document **before touching code**.

The purpose of this guide is to ensure the project remains:

- Scalable
- Modular
- Predictable
- Safe to evolve
- Free of architectural regressions and hard-to-debug errors

This file is authoritative.

---

## 1️⃣ Mandatory workflow (always)

At the start of **every session**:

1. Open and read:
   - `CLAUDE.md` (project root) — confirmed anti-patterns and implementation guardrails
   - `docs/specs.md`
   - `docs/roadmap.md`
   - `docs/dev_log.md`
   - `docs/bugs/bug_log.md` — canonical bug status source
   - `docs/validation/validation_ledger.md` — open P0/P1 items take priority over new phases
2. Confirm the **current real date** (e.g. `date` in terminal).
3. Verify in order:
   - Open `[ ]` P0/P1 items in `docs/validation/validation_ledger.md` (bugs AND RVP items)
   - Non-closed bug-log entries are mirrored in `docs/validation/validation_ledger.md`
     with stable IDs, priorities, statuses, and source references
   - Any **Reopened phases** in `docs/roadmap.md`
   - CURRENT PHASE in `docs/roadmap.md` — only after the above are clear
4. If a phase is reopened and not listed, **add it immediately** to:
   - 🔄 Reopened phases
5. Do **not** start coding until context is fully aligned.

Bug-priority preflight gate (hard rule):
- Before starting any validation, roadmap item, feature, refactor, or infra task:
  1. Scan `docs/bugs/bug_log.md` for all non-closed bugs.
  2. Ensure each one is present in `docs/validation/validation_ledger.md`.
  3. If any mismatch exists, stop and synchronize ledger + `docs/dev_log.md` first.
  4. Continue only after the bug queue is explicit and ordered by priority.

**"What's next" rule:** When asked what to do next, always cross-reference
`validation_ledger.md` + `roadmap.md` + tail of `dev_log.md`. Never answer from
the `CURRENT PHASE` label alone — pending validations and doc cleanup come first.
6. Before any implementation, explain the high-level plan and review it for incoherence or likely failure modes; wait for confirmation.
7. Ensure you are **not on `main`**; create a new branch before any code/doc changes.
8. If already on a branch, ensure your changes match the branch purpose/name; if not, commit the current work on that branch, then create a new branch for the unrelated change.
   - Branch-scope checkpoint (mandatory before any new commit):
     - Write one line in the working notes/dev update: `Current branch intent: <scope>`.
     - If the next change is a different scope family (bugfix vs roadmap validation vs process/docs governance vs feature), stop and switch to a dedicated branch first.
9. Dev log hygiene:
   - Append new blocks to the end of `docs/dev_log.md` in chronological order.
   - Block numbers must be strictly increasing and continue from the last block.
   - Update the "Last update" date whenever a new block is added.
10. Never push a branch that contains known bugs or unverified fixes. If there
    is not high confidence that a reported bug is resolved, do not push.
    Production policy: `main` must never contain known bugs.

Daily specs hygiene (hard rule):
- At least once per day, review `docs/specs.md` end-to-end to detect
  incoherencies, contradictions, or missing edge cases.
- If issues are found, record them immediately and propose fixes before
  implementing new behavior. Specs are the app's supreme source of truth.

## 1️⃣A Role Operating Model (Claude/Codex/Gemini) (hard rule)

Canonical role definitions, master workflow, and handoff protocol are maintained in:
- `docs/team_roles.md`

Operational split:
- **Claude**: orchestrator, architecture authority, and structural review (the "why/where").
- **Codex**: implementation, debugging, tests, and low-level correctness (the "how").
  Codex is not a blind executor — it reviews fix specifications before implementing.
  If the spec contains a technical error, Codex reports it to Claude before writing code.
- **Gemini**: full-repository context analysis, large-doc ingestion, cross-module impact scans.

Master workflow (standard path): user → Claude → Gemini (impact scan) → Claude (plan) → Codex (spec review + implementation) → Claude + Gemini (closure review).
Fast path for P0 bugs: skip Gemini step if it delays the fix; run full path after P0 is resolved.

Mandatory handoff contract (all directions):
- Context and scope
- Files changed
- Tests executed (exact commands + results)
- Known risks and open questions
- Explicit next action expected from the receiving role
- User-facing validation recap when closing items:
  - For each closed ID, explain the concrete validation case in plain language
    (trigger/repro, expected behavior, PASS evidence).
  - Ask the user for explicit final confirmation after presenting the recap.

Conflict rule:
- If architecture intent and implementation details diverge, stop and resolve via
  `docs/specs.md` + `docs/team_roles.md` before continuing.
- Claude has the final word on all design decisions regardless of source.

---

## 2️⃣ Documentation-first rule (hard rule)

Code **must never lead documentation**.

Before implementing or modifying behavior:

- Specs must already define it **or**
- Specs must be updated **first**

This includes:

- New flows
- Edge cases
- Error handling
- Platform-specific behavior
- Performance optimizations
- Sync logic
- UX decisions that affect state

If documentation and code diverge → **documentation wins**.

Additional requirement:
- If the user requests a change that is not yet in specs, the agent must
  proactively propose the spec update in the very next response and ask for
  confirmation. Do not ignore or defer the request without offering the
  documentation path forward.

Bug validation workflow (required):
- All validation artifacts live under `docs/bugs/validation_<bug-id>_YYYY_MM_DD`.
  - `<bug-id>`: normalized bug log ID in lower-case with hyphens removed.
    `BUG-F25-E` → `f25e` · `BUG-F25-H` → `f25h` · `BUG-001` → `bug001`
  - Multiple bugs in one folder: join IDs with `_`. `BUG-001` + `BUG-002` → `bug001_bug002`
  - **No `-01`/`-02` date suffixes.** If two folders cover different bugs on the same day,
    their distinct bug IDs already differentiate them.
  - Grandfathered folders keep their original names — do not rename them.
- Never delete validation subdirectories in `docs/bugs`. Keep them for traceability.
- Each validation folder must contain **exactly these — no other files**:
  - `plan_validacion_rapida_fix.md` — living document (see required sections below)
  - `quick_pass_checklist.md` — checkboxes only (see format below)
  - `codex_handoff.md` — **optional**; created by Claude, consumed by Codex; not updated with validation results
  - `logs/` — `.log` files from device runs (named per convention below)
  - `screenshots/` — device screenshots used as evidence
- **Never create additional `.md` files** beyond the three listed above
  (no `repro_steps.md`, no `notes.md`, no `analysis.md`).
  Any extra content belongs inside `plan_validacion_rapida_fix.md`.

Required sections of `plan_validacion_rapida_fix.md` (all mandatory):
  1. Header: date, branch, commit hash, bugs covered, target devices.
  2. Objetivo: one-paragraph scope.
  3. Síntoma original: what the user sees/feels without the fix (user perspective first).
  4. Root cause: technical explanation at file + method level.
  5. Protocolo de validación: labeled scenarios (A, B, C…) each with preconditions,
     numbered steps, expected result with fix, reference result without fix.
  6. Comandos de ejecución: full `flutter run … 2>&1 | tee <log-path>` commands,
     copy-pasteable, no placeholders. Use `docs/bugs/README.md` templates.
  7. Log analysis — quick scan: `grep` commands for the key signals of this bug.
     One block for "bug present" signals; one block for "fix working" signals.
  8. Verificación local: checklist of `flutter analyze` + targeted `flutter test` results.
  9. Criterios de cierre: explicit list of what must be PASS to close.
  10. Status line (updated in-place): `Open` / `In validation` / `Closed/OK`.

`quick_pass_checklist.md` format — checkboxes only, no repro steps:
  ## Exact repro / ## Regression smoke / ## Local gate / ## Closure rule

Log naming convention (mandatory):
  `YYYY-MM-DD_<fix-id>_<short-commit>_<device>_<mode>.log`
  Example: `2026-03-18_f25d_07ac0cb_android_RMX3771_debug.log`
  - `<fix-id>`: e.g. `f25d`, `ownership_cursor`
  - `<device>`: `android_RMX3771`, `macos`, `ios_iPhone17Pro_9A6B6687`, `chrome`
  - `<mode>`: `debug` or `release`

Fix closure requires all three conditions:
  1. Exact Repro PASS with log evidence.
  2. Regression smoke PASS.
  3. Evidence recorded in checklist + logs/screenshots.
When all three are met: update `plan_validacion_rapida_fix.md`, `quick_pass_checklist.md`,
`docs/bugs/bug_log.md`, `docs/validation/validation_ledger.md` to Closed/OK.
Then merge fix branch → `develop` (never to `main` directly).
Add a Block to `docs/dev_log.md` documenting the closure with commit hash.

Mandatory user-facing closure communication (all agents: Claude/Codex/Gemini/any AI):
- Before considering the closure fully done, provide a concise recap of each closed
  validation ID with the exact case validated (what was reproduced/checked and what PASS means).
- End by requesting explicit final user confirmation.

Always review screenshots in the validation folder before diagnosing or implementing fixes.
Full bug lifecycle detail: `CLAUDE.md` sections 10–11.

Feature planning workflow (required):
- All feature implementation artifacts live under `docs/features/feature_YYYY_MM_DD_slug`
  (use `feature_YYYY_MM_DD_slug-01`, `-02`, etc. for multiple feature tracks
  in the same day).
- Never delete feature subdirectories in `docs/features`. Keep them for
  traceability and regression history.
- Screenshots stay in the feature folder but are ignored by git.
- Each feature folder must include:
  - `feature_plan.md` (implementation plan)
  - `feature_checklist.md` (validation checklist, created after implementation)
  - `screenshots/` (when relevant)
- Every feature must be linked to `docs/features/feature_backlog.md` (reference the item
  or ID in the plan).
- In `docs/features/feature_backlog.md`, move the item to **In progress** (or
  **In implementation**) and add the link to the feature directory.
- When the feature is complete, move the item to **Done** (or
  `docs/features/feature_backlog_archive.md`) and record the final commit.
- After each feature or subfeature:
  - Update the plan to mark it completed.
  - Record the commit hash and commit message in the plan tracking entry.
  - Commit the change after updating the plan and supporting docs/logs.

Global validation ledger workflow (hard rule):
- Use a single active ledger for validation order and closure traceability:
  - `docs/validation/validation_ledger.md`
- This ledger is mandatory for **all** work types:
  - bugs, features, refactors, infra/process work.
- Every pending validation item must include, at minimum:
  - stable ID
  - type (`bug` / `feature` / `refactor` / `infra` / `process` / `roadmap`)
  - priority (`P0`, `P1`, etc.)
  - status (`Pending`, `In validation`, `Validated`, `Closed/OK`)
  - source path + line reference
- Stop-the-line rule (mandatory):
  - Do not start a new unrelated implementation before the current item is
    updated in the ledger and in its source docs (checklist/plan/roadmap).
  - If validation is incomplete, leave explicit status and blocker reason before
    switching context.
- Closure traceability (mandatory):
  - When any item is closed, record:
    - `closed_commit_hash`
    - `closed_commit_message`
    - evidence reference (logs/screenshots/checklist line)
  - If one implementation closes multiple items, close each ID explicitly.
- Priority execution order (mandatory):
  1. P0 blockers
  2. Active bug-log queue (all non-closed bug entries, ordered P1 then P2)
  3. Reopened-phase validation items
  4. Remaining historical pending validations
  - Do not start new feature work while open P0/P1 bug items remain unresolved.

---

## 3️⃣ Architecture invariants (must never be violated)

### 🧱 Layer boundaries (strict)

presentation/ → UI only
viewmodels/ → UI state & orchestration
domain/ → pure logic (no Flutter, no Firebase)
data/ → persistence & external services

Forbidden:

- UI screens calling repositories directly
- Domain logic importing Flutter, Riverpod, Firebase, or platform code
- Services depending on UI state

Allowed (current project reality):

- ViewModels may use **timers only for projection/rendering** (never authoritative decisions).
- UI may include **minimal platform guards** when there is no viable service-level alternative.
- App-level orchestration widgets may read repositories/providers for lifecycle or
  navigation control, but must not implement domain rules and should be migrated
  to ViewModel/service when feasible.

If unsure where code belongs → **stop and ask**.

### 🧠 Single source of truth (authoritative vs derived)

Authoritative logic lives in one place only:

- Pomodoro flow & rules → `PomodoroMachine`
- Execution orchestration → `PomodoroViewModel`
- Persistence & sync → repositories / Firestore
- Active execution authority (Account Mode) → Firestore `activeSession` owner
- Active execution authority (Local Mode) → local session owner (device-local)

Derived logic is allowed when it is:

- Read-only
- Deterministic
- Based exclusively on authoritative data

Forbidden duplication:

- Authoritative time ownership
- State transitions
- Conflict rules
- Scheduling decisions

If logic is _derived_, document it clearly as such.

---

## 4️⃣ State & time rules (authoritative vs derived)

### ⏱️ Time handling

- The **authoritative timeline** is owned by:
  - `PomodoroMachine`
  - Firestore timestamps (for sync)
- ViewModels may **project** time from authoritative sources.
- UI may:
  - Render system time
  - Render projections
  - Animate progress
  - Show previews

UI must never:

- Decide state transitions
- Own authoritative timers
- Persist time decisions

Local timers, tickers, or `DateTime.now()` are allowed **only for rendering or projection**, never as the source of truth.

- Any user-visible countdown or time-remaining display must update in real time
  while visible; stale time is unacceptable. These updates must remain
  projection-only and never drive authoritative state.

---

### 🔁 Deterministic state transitions

All **authoritative** state transitions must be:

- Explicit
- Reproducible
- Traceable

Derived transitions (UI reactions, animations, projections) do not require logging.

Whenever authoritative behavior changes, update:

- `docs/dev_log.md`
- `docs/roadmap.md` if phase scope is affected

---

## 5️⃣ Multi-device & sync rules

- Exactly one device is the **authoritative owner** of `activeSession`.
- Owner:
  - Writes authoritative state
- Mirror devices:
  - Never mutate authoritative state
  - Project progress from timestamps
  - May request explicit take-over only under defined rules

Ownership changes:

- Must be explicit
- Must be logged
- Must be justified by documented thresholds

No implicit ownership inference is allowed.

---

## 6️⃣ Local Mode vs Account Mode (scope safety)

Local and Account scopes are **intentionally isolated**.

Rules:

- No implicit sync
- No silent merges
- No shared authority
- No background imports

Import from Local → Account:

- Explicit user confirmation only
- Overwrite-by-ID (MVP rule)

Any change to scope behavior must be documented in `specs.md` first.

---

## 7️⃣ Platform discipline

Platform differences **must be isolated** inside:

- Services
- Adapters
- Guards

Never:

- Assume plugin availability
- Crash when a platform feature is missing

Fallback behavior:

- Must be silent
- Must log in debug
- Must preserve UX consistency

Minimal UI guards are permitted **only when no service-level alternative exists**.

---

## 8️⃣ Feature development protocol

**Three-tier branching model (mandatory):**

```
fix/xxx  or  feature/xxx
        ↓  (after device validation PASS)
     develop
        ↓  (only when zero known open P0/P1 bugs)
       main  (production)
```

Rules:
- **Never commit directly to `main` or `develop`.** All work on short-lived branches.
- Fix/feature branches merge into `develop` only after device validation PASS.
- `develop` merges into `main` only when `validation_ledger.md` shows zero open P0/P1 bugs.
- Before checking out any branch: run `git branch --show-current` to confirm you are NOT on `main` or `develop`. If you are, ask the user which branch to use.
- Branch naming: `fix/<short-description>` or `feature/<short-description>`. Never generic names (`patch`, `temp`, `wip`).
- Branch scope lock: one branch = one scope family. Do not mix unrelated tracks in one branch
  (example of forbidden mix: roadmap validation closures + process-rule governance edits).
  If a new request changes scope family, create/switch branch before editing.

For every new feature or fix:

1. Create a **new branch** from `develop` (never from `main`).
2. Implement **only one logical change**
3. Ensure:
   - App compiles
   - Analyzer passes (run `flutter analyze`)
   - No known bugs remain
   - Change is verified (manual or automated) before commit/push
4. Update:
   - `docs/dev_log.md` (same real date)
   - `docs/roadmap.md` if phase status changes
5. Commit code + docs **together**
6. Open PR
7. Merge only after review

Never commit:

- Broken builds
- Half-implemented features
- “Temporary” hacks
- Debug-only logic without guards

Roadmap reconciliation & validation closure (mandatory):

- After completing any implementation (feature, fix, refactor, UX, sync, rules, or migration), re-open `docs/roadmap.md` and find the **exact matching line(s)** where the implementation belongs.
- Update all affected entries completely (status, wording, scope links, reopened items, and dependencies).
- If no exact line exists, add one in the correct chronological/phase position.
- If the implementation requires validation, run the validation **immediately after implementation** (do not defer).
- Use the corresponding validation workflow (`docs/bugs/...` or `docs/features/...`) and record evidence.
- Once validation passes, update roadmap status in an orderly way:
  - Replace/clear `validation pending` where applicable.
  - Mark the item explicitly as validated/completed.
  - Include real validation date and commit reference (hash + message) in roadmap/dev log tracking.
- Do not start unrelated work until roadmap + validation state are fully synchronized.

This rule is required to keep roadmap truth, validation traceability, and release safety aligned.

---

## 9️⃣ Regressions & reopen rule

If a change:

- Breaks an earlier phase
- Alters a completed behavior
- Requires revisiting past decisions

Then:

1. Reopen the phase in `docs/roadmap.md`
2. Treat it as **priority work**
3. Do not continue forward until resolved

Skipping this step creates hidden technical debt.

Additional regression rule:

- Do not remove, downgrade, or reposition existing UI/flows that were already
  implemented and validated without explicitly notifying the project owner and
  receiving approval, unless it is strictly required for a new delivery.

---

## 🔟 Language & consistency

- All code, comments, UI strings, and docs are **English only**.
- Exception: files/directories created by the project owner that are private and
  only visible to them may be written in Spanish.
- Naming must be:
  - Explicit
  - Consistent
  - Stable over time

Renaming core concepts requires:

- Spec update
- Global refactor
- Explicit justification

---

## 1️⃣0️⃣A Code quality & UI consistency (non-negotiable)

- Code must be clean, modular, and scalable by default.
- Prefer reusable components and shared styling utilities over ad-hoc UI.
- When a UI style is reused (e.g., SnackBar/Banner), create or plan a theme
  entry to keep the visual language unified.

---

## 1️⃣1️⃣ Release & safety checks

Before any release discussion:

- Confirm Android keystore is backed up
- Confirm Firebase project access
- Confirm bundle IDs are consistent
- Confirm platform stubs exist where features are unsupported

If unsure → **stop and verify**

---

## 1️⃣2️⃣ Production safety & data evolution

Production must remain backward compatible at all times.

Rules:

- All changes touching Firestore data, queries, rules, auth, or sync must follow `docs/release_safety.md`.
- Never remove, rename, or change the type of existing fields until old clients are effectively gone.
- Any new Firestore collection or document path requires updating `firestore.rules` and redeploying rules/indexes.
- Migrations must be additive, versioned (`dataVersion`), and staged (dual-read/dual-write + backfill).
- Rules changes must remain compatible with old and new clients; validate in emulator and STAGING.
- Release sequencing must avoid coupling breaking client + backend changes in one release.
- Use staged rollouts and keep a rollback plan.

---

## 1️⃣3️⃣ Session/sync confirmed anti-patterns (mandatory — do not repeat)

**Read `CLAUDE.md` (project root) for full details and code examples.**

These patterns caused irrecoverable `Syncing session...` freezes confirmed in production logs.
Violating any of them will re-introduce the same bugs.

### AP-1 — Never cancel `_sessionSub` inside `build()` [CRITICAL]

`build()` re-runs on every `ref.watch()` emission (including auth token refresh).
Canceling `_sessionSub` there kills the live Firestore listener. The reconnect emits
`null` → `_sessionMissingWhileRunning = true` → permanent freeze.

**Rule:** `_sessionSub?.close()` only in `ref.onDispose()`, `loadGroup`, explicit
mode-switch handlers, and resume handlers. Never in `build()`.

### AP-2 — Never treat stream `null` as authoritative session deletion

`pomodoroSessionStreamProvider` emits `AsyncData<null>` for transient reasons:
Firestore SDK cache miss, reconnect, `fireImmediately: true` before first snapshot.

**Rule:** Always debounce ≥3s before latching `_sessionMissingWhileRunning = true`.
Recovery must include a server-fetch fallback (`preferServer: true`) to confirm state.

### AP-3 — Recovery paths must read, not only write

A write-only recovery (`tryClaimSession` + `publishSession`) fails silently when
another device is owner. This permanently blocks the latch clearance.

**Rule:** After write fails, fetch from server to discover the current owner/session
and apply it to clear the latch — even if this device is not the owner.

### AP-4 — `!shouldApplyTimeline` gate must not block latch clearance

When `wasMissing=true` and a real snapshot arrives but fails the timeline gate,
the UI must still be notified or it stays permanently frozen.

**Rule:**
```dart
if (!shouldApplyTimeline) {
  if (ownershipMetaChanged || wasMissing) { _notifySessionMetaChanged(); }
  return;
}
```

### Implementation guardrails (summary)

- Listener lifecycle changes → dedicated commit, no mixed UI edits
- Any change to `_subscribeToRemoteSession` or `build()` → regression test proving
  provider rebuild (auth token refresh) does NOT drop session-listener continuity
- Before merge: exact degraded-network repro PASS + ≥4h soak window
- No destructive clear without corroborated evidence (group repo recheck + debounce)
- `TimeSyncService`: reject roundtrip >3s, reject offset jump >5s, 3s rejection cooldown

---

## 1️⃣4️⃣ Guiding principle

> **Focus Interval must remain predictable.**
>
> Predictable code scales.
> Predictable state syncs.
> Predictable systems survive growth.

If a change makes the system harder to reason about,
**it is the wrong change**, even if it works today.

---

End of AGENTS.md

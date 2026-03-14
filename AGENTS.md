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
2. Confirm the **current real date** (e.g. `date` in terminal).
3. Verify:
   - CURRENT PHASE in `docs/roadmap.md`
   - Any **Reopened phases**
4. If a phase is reopened and not listed, **add it immediately** to:
   - 🔄 Reopened phases
5. Do **not** start coding until context is fully aligned.
6. Before any implementation, explain the high-level plan and review it for incoherence or likely failure modes; wait for confirmation.
7. Ensure you are **not on `main`**; create a new branch before any code/doc changes.
8. If already on a branch, ensure your changes match the branch purpose/name; if not, commit the current work on that branch, then create a new branch for the unrelated change.
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
- All validation artifacts live under `docs/bugs/validation_fix_YYYY_MM_DD`
  (use `validation_fix_YYYY_MM_DD-01`, `-02`, etc. for multiple validations
  in the same day).
- Never delete validation subdirectories in `docs/bugs`. Keep them for traceability and regression history.
- Screenshots stay in the validation folder but are ignored by git.
- Each validation folder must include:
  - `quick_pass_checklist.md`
  - `plan_validacion_rapida_fix.md`
  - `screenshots/`
- Every fix must include an **Exact Repro** of the original bug scenario (steps,
  mode, device(s), timing, logs/screenshots). This repro must be executed as
  part of the rapid validation; otherwise the validation is incomplete.
- Every fix must include a **Regression smoke check** that re-tests the most
  recent critical fixes (3–5 items). If the regression list changes, update it
  in both `plan_validacion_rapida_fix.md` and `quick_pass_checklist.md`.
- Fix closure rule (mandatory): when a fix is implemented, validated with
  evidence, and no regressions are detected, mark it immediately as
  **Closed/OK** in the validation docs. Do this automatically; do not ask for
  extra confirmation.
- A fix can be closed only if these three conditions are true:
  - Exact Repro passes.
  - Regression smoke checks pass.
  - Evidence is recorded (at minimum checklist result + logs/screenshots when
    applicable).
- Always review the screenshots in the relevant validation folder before diagnosing or implementing fixes.
- `quick_pass_checklist.md` is created **after** implementation and must match
  the actual changes. For a brand new validation folder, it starts empty until
  the implementation is complete.
- `plan_validacion_rapida_fix.md` is updated by the agent based on the latest
  completed checklist and reported bugs.
- Keep validations isolated per folder; never mix evidence or steps across
  different validation dates.
- After each fix:
  - Update `plan_validacion_rapida_fix.md` to mark the fix as completed and note
    any order changes or new findings.
  - Run the appropriate tests (unit or integration) for the fix’s scope and
    only proceed if they pass.
  - Record the commit hash and commit message in the plan tracking entry.
  - Commit the fix **after** updating the plan and any supporting docs/logs.

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

Bug validation workflow (required):

- All validation artifacts live under `docs/bugs/validation_fix_YYYY_MM_DD`
  (use `validation_fix_YYYY_MM_DD-01`, `-02`, etc. for multiple validations
  in the same day).
- Never delete validation subdirectories in `docs/bugs`. Keep them for traceability and regression history.
- Screenshots stay in the validation folder but are ignored by git.
- Each validation folder must include:
  - `quick_pass_checklist.md`
  - `plan_validacion_rapida_fix.md`
  - `screenshots/`
- Every fix must include an **Exact Repro** of the original bug scenario (steps,
  mode, device(s), timing, logs/screenshots). This repro must be executed as
  part of the rapid validation; otherwise the validation is incomplete.
- Every fix must include a **Regression smoke check** that re-tests the most
  recent critical fixes (3–5 items). If the regression list changes, update it
  in both `plan_validacion_rapida_fix.md` and `quick_pass_checklist.md`.
- Fix closure rule (mandatory): when a fix is implemented, validated with
  evidence, and no regressions are detected, mark it immediately as
  **Closed/OK** in the validation docs. Do this automatically; do not ask for
  extra confirmation.
- A fix can be closed only if these three conditions are true:
  - Exact Repro passes.
  - Regression smoke checks pass.
  - Evidence is recorded (at minimum checklist result + logs/screenshots when
    applicable).
- Always review the screenshots in the relevant validation folder before diagnosing or implementing fixes.
- `quick_pass_checklist.md` is created **after** implementation and must match
  the actual changes. For a brand new validation folder, it starts empty until
  the implementation is complete.
- `plan_validacion_rapida_fix.md` is updated by the agent based on the latest
  completed checklist and reported bugs.
- Keep validations isolated per folder; never mix evidence or steps across
  different validation dates.
- After each fix:
  - Update `plan_validacion_rapida_fix.md` to mark the fix as completed and note
    any order changes or new findings.
  - Run the appropriate tests (unit or integration) for the fix’s scope and
    only proceed if they pass.
  - Record the commit hash and commit message in the plan tracking entry.
  - Commit the fix **after** updating the plan and any supporting docs/logs.

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
  2. Reopened-phase validation items
  3. Remaining historical pending validations
  - Do not start new feature work while P0 validation blockers remain open.

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

For every new feature or fix:

1. Create a **new branch**
   - Never work directly on `main` (release branch).
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

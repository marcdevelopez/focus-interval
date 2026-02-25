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

Bug validation workflow (required):
- All validation artifacts live under `docs/bugs/validation_fix_YYYY_MM_DD`
  (use `validation_fix_YYYY_MM_DD-01`, `-02`, etc. for multiple validations
  in the same day).
- Each validation folder must include:
  - `quick_pass_checklist.md`
  - `plan_validacion_rapida_fix.md`
  - `screenshots/`
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
  - Commit the fix **after** updating the plan and any supporting docs/logs.

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

- All code, comments, UI strings, and docs are **English only**
- Naming must be:
  - Explicit
  - Consistent
  - Stable over time

Renaming core concepts requires:

- Spec update
- Global refactor
- Explicit justification

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

## 1️⃣3️⃣ Guiding principle

> **Focus Interval must remain predictable.**
>
> Predictable code scales.
> Predictable state syncs.
> Predictable systems survive growth.

If a change makes the system harder to reason about,
**it is the wrong change**, even if it works today.

---

End of AGENTS.md

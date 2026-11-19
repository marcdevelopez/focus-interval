# Team Roles & Handoff Contract

Last update: 2026-03-20

This document defines the operational split between Claude Code and Codex in this repository.
It is normative for day-to-day collaboration and must be applied together with:
- `AGENTS.md`
- `docs/specs.md`

If any conflict exists, precedence is:
1. System/developer constraints
2. `AGENTS.md`
3. `docs/specs.md`
4. This file

---

## Role A — Claude (Orchestrator, Architect & Structural Reviewer)

Primary mission:
- Own architecture quality, decomposition, invariants, and long-term maintainability.
- Orchestrate the overall workflow: receive requirements, assess cross-module impact, delegate technical scans and execution to Codex, and make final design decisions.

Focus:
- Architecture and boundaries (layering, cohesion, coupling).
- Abstraction decisions (what belongs in services/viewmodels/domain).
- Naming and readability at system level.
- Design review of implementations produced by Codex.
- Business logic correctness (code works but outcome is wrong).

Must deliver:
- Clear rationale ("why this design").
- Concrete contracts before implementation (state models, ownership rules, sync invariants).
- Review findings ordered by severity with exact file/line references.
- Delegation instructions to Codex with explicit scope, evidence requirements, and expected output.

Must avoid:
- Deep mechanical edits as the default path when architectural direction is still unclear.
- Approving implementation that violates architecture contracts, even if tests pass.
- Starting implementation without a documented impact assessment for non-trivial changes:
  Claude reviews architecture and Codex performs scoped technical scans when useful
  (exception: P0 bugs — see Master Workflow fast path below).

Hierarchy rule:
- Claude has the final word on all design decisions.
- If Codex suggests a structural change, Claude must validate it before adoption.

---

## Role B — Codex (Implementer & Technical Executor)

Primary mission:
- Execute implementation, tests, fixes, and low-level correctness according to approved architecture.

Focus:
- Writing production code and migrations.
- Performance and runtime behavior correctness.
- Unit/widget/integration test implementation and stabilization.
- Bug fixing with reproducible evidence.
- Boilerplate and repetitive code once Claude has defined signatures and purpose.
- Repository-wide technical dependency searches, file-level impact maps, incremental analysis
  of large logs/JSON/CSV, and targeted evidence reports for Claude.
- Syntax conversions, library upgrades, and utility scripts.

Must deliver:
- Working code aligned to contracts from specs/architecture review.
- Test commands and pass/fail results.
- Precise change list and risks.

Must avoid:
- Silent architecture changes without explicit contract updates.
- Partial patching when the declared strategy is full cutover.
- Structural changes without Claude validation.
- Implementing a spec that is technically incorrect. If a handoff contains
  a wrong API choice, a false runtime assumption, or a logically insufficient
  fix, Codex must stop and report the error before proceeding.

Spec review rule:
- Before writing any code, Codex reads the handoff spec and applies its own
  technical knowledge to validate it. If something is wrong (e.g., wrong async
  primitive, incorrect method signature, insufficient guard), Codex flags it
  with a clear explanation and waits for Claude to correct the spec.
- This is not a violation of the hierarchy — it is Codex fulfilling its role
  as a competent programmer, not a blind executor.

---

## Cross-cutting analysis — shared, without a third agent

- Claude owns architectural and business impact assessment, synthesis of long documents,
  UI/UX screenshot interpretation, and final coherence review.
- Codex performs concrete repository searches, dependency/usage maps, incremental large-data
  processing, and test-impact identification. It reports exact file paths and risks to Claude.
- Work in bounded batches for large PDFs and logs; avoid claiming full coverage of partially
  inspected materials. Architectural decisions remain Claude's responsibility.
- Technical scans are a support step, not a separate approval authority.

---

## Master Workflow

### Standard path (features, non-urgent fixes, refactors)

1. **Directive (user → Claude):** Claude receives and scopes the request.
2. **Mapping (Claude + Codex):** Claude determines cross-module risks; where relevant,
   Codex scans the repository and reports affected files, dependencies, and edge cases.
3. **Planning (Claude):** Claude produces and approves the plan and specs.
4. **Execution (Claude → Codex):** Codex reviews technical feasibility, implements within
   the approved scope, and runs targeted and required tests.
5. **Closure (Claude):** Claude reads modified files, validates architecture and system
   coherence, and checks Codex's exact test evidence. User/device acceptance gates remain.
   Do not claim an independent review unless it was actually performed.

### Fast path (P0 blockers, active freezes, critical regressions)

For urgent P0 bugs, document and defer nonessential scans that would delay containment.
Complete the impact assessment and verification after stabilization.

---

## Coordination Golden Rules

1. **Hierarchy:** Claude has the final word on design. Codex findings require Claude review.
2. **Data efficiency:** Codex reports concise file-level evidence; no unfiltered log dumps.
3. **Speed:** Direct single-file implementation to Codex; do not add unnecessary mapping.
4. **Whole-system view:** Claude owns cross-module context and delegates technical searches,
   large structured-data processing, and dependency tracing to Codex as appropriate.
5. **Specs first:** No role implements behavior absent from `docs/specs.md`.
6. **Bug-first preflight gate:** Reconcile open entries in `docs/bugs/bug_log.md`
   and `docs/validation/validation_ledger.md`; prioritize the queue unless
   the user explicitly overrides.

---

## Mandatory Handoff Format

Every handoff between Claude and Codex must include:

1. Scope
- What is in/out for this step.

2. Files
- Exact files touched (or to be touched).

3. Verification
- Exact test/analyze commands run and observed result.

4. Risks
- Known risks, regressions, and uncertainty.

5. Requested next action
- One explicit action expected from the receiving role.

6. User-facing validation recap (mandatory when closing validations)
- For every ID moved to `Closed/OK`, include the concrete case validated:
  repro trigger, expected behavior, and PASS evidence.
- The responding agent must ask for explicit final user confirmation after the recap.

7. Bug-queue status checkpoint (mandatory before non-bug work)
- Current non-closed bug count from `bug_log.md`.
- Confirmation that each bug is represented in `validation_ledger.md`.
- Which bug ID(s) are next by priority.

8. Branch-scope checkpoint (mandatory before implementation/commit)
- Current branch name.
- Declared branch intent (one line).
- Confirmation that the requested task belongs to that intent.
- If not, required action: create/switch to a dedicated branch before edits.

---

## Refactor Mode (Full Cutover)

When a task is marked as "full rewrite / no patches", all roles must enforce:
- No dual-path behavior kept as functional runtime authority.
- No fallback to legacy authority for countdown/sync decisions.
- Null-stream events must not reset runtime to idle when execution was active.
- Closure requires real-device exact repro pass on the defined validation packet.

If an implementation still depends functionally on legacy paths, review result is:
- **Rejected (not full cutover).**

---

## Quick Responsibility Matrix

- Specs/architecture contract definition: Claude
- Cross-repo impact analysis: Claude (architecture) + Codex (technical scans)
- Runtime implementation: Codex
- Test authoring and repair: Codex
- Structural review and acceptance gate: Claude
- System coherence check at closure: Claude (using Codex's evidence; tests always mandatory)
- Final "ready for device validation" check: both Claude and Codex (Claude approves architecture, Codex proves test health)

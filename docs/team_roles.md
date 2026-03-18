# Team Roles & Handoff Contract

Last update: 2026-03-18

This document defines the operational split between Claude, Codex, and Gemini in this repository.
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
- Orchestrate the overall workflow: receive requirements, delegate to Gemini or Codex, and make final design decisions.

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
- Delegation instructions to Gemini or Codex with explicit scope and expected output.

Must avoid:
- Deep mechanical edits as the default path when architectural direction is still unclear.
- Approving implementation that violates architecture contracts, even if tests pass.
- Starting implementation without first requesting a Gemini impact scan for non-trivial changes
  (exception: P0 bugs — see Master Workflow fast path below).

Hierarchy rule:
- Claude has the final word on all design decisions.
- If Codex or Gemini suggest a structural change, Claude must validate it before adoption.

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

## Role C — Gemini (Context Specialist & Repository Analyst)

Primary mission:
- Provide deep, cross-cutting analysis of the full repository that would exceed Claude's
  practical context window.

Note on access: Gemini operates via GitHub Copilot in VS Code with full autonomous access
to the repository — it can list directories, search files, read any file, run terminal commands,
and retrieve logs directly, without requiring manual context from the user.

Focus:
- Repository impact analysis: scan the full codebase to find hidden dependencies or conflicts
  before Claude designs a solution.
- Large document ingestion: read and summarize extensive external docs, PDFs, or API references.
- Visual / UI review: analyze screenshots of visual bugs or design mockups and propose code structures.
- Massive data processing: parse large logs, JSON/CSV exports, or audit trails that exceed
  working memory of other agents.

Must deliver:
- Concise impact reports (affected modules, risks, edge cases) — not raw file dumps.
- Targeted summaries that Claude can consume to make architectural decisions.

Must avoid:
- Making architectural decisions or modifying code without Claude validation.
- Replacing Claude's own responsibility to understand context from CLAUDE.md and AGENTS.md.

Efficiency rule:
- Do not invoke Gemini for single-file analysis, simple autocompletion, or trivial lookups;
  use Claude or Codex directly for those.

---

## Master Workflow

### Standard path (features, non-urgent fixes, refactors)

1. **Directive (user → Claude):** User requests a feature or fix. Claude takes command.
2. **Mapping (Claude → Gemini):** Claude asks Gemini to scan the full repo for impact:
   "Gemini, find how this change affects existing modules and flag hidden dependencies."
3. **Planning (Claude):** Using Gemini's report, Claude drafts the attack plan and technical specs.
4. **Execution (Claude → Codex):** Claude delegates repetitive code writing:
   "Codex, implement the logic for these 3 functions following this plan."
5. **Closure (Claude + Gemini):** Claude reviews final logic; Gemini confirms the resulting
   file is coherent with the rest of the system. Mandatory tests (`flutter analyze` + relevant
   test suite) must still pass — Gemini confirmation does not replace test results.

### Fast path (P0 blockers, active freezes, critical regressions)

When a P0 bug is active (e.g., irrecoverable `Syncing session...`), the Gemini mapping step
(step 2) is **optional** — skip it if it would delay the fix. The priority is stopping the
bleeding first. Document the skip and run the full standard path after the P0 is resolved.

---

## Coordination Golden Rules

1. **Hierarchy:** Claude has the final word on design. Codex and Gemini proposals require
   Claude validation before adoption.
2. **Data efficiency:** Do not saturate Claude with raw large files or full log dumps.
   Use Gemini as a filter — deliver to Claude only the relevant summary.
3. **Speed:** Do not invoke Gemini for single-line autocompletion or trivial file lookups;
   Codex is faster for those.
4. **Whole-system view:** Invoke Gemini whenever you need to "see" the project as a whole,
   assess cross-module impact, or process data that exceeds practical context limits.
5. **Specs first:** No role may implement behavior that is not yet defined in `docs/specs.md`.
   If a gap exists, Claude must update specs before implementation begins.

---

## Mandatory Handoff Format

Every handoff between Claude, Codex, and Gemini must include:

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
- Cross-repo impact analysis: Gemini
- Runtime implementation: Codex
- Test authoring and repair: Codex
- Structural review and acceptance gate: Claude
- System coherence check at closure: Claude + Gemini (tests always mandatory regardless)
- Final "ready for device validation" check: both Claude and Codex (Claude approves architecture, Codex proves test health)

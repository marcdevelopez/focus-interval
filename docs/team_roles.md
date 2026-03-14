# Team Roles & Handoff Contract

Last update: 2026-03-14

This document defines the operational split between Claude and Codex in this repository.
It is normative for day-to-day collaboration and must be applied together with:
- `AGENTS.md`
- `docs/specs.md`

If any conflict exists, precedence is:
1. System/developer constraints
2. `AGENTS.md`
3. `docs/specs.md`
4. This file

---

## Role A — Claude (Architect & Structural Reviewer)

Primary mission:
- Own architecture quality, decomposition, invariants, and long-term maintainability.

Focus:
- Architecture and boundaries (layering, cohesion, coupling).
- Abstraction decisions (what belongs in services/viewmodels/domain).
- Naming and readability at system level.
- Design review of implementations produced by Codex.

Must deliver:
- Clear rationale ("why this design").
- Concrete contracts before implementation (state models, ownership rules, sync invariants).
- Review findings ordered by severity with exact file/line references.

Must avoid:
- Deep mechanical edits as the default path when architectural direction is still unclear.
- Approving implementation that violates architecture contracts, even if tests pass.

---

## Role B — Codex (Implementer & Technical Executor)

Primary mission:
- Execute implementation, tests, fixes, and low-level correctness according to approved architecture.

Focus:
- Writing production code and migrations.
- Performance and runtime behavior correctness.
- Unit/widget/integration test implementation and stabilization.
- Bug fixing with reproducible evidence.

Must deliver:
- Working code aligned to contracts from specs/architecture review.
- Test commands and pass/fail results.
- Precise change list and risks.

Must avoid:
- Silent architecture changes without explicit contract updates.
- Partial patching when the declared strategy is full cutover.

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

---

## Refactor Mode (Full Cutover)

When a task is marked as "full rewrite / no patches", both roles must enforce:
- No dual-path behavior kept as functional runtime authority.
- No fallback to legacy authority for countdown/sync decisions.
- Null-stream events must not reset runtime to idle when execution was active.
- Closure requires real-device exact repro pass on the defined validation packet.

If an implementation still depends functionally on legacy paths, review result is:
- **Rejected (not full cutover).**

---

## Quick Responsibility Matrix

- Specs/architecture contract definition: Claude
- Runtime implementation: Codex
- Test authoring and repair: Codex
- Structural review and acceptance gate: Claude
- Final "ready for device validation" check: both (Claude approves architecture, Codex proves test health)


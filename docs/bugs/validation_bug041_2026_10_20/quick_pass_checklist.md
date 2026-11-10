## Exact repro

- [x] R1.0 clock probe PASS (2026-10-22; single real clock verified, Flutter exit 0).
- [x] R1-A: 5/5 valid, at least 4/5 H1, identical SPEC-FAIL signature including S1 and S5 (met by intento 3).
- [x] R1-B: valid, H1, same SPEC-FAIL signature as R1-A (met by intento 3).

- [x] (intento 2) R1.0 PASS; clock delta 0 ms, timer 302 ms, pump 25,892 us, ticks 1002/2002/3002 ms.
- [ ] (intento 2) R1-A gate accepted: stopped INVALID; A1/A3/A5 valid SPEC-FAIL, A2/A4 INVALID:V3.
- [ ] (intento 2) R1-B: not run after the R1-A gate stopped.

- [x] (intento 3) R1.0 PASS: clock delta 0 ms, timer 302 ms, pump 27,338 us, ticks 1003/2002/3003 ms.
- [x] (intento 3) R1-A evidence: 5/5 VALID, 5/5 H1, identical FAIL[S1,S2,S4,S5], EXPECTED_SPEC_FAIL gate.
- [x] (intento 3) R1-B evidence: VALID/H1, same signature as R1-A, EXPECTED_SPEC_FAIL gate.

- [x] (R1-D, 2026-10-30) Physical Samsung, Local Mode, installed debug build: signature criteria 1–6 met (abort 762 ms before T0; no start; Ready/25:00 with Start; no sound heard).
- [x] (R1-D) Device logcat, pre-check log, videos and T0+60 s screenshot indexed by sha256 in the plan.
- [x] (R3-D) Valid run (manual Start after the failed auto-start, then Groups Hub -> Run Mode) executed on 2026-11-10 as Scenario G; the 2026-10-30 run was a variant without manual Start.
- [x] (R3-D) Valid-run procedure recorded in the plan as Scenario G (2026-11-09); execution pending owner authorization.
- [x] (Scenario G, 2026-11-10) Preconditions met (build identical to R1-D, Local Mode, Do Not Disturb, app in the foreground, baseline 7 completed / 5 canceled); R1-D criteria 1–4 met; criterion 5 partial check (T0 to T0+15 s) met.
- [x] (Scenario G) O1–O6 recorded: Start anchored at the press (25:00 at d ≈ 23.2 s); after the Groups Hub return, two alternating countdowns 24 s apart; start sound once at Start.

## Regression smoke

- [x] Existing suite 219/219 PASS (runner stage `existing`, 2026-10-22, Flutter exit 0).
- [x] Real full suite: only R1 SPEC-FAIL failures; reported as `SUITE_FAIL`, not PASS (met by intento 3).
- [x] No tracked file modified (`git diff --stat` empty).

- [x] (intento 2) Existing tracked suite 219/219 PASS, Flutter exit 0.
- [ ] (intento 2) Real full suite: not run after the R1-A gate stopped.
- [x] (intento 2) Tracked and staged diffs empty; private untracked files preserved.

- [x] (intento 3) Existing tracked suite 219/219 PASS separately and within the real full suite.
- [x] (intento 3) Real full suite reported SUITE_FAIL, Flutter exit 1: 219 existing PASS, R1.0 PASS, five expected SPEC-FAIL, B1 intentionally skipped.
- [x] (intento 3) No unexpected failure, invalid run or alternative interleaving; no global PASS claim.
- [x] (intento 3) Tracked and staged diffs empty; expected branch/HEAD, private files and Drive temp files untouched.

- [x] (R1-D) Cleanup: test group canceled; final data 7 completed / 5 canceled, none scheduled or running.
- [x] (R1-D) No reinstall, data deletion or device-setting change; private backup verified before the run.
- [x] (Scenario G) Cleanup: only the test group canceled; data = baseline plus one canceled; none scheduled or running.

## Local gate

- [x] `flutter analyze` PASS (2026-10-22; no issues, Flutter exit 0).
- [x] Runner summary log present with `SEQUENCE=STOPPED stage=r1a`; `RUNNER_EXIT=2` recorded in the plan.
- [x] Unexpected R1-A INFRA stop documented; no rerun and no test edits after the stop.

- [x] (intento 2) Exact authorized repair; format 0 changed; test SHA-256 47b96386eee004d7... before/after execution.
- [x] (intento 2) flutter analyze PASS, no issues, Flutter exit 0.
- [x] (intento 2) One runner invocation only; RUNNER_EXIT=2, STOPPED stage=r1a, INVALID:2,SPEC_FAIL:3.
- [x] (intento 2) Eight original log checksums OK before/after; eight separate _a2_ logs preserved; handoff hash unchanged.
- [x] (intento 2) Per-run table, full summary, complete A1/A2/A4 traces and V3 invalidations recorded in the plan.
- [x] (intento 2) No rerun, no post-stop test/runner edit, no R1-C/R2/R3, no production change or Git mutation.

- [x] (intento 3) Exact V3 diff only; format 0 changed; test SHA-256 1d92a9b9629627c6... matches before/after execution.
- [x] (intento 3) flutter analyze PASS, no issues, Flutter exit 0.
- [x] (intento 3) One invocation, RUNNER_EXIT=1, SEQUENCE=COMPLETED, suite_status=FAIL.
- [x] (intento 3) Sixteen historical checksums OK before/after; twelve separate _a3_ logs; handoff/runner unchanged.
- [x] (intento 3) Full summary, all RESULT lines, per-run table, complete H1 trace, B1 comparison and suite verdict recorded.
- [x] (intento 3) Attempts 1/2 and Claude V3 review preserved; no extra execution, test edit, production change or Git mutation.

- [x] (R1-D) No code, test or configuration change; tracked and staged diffs empty; new evidence ignored by Git.
- [x] (R1-D) Private backup of the seven device files: two copies outside Git, 7/7 SHA-256 OK each, originals unchanged (2026-11-09).
- [x] Branch published to `origin` (2026-11-09; docs only; one-off AGENTS.md rule-10 exception; no PR); remote HEAD verified.
- [x] (Scenario G) Four evidence files indexed by sha256; two private copies verified (2026-11-10); no code, test or configuration change.

## Closure rule

- [x] R1 closes only after Claude's evidence review and the owner's decision (Claude review 2026-10-22; owner acceptance 2026-10-23).
- [x] BUG-041 stays Open (P1 provisional); bug closure requires an approved fix, device validation and the `CLAUDE.md` section 11 flow.
- [ ] (intento 2) Claude reviews the exact repair and evidence/V3 results; owner decides any further change/run.
- [x] (intento 2) BUG-041 remains Open, P1 provisional; H1/H2 not established as root cause.
- [x] (intento 3) Claude reviews and accepts the automated R1 evidence; owner decides the next authorized step (accepted 2026-10-23).
- [x] (intento 3) BUG-041 remains Open, P1 provisional; no fix, physical-device validation or root-cause claim.
- [x] (R1-D) BUG-041 remains Open, P1 provisional; R1-D is a reproduction, not a root-cause, fix or H2 result.
- [x] (Scenario G) BUG-041 remains Open, P1 provisional; H2 is consistent with the observations but not demonstrated.

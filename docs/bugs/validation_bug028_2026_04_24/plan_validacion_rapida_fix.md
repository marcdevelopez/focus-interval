# BUG-028 validation plan

## 1. Header

- Date: 24/04/2026
- Branch: fix/bug028-paused-ends-projection
- Working commit hash: pending-local (log naming base: 5df97ec)
- Bugs covered: BUG-028 / BUGLOG-028
- Target devices: Android RMX3771 (owner) + macOS (mirror)

## 2. Objetivo

Validate that Groups Hub keeps timeline coherence while a running group is paused and a dependent scheduled group has been postponed. Specifically, the Running/Paused card Ends must follow projected end time in real time (theoretical end + elapsed pause), so it no longer stays static until resume.

## 3. Sintoma original

During overlap/postpone flows, Scheduled cards in Groups Hub shifted as expected, but the paused running card Ends stayed frozen. The timeline looked incoherent until the user resumed the running group.

## 4. Root cause

Groups Hub card rendering used static TaskRunGroup.theoreticalEndTime for running cards. The screen already had projected scheduling logic for postponed groups, but running card Ends did not use projected paused end. Root cause location: lib/presentation/screens/groups_hub_screen.dart (\_GroupCard build -> endTime resolution).

## 5. Protocolo de validacion

### Scope guard (mandatory)

- BUG-028 validates the runtime overlap path from specs section 10.4.1.c
  (paused timeline projection coherence in Groups Hub after Postpone scheduled).
- This packet does not validate Plan Group auto-clamp/auto-adjust behavior
  (planning contract tracked separately under IDEA-039).
- If planning auto-adjust behavior differs, record it under IDEA-039 and do not
  fail BUG-028 unless it prevents entering the runtime overlap validation path.

### Scenario A — Owner paused timeline coherence after postpone

Preconditions:

1. Account mode enabled on owner Android.
2. One running group (G1) active, and a second group (G2) scheduled right after G1 end.
3. Prefer G2 noticeMinutes > 0m (for deterministic pre-run overlap at runtime).
4. noticeMinutes = 0m is also acceptable if overlap is triggered at scheduled-start
   boundary.

Steps:

1. With G1 running, create G2 starting at G1 projected end or +1 minute.
2. Wait until runtime overlap decision appears (pre-run boundary when notice > 0,
   or scheduled-start boundary when notice = 0).
3. When the conflict modal appears, choose Postpone scheduled.
4. Confirm G1 is paused by the conflict flow and open Groups Hub.
5. Capture T0 on owner (G1 paused, G1 Ends visible, G2 window visible).
6. Wait 70-90 seconds without resuming G1.
7. Capture T+70 on owner.
8. Compare G1 Ends drift versus G2 scheduled window shown on Groups Hub.

Expected result with fix:

1. G1 Ends keeps moving while paused (projected end).
2. G1 and G2 timelines stay coherent without requiring resume.

Reference result without fix:

1. G1 Ends remains static during pause and only catches up after resume.

### Scenario B — Mirror coherence

Preconditions:

1. Owner Android paused on G1.
2. Mirror macOS open in Groups Hub.

Steps:

1. Keep G1 paused for at least 70 seconds.
2. Observe mirror Groups Hub Running/Paused card Ends and scheduled card windows.

Expected result with fix:

1. Mirror shows projected G1 Ends moving while paused.
2. Scheduled cards remain aligned with projected anchor.

Reference result without fix:

1. Mirror can show static paused Ends until owner resumes.

### Scenario C — Resume non-regression

Preconditions:

1. Same state as Scenario A/B with paused G1.

Steps:

1. Resume G1 from Run Mode.
2. Re-open Groups Hub.

Expected result with fix:

1. Timeline stays coherent after resume.
2. No regression in existing Running/Paused/Scheduled card rendering.

Reference result without fix:

1. Coherence returns only after resume (delayed correction).

## 6. Comandos de ejecucion

### Device runs (exact repro)

- Evidence integrity note (27/04/2026):
  - `2026-04-24_bug028_5df97ec_android_RMX3771_debug.log` was overwritten on
    27/04/2026 and is invalid for closure evidence.
  - Keep the file for traceability, but do not use it as closure proof.
- Android owner:
  - flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_android_RMX3771_debug.log
- macOS mirror:
  - flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log

### Local gate (already executed)

- flutter analyze 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_analyze_debug.log
- flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub paused running card updates Ends projection in real time" 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_bug028_widget_debug.log
- flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub core sections and actions are visible" 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_groups_hub_smoke_debug.log

## 7. Log analysis — quick scan

### Bug present signals

- grep -nE "Expected: not|Paused running card Ends should keep projecting|Some tests failed" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_bug028_widget_debug.log
- grep -nE "Timeline appears incoherent|paused.*Ends.*static" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_android_RMX3771_debug.log
- grep -nE "Timeline appears incoherent|paused.*Ends.*static" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log

### Fix working signals

- grep -nE "No issues found" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_analyze_debug.log
- grep -nE "All tests passed|Groups Hub paused running card updates Ends projection in real time" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_bug028_widget_debug.log
- grep -nE "Groups Hub core sections and actions are visible|All tests passed" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_groups_hub_smoke_debug.log

## 8. Verificacion local

- flutter analyze: PASS
- target test (BUG-028): PASS
- Groups Hub smoke test: PASS

## 9. Criterios de cierre

- Scenario A PASS on real device with evidence (logs + screenshot).
- Scenario B PASS on mirror device with evidence (logs + screenshot).
- Scenario C PASS (resume non-regression) with evidence.
- Local gate remains PASS (analyze + targeted tests).
- bug_log + validation_ledger + dev_log synchronized with closure metadata.

## 10. Status

In validation

## 11. 27/04/2026 rerun findings (owner+mirror)

Execution window reviewed:

- Android owner + macOS mirror run between 16:08 and 16:15 (UTC-4).
- Logs used:
  - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_android_RMX3771_debug.log`
  - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log`

Observed BUG-028 target behavior:

- Paused-window projection coherence was observed during Scenario A/B:
  - Session paused at ~16:12:13 (`status=paused`, `remaining=675`).
  - While paused, effective scheduled window shifted in real time:
    - ~16:13:02 sample `16:26`
    - ~16:13:46 sample `16:27`
    - ~16:14:46 sample `16:28`
    - ~16:14:57 sample `16:30`
  - This matches expected projected-anchor behavior for paused overlap/postpone flow.
- Scenario C (resume non-regression) was observed:
  - Session resumed at ~16:14:57 (`status=pomodoroRunning`), no paused-window projection collapse observed in the immediate post-resume window.

Critical side findings from same run (separate bugs):

- BUG-030 (P1): mirror forced navigation to Run Mode while user was in `/groups` or `/tasks`.
- BUG-031 (P2): mirror conflict snackbar remained stale after conflict was resolved.

Validation status decision:

- BUG-028 behavior looks functionally corrected in this rerun.
- Packet remains **In validation** until closure evidence set is finalized and cross-doc closure is done after triaging BUG-030/BUG-031 impact.

## 12. Resume checkpoint (24/04/2026, amended 27/04/2026)

Current git checkpoint:

- Branch: fix/bug028-paused-ends-projection
- Working commit base: 5df97ec
- Worktree state: dirty (expected, includes BUG-028 code + docs + validation packet)

What is already validated/confirmed:

1. Local gate PASS:

- flutter analyze PASS
- BUG-028 widget regression test PASS
- Groups Hub smoke test PASS

2. Real-device conflict path is confirmed:

- Pre-run conflict modal appears when G2 pre-run overlaps G1 running window.
- Postpone scheduled action works.
- Runtime feedback observed: "Scheduled start moved to 17:46 (pre-run at 17:41)."

3. Spec/runtime alignment clarified:

- BUG-028 closure is based on runtime overlap flow coherence only.
- Plan Group auto-clamp/auto-adjust belongs to IDEA-039 validation scope.
- Overlap conflicts (running/scheduled) remain explicit conflict-resolution flows.

What is not validated yet (blocking closure):

1. Cross-doc closure sync is still pending (BUG-028 packet + bug_log + ledger + dev_log final closure block).
2. BUG-030/BUG-031 triage/fix branch must complete before deciding whether BUG-028 closes independently or together.

Screenshot evidence index (captured and renamed on 27/04/2026):

- Scenario A precondition + conflict path:
  - `screenshots/2026-04-27_bug028_scenarioA_precondition_161222_owner_android_mirror_macos.png`
  - `screenshots/2026-04-27_bug028_scenarioA_conflict_modal_161248_owner_android_mirror_macos.png`
- Scenario A/B paused projection coherence:
  - `screenshots/2026-04-27_bug028_scenarioAB_T0_paused_161302_owner_android_mirror_macos.png`
  - `screenshots/2026-04-27_bug028_scenarioAB_T0_postpone_snackbar_161303_owner_android_mirror_macos.png`
  - `screenshots/2026-04-27_bug028_scenarioAB_mid_paused_161349_owner_android_mirror_macos.png`
  - `screenshots/2026-04-27_bug028_scenarioAB_Tplus106_paused_161448_owner_android_mirror_macos.png`
- Scenario C post-resume:
  - `screenshots/2026-04-27_bug028_scenarioC_post_resume_161459_owner_android_mirror_macos.png`

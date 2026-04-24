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

### Scenario A — Owner paused timeline coherence after postpone

Preconditions:

1. Account mode enabled on owner Android.
2. One running group (G1) active, and a second group (G2) scheduled right after G1 end.
3. Pre-run notice for G2 is > 0m, so pre-run can overlap while G1 is still active.

Steps:

1. With G1 running, create G2 starting right after G1 end.
2. Wait until G2 pre-run starts while G1 is still active.
3. When the conflict modal appears, choose Postpone scheduled.
4. Confirm G1 is paused by the conflict flow and open Groups Hub.
5. Observe G1 Running/Paused card Ends for at least 70 seconds.
6. Compare with G2 scheduled window shown on Groups Hub.

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

- Android owner:
  - flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_android_RMX3771_debug.log
- macOS mirror:
  - flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_macos_debug.log

### Local gate (already executed)

- flutter analyze 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_analyze_debug.log
- flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub paused running card updates Ends projection in real time" 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_bug028_widget_debug.log
- flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub core sections and actions are visible" 2>&1 | tee docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_groups_hub_smoke_debug.log

## 7. Log analysis — quick scan

### Bug present signals

- grep -nE "Expected: not|Paused running card Ends should keep projecting|Some tests failed" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_local_bug028_widget_debug.log
- grep -nE "Timeline appears incoherent|paused.*Ends.*static" docs/bugs/validation_bug028_2026_04_24/logs/2026-04-24_bug028_5df97ec_android_RMX3771_debug.log

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

## 11. Resume checkpoint (24/04/2026)

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

- Auto-clamp applies only when selected start is too soon.
- Overlap conflicts (running/scheduled) remain explicit conflict resolution flows.

What is not validated yet (blocking closure):

1. Paused projection evidence for Scenario A/B is still missing.
2. Resume non-regression evidence for Scenario C is still missing.

Exact stop point before interruption:

- Work stopped immediately before executing the paused-validation capture flow.
- Last guidance to execute was:
  1. Plan G2 to start at G1 end or +1 minute.
  2. Keep pre-run at 5m.
  3. Wait for pre-run conflict modal.
  4. Choose Postpone scheduled.
  5. If G1 is still running, pause it manually.
  6. In Groups Hub (Android + macOS), capture T0 with:
  - G1 paused
  - G1 Ends visible
  - G2 window visible
  7. Wait 70-90 seconds without resume.
  8. Capture T+70 on both devices.
  9. Resume G1 and capture final screenshot for Scenario C.

Pass/fail rule to apply on resume:

- Scenario A/B PASS only if G1 Ends advances from T0 to T+70 while paused and stays coherent with G2 window on both owner and mirror.
- Scenario C PASS only if timeline remains coherent after resume with no regression in Groups Hub rendering.

Evidence still required in validation folder:

- Android screenshots: T0 paused, T+70 paused, post-resume
- macOS screenshots: T0 paused, T+70 paused, post-resume
- Optional log snippets (grep) confirming no incoherent paused timeline behavior

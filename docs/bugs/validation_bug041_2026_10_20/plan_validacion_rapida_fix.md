# BUG-041 Quick Validation Plan - Step B / R1 (automated reproduction)

Date: 2026-10-20  
Branch: `fix/local-scheduled-autostart` (local, unpublished)  
Commit: `1561ead` (base; the R1 test file and this packet are uncommitted)  
Bugs covered: `BUG-041` (Open, P1 provisional)  
Target devices: `flutter test` host on macOS (debug), default test platform Android.
Physical Samsung validation is out of scope for R1.

Scope approved by the owner on 2026-10-20: R1.0, R1-A and R1-B only. R1-C (long
"never press Start" run) is deferred. No fix, no R2/R3. No commits.

## Objetivo

Obtain a technically defensible automated reproduction of symptom 1 of BUG-041
(Local Mode: after Pre-Run reaches zero, Run Mode stays Ready at 25:00 instead of
auto-starting), using real execution paths and a single real clock, and measure
the event sequence around the scheduled start (T0). The goal is to reproduce and
measure, not to confirm hypothesis H1. Symptom 2 (alternating countdowns) is R3
and out of scope.

## Síntoma original

From the owner's reports (16/10, 19/10 and 20/10/2026, physical Samsung, Local
Mode, no logs): the owner schedules a group (one task, one 25-minute pomodoro)
less than five minutes before its start. Pre-Run appears with the amber ring and
countdown. When the countdown reaches zero, Run Mode shows Ready / 25:00 with a
Start button and does not start by itself, before any Groups Hub visit. If the
owner presses Start later and then goes Run Mode -> Groups Hub -> Run Mode, the
countdown alternates about once per second between two values (R3, not covered
here).

## Root cause

Pending. Not established. No automated or device reproduction exists yet.

Hypotheses under test (from code reading, not demonstrated):

- H1 (this step): the Pre-Run tick (`Timer.periodic(1 s)` with
  `info.end.difference(now).inSeconds`) reaches 0 when less than 1 s remains, so
  `_handlePreRunCountdownFinished` can run before T0
  (`lib/presentation/screens/timer_screen.dart:918-960`);
  `_attemptScheduledAutoStart` then aborts as "not due" and clears the pending id
  (`timer_screen.dart:341-396`). At T0 the coordinator sets the group `running`
  with `actualStartTime = scheduledStart`
  (`lib/presentation/viewmodels/scheduled_group_coordinator.dart:532-557`,
  `1306-1367`), but `_maybeAutoStartScheduled` returns on `_autoStartHandled`
  (`timer_screen.dart:330-339`) and `_maybeAutoStartRunningGroup` returns in Local
  when `actualStartTime != null` (Fix 18 guard, `timer_screen.dart:468-470`).
- H2 (R3, later): two projections of the run (scheduled anchor vs manual Start)
  becoming visible after Run Mode re-entry.

Limit of R1: it can show the symptom and the ordered event sequence. It cannot
prove which guard blocks the start, because those returns emit no log. That part
stays an inference until a later, authorized step.

## Protocolo de validación

Time strategy: `LiveTestWidgetsFlutterBinding` (real clock, real timers, real
`DateTime.now()`). Verified on 2026-10-20 in the local SDK (Flutter 3.41.2) and
with a throwaway probe outside the repo. Detailed specification:
`codex_handoff.md` sections 5-6.

### Scenario A - R1.0 clock probe

Preconditions:
1. New test file present.
2. `flutter analyze` and the existing suite (219 tests) PASS (runner stages).

Steps:
1. Runner stage `r1.0` (`--plain-name 'BUG041 R1.0'`).

Expected result with fix: PASS (environment check; independent of the bug).

Reference result without fix: PASS. A failure means the strategy is not viable:
stop and report.

### Scenario B - R1-A: app opened inside the Pre-Run window (5 runs)

Preconditions:
1. Local Mode, real Local repositories, production app shell, no Firebase.
2. Group seeded as persisted data: 1 task, 25-min pomodoro, `noticeMinutes: 5`,
   T0 = whole second at least 6 s after start (window already open, as in the
   owner's "less than five minutes ahead" report).

Steps:
1. Mount the app at `/tasks`; the coordinator and auto-starter open Run Mode in
   Pre-Run by themselves.
2. Observe with 16-ms real frames until T0+3 s; no interaction.
3. Classify validity (V1-V5) and interleaving (H1 / ALT-due / ALT-stale / OTHER);
   evaluate spec checks S1-S5.

Expected result with fix (spec L1575-1581, L1655): ViewModel running by T0+2 s
without user action; exactly one start; `actualStartTime == T0`; remaining
consistent with T0; no Start/Ready visible.

Reference result without fix (prediction from code, to be measured): H1 sequence
(`Auto-start abort (not due)` before T0, coordinator `running` at T0, no
`startFromAutoStart`, ViewModel idle, Start + Ready visible), with S1, S2, S4, S5
failing and S3 passing.

### Scenario C - R1-B: app open before the window (1 run)

Preconditions:
1. As Scenario B, but `noticeMinutes: 1` and T0 at least 66 s after start.
2. Runs only if Scenario B shows no unexpected failures or invalid runs.

Steps:
1. Mount at `/tasks`; the coordinator schedules and fires the pre-alert and
   opens Pre-Run at about T0-60 s.
2. Observe until T0+3 s; same classification and checks.

Expected result with fix: as Scenario B.

Reference result without fix: same H1 sequence and same failure signature as
Scenario B (to be measured).

### Scenario D - suites and honest global status

Steps:
1. Runner stage `existing`: all tracked tests, excluding the new untracked file.
2. Runner stage `full`: real `flutter test --concurrency=1`.

Expected result: existing 219/219 PASS; the full suite is reported as
`SUITE_FAIL` when its only failures are the R1 SPEC-FAIL reproductions. Never
reported as PASS.

### Resultados de ejecución (filled in place by Codex)

| Stage / run | delta_ms | latency_ms | Interleaving | Validity | Failed S checks | Notes |
|---|---|---|---|---|---|---|
| r1.0 | - | - | - | PASS (environment only) | - | Real clock delta 0 ms; 300-ms timer fired at 303 ms; first 16-ms pump took 28,944 us; widget ticks at 1004, 2004, 3003 ms. |
| A1 | n/a | n/a | not classified | no RESULT; INFRA | not evaluated | Observation callback threw NoSuchMethodError before T0; no complete observation window or trace. |
| A2 | n/a | n/a | not classified | no RESULT; INFRA | not evaluated | Live binding assertions after the first run failed; no usable reproduction. |
| A3 | n/a | n/a | not classified | no RESULT; INFRA | not evaluated | Same secondary binding failure; no usable reproduction. |
| A4 | n/a | n/a | not classified | no RESULT; INFRA | not evaluated | Same secondary binding failure; no usable reproduction. |
| A5 | n/a | n/a | not classified | no RESULT; INFRA | not evaluated | Same secondary binding failure; no usable reproduction. |
| B1 | n/a | n/a | not run | blocked by runner stop | not evaluated | R1-B was not launched. |

Execution on 2026-10-22, 06:45:01–06:47:44 CEST, one invocation of the literal
handoff runner: `RUNNER_EXIT=2`, `SEQUENCE=STOPPED stage=r1a`. No stage was
restarted and no test code was edited after that stop.

Results are separated as required:

1. Existing checks: analyzer exit 0 (no issues); all 219 tracked existing tests
   passed with Flutter exit 0; R1.0 passed with Flutter exit 0 and the measured
   clock/pump values above.
2. Intended specification failures: none established. There are no R1-A RESULT
   lines, valid S-check outcomes, delta/latency measurements, or complete H1
   traces. R1-B and the real full-suite stage did not run. Do not report this as
   an expected SPEC-FAIL reproduction or as a full-suite PASS/SUITE_FAIL.
3. Unexpected failures: R1-A returned Flutter exit 1; the gate classified all
   five cases as INFRA (`detail=INFRA:5`) and stopped the sequence. The first
   error is in the new observation harness, not demonstrated production behavior.

Harness failure and next action for Claude/owner:

- `timer_screen_local_scheduled_autostart_test.dart:202-206`: the coordinator
  observation callback calls `.name` through a dynamically inferred action/type.
  The first runtime error is `NoSuchMethodError: Class 'ScheduledGroupActionType'
  has no instance getter 'name'`. Additional observation errors include
  `PomodoroStatus.name` (`:279-286`). The generic listener results are stored in
  `List<ProviderSubscription<dynamic>>`; the callbacks were left untyped, allowing
  dynamic dispatch of enum extension getters. The analyzer did not reject that.
- A1 then reports multiple callback/teardown errors; A2–A5 report live-binding
  assertions (`!inTest`, `!_expectingFrame`, `_pendingFrame == null`) without
  running meaningful observation windows. These are not five independent bug
  reproductions. The human and JSON logs preserve the complete diagnostics.
- Proposed harness-only repair for review, NOT APPLIED: explicitly type all
  observation `container.listen` calls (`ScheduledGroupAction?`, `String?`,
  `AsyncValue<List<TaskRunGroup>>`, `PomodoroState`, `TimerRuntimeState`) so enum
  names use statically resolved access. Review the subsequent teardown errors
  as well. Do not change the production paths, timing, runner or classification.
- Owner authorization is required before any repair or rerun. H1/H2 and the
  production root cause remain unproved; BUG-041 stays Open, P1 provisional.

Evidence (all under this packet's `logs/`):
- `2026-10-22_bug041_summary_1561ead_macos_debug.log`: full stage verdicts and stop.
- `2026-10-22_bug041_analyze_1561ead_macos_debug.log`: no issues, Flutter exit 0.
- `2026-10-22_bug041_existing_1561ead_macos_debug.log` and
  `2026-10-22_bug041_existing_json_1561ead_macos_debug.log`: 219 existing successes.
- `2026-10-22_bug041_r10_1561ead_macos_debug.log` and
  `2026-10-22_bug041_r10_json_1561ead_macos_debug.log`: real-clock probe success.
- `2026-10-22_bug041_r1a_1561ead_macos_debug.log` and
  `2026-10-22_bug041_r1a_json_1561ead_macos_debug.log`: unexpected exceptions,
  five error results, and zero RESULT lines. No complete H1 or alternate trace
  can be delivered from this aborted observation.

Harness prepared on 2026-10-22. The test attempted `FocusIntervalApp` and the
production router/wrappers; no shell fallback was used. Mounting and the
observation path are not accepted as validated because the callbacks failed.

Overrides (all confined to the new test file):
- `appModeServiceProvider`: `AppModeService.memory()` supplies the required app
  initialization and defaults to Local Mode, as in the existing coordinator tests.
- `firebaseAuthServiceProvider`: existing `StubAuthService`, avoiding Firebase
  initialization on the host while retaining the production Local selection path.
- `firestoreServiceProvider`: existing `StubFirestoreService`, for the same
  platform isolation; Local repositories remain real and are not overridden.
- `soundServiceProvider`: call recorder implementing the existing `SoundService`
  interface, to count starts without an audio plugin.
- `deviceInfoServiceProvider`: real `DeviceInfoService.load()` supplied with the
  fixed test ID via mock SharedPreferences before mounting, matching main's
  service initialization without a random device identity.

No task, preset, group, session, time-sync, coordinator, ViewModel, or TimerService
provider is overridden. Notifications use the production provider's disabled
host default, with no override. The default Android test platform is unchanged.
The group seed follows `task_list_screen.dart:1418-1447` (local owner, schema,
snapshot, device, anchors, totals and status), `task_group_planning_screen.dart:686-704`
(scheduled option and the shared duration function), and
`task_run_notice_service.dart:8-10` (default notice 5, valid range 0-15). It is saved
once through the real local repository before mounting; nothing is written by the
test afterwards. Action/pending observers attach immediately before mounting;
the persisted observer attaches after the first frame, and VM/TimerService
observers attach only once `TimerScreen` exists. Frames use real 16-ms pumps;
checkpoint reads and all trace output are observation-only.

### Intento 2 — execution results (2026-10-22)

One authorized invocation of handoff section 11.3, 07:48:20–07:51:41 CEST.
`RUNNER_EXIT=2`; `SEQUENCE=STOPPED stage=r1a`;
`VERDICT=INVALID detail=INVALID:2,SPEC_FAIL:3`.
The runner was not relaunched. R1-B and the real full suite were not executed.
This attempt does not satisfy the R1 acceptance gate and is not a global PASS
or a completed `SUITE_FAIL` reproduction sequence. Attempt-1 text and all eight
original logs above remain unchanged.

| Stage / run | delta_ms | latency_ms | Interleaving | Validity | Failed S checks | Notes |
|---|---|---|---|---|---|---|
| r1.0 | - | - | - | PASS (environment only) | - | Clock delta 0 ms; timer 302 ms; first pump 25,892 us; periodic ticks 1002, 2002, 3002 ms. |
| A1 | 177 | 1 | H1 | VALID | S1, S2, S4, S5 | Expected SPEC-FAIL; S3 passes; no unexpected exception. |
| A2 | 409 | 0 | H1 (reported) | INVALID:V3 | S1, S2, S4, S5 (printed; not accepted) | Logged now values go backwards by 118 us in emission order; invalid run. |
| A3 | 563 | 0 | H1 | VALID | S1, S2, S4, S5 | Expected SPEC-FAIL; S3 passes; no unexpected exception. |
| A4 | 652 | 0 | H1 (reported) | INVALID:V3 | S1, S2, S4, S5 (printed; not accepted) | Logged now values go backwards by 99 us in emission order; invalid run. |
| A5 | 617 | 0 | H1 | VALID | S1, S2, S4, S5 | Expected SPEC-FAIL; S3 passes; no unexpected exception. |
| B1 | n/a | n/a | not run | blocked by runner stop | not evaluated | No R1-B comparison with R1-A is available. |

Results in the three required groups:

1. Existing passing checks: `flutter analyze` exit 0, no issues (34.6 s);
   219/219 tracked tests PASS, Flutter exit 0; R1.0 PASS, Flutter exit 0.
2. New tests failing against the specification: A1, A3 and A5 are VALID and
   report identical `FAIL[S1,S2,S4,S5]`, with `exception=none`. They observe
   the first symptom: the persisted group becomes running at the scheduled
   anchor, while the ViewModel remains idle at 1500 s and Run Mode displays an
   enabled Start button and Ready through T0+3 s. No runtime start or start sound
   is observed; S3 (persisted scheduled start/end anchors) passes. These are
   specification failures, not passing tests.
3. Unexpected/unstable results: A2 and A4 report `INVALID:V3`; their printed
   H1/S-check values do not count as valid reproductions. The R1-A process exits
   1, the gate rejects the stage, and the runner exits 2. All five cases have
   exactly one JSON error carrying the framework's generic TestFailure message;
   the classified thrown messages are SPEC-FAIL for A1/A3/A5 and INVALID for
   A2/A4. The attempt-1 dynamic enum errors and secondary binding assertions
   did not recur. No unexpected runtime exception is reported, but the two
   invalid runs prevent acceptance of R1.

V3 evidence for Claude (the validity rule has not been changed):

- A2, raw log lines 290 and 292: `start-timer-fired now=07:51:08.031951`
  precedes `[evaluate] now=07:51:08.031833`. The embedded timestamps reverse
  by 118 microseconds; the observer trace times increase from T0+32 to T0+34 ms.
- A4, raw log lines 666 and 668: `start-timer-fired now=07:51:28.024376`
  precedes `[evaluate] now=07:51:28.024277`. The embedded timestamps reverse
  by 99 microseconds; the observer trace times increase from T0+24 to T0+25 ms.
- This establishes the logged-value ordering rejected by V3. It does not
  establish a system-clock jump or its cause. Claude should review the meaning
  of the sampled production timestamps versus their log-emission order before
  proposing any change. Both runs remain INVALID; no tolerance or
  reclassification was applied.

In A1 the attempt is observed 177 ms before T0, followed by a not-due abort
(reported latency 1 ms), pending-id reset, coordinator timer at T0+25 ms,
persisted running at T0+32 ms, and pending id set again at T0+35 ms. No second
attempt/start appears; checkpoints at +510, +2010 and +3008 ms show idle/1500,
Start/Ready, and TimerService idle. This ordered sequence is consistent with
H1, but does not prove the silent guard paths or establish root cause. H1 and
H2 remain hypotheses; alternating countdowns (R3), lifecycle recovery,
duplicates in a successful start and physical Samsung behavior were not
validated by this attempt. BUG-041 stays Open, P1 provisional.

Repair and execution integrity:

- Original test SHA-256:
  `75f52f6693ec657562edb03df006b1fb6461f16378340fc1a08d0783b16f4110`.
- Repaired/tested/post-stop SHA-256:
  `47b96386eee004d7918ac9f96c6613c1da2a7bce03c1a1cfa954c4530f5a7a0d`.
- Applied only the extracted section 11.1 diff using section 11.3 step 2:
  one import, five explicit listener types and the Object? subscription list.
  `git apply --check` succeeded; `dart format` reported 1 file, 0 changed.
  No post-stop test edit, timing edit, gate edit or rerun.
- Handoff SHA-256 before and after execution:
  `c9490807451519fd90c68df699076e7f0a4cf3803ed0c933428b8034bee3ccf3`.
  No handoff/runner edits by Codex.
- No fallback shell or additional doubles: the production app, five overrides
  and scheduling-flow source references documented for attempt 1 are unchanged.
  The five observation windows now finish and emit their evidence; no test
  navigation, user action or post-mount repository write was introduced.
- Branch `fix/local-scheduled-autostart`, HEAD `1561ead` throughout.
  Tracked and staged diffs remain empty. No .git mutation, staging, commit,
  push, PR or merge; production, other tests, dependencies, configuration,
  canonical source docs, private files and Drive temp files are untouched.

Full attempt-2 summary (verbatim):

```log
07:48:20 SEQUENCE=START runner=bug041-r1 attempt=2 head=1561ead date=2026-10-22
07:48:20 ENV Flutter 3.41.2 • channel stable • https://github.com/flutter/flutter.git
07:48:20 STAGE=precheck VERDICT=PASS
07:48:58 STAGE=analyze VERDICT=PASS flutter_rc=0
07:50:32 STAGE=existing VERDICT=PASS flutter_rc=0 tests=219
07:50:45 STAGE=r1.0 VERDICT=PASS flutter_rc=0 tests=1
07:51:41 INVALID_RUN 'BUG041 R1-A run 2' A2 INVALID:V3
07:51:41 INVALID_RUN 'BUG041 R1-A run 4' A4 INVALID:V3
07:51:41 STAGE=r1a VERDICT=INVALID flutter_rc=1 detail=INVALID:2,SPEC_FAIL:3
07:51:41 SEQUENCE=STOPPED stage=r1a
```

Attempt-1 checksum verification before attempt 2 (verbatim stdout):

```text
2026-10-22_bug041_analyze_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_1561ead_macos_debug.log: OK
```

Attempt-1 checksum verification after attempt 2 (verbatim stdout):

```text
2026-10-22_bug041_analyze_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_1561ead_macos_debug.log: OK
```

New attempt-2 files (all under this packet's `logs/`; eight files produced):

- `2026-10-22_bug041_analyze_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_existing_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_existing_json_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_r10_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_r10_json_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1a_json_a2_1561ead_macos_debug.log`
- `2026-10-22_bug041_summary_a2_1561ead_macos_debug.log`

No `r1b_a2`, `r1b_json_a2`, `full_a2` or `full_json_a2` file was created:
the runner stopped before those stages.

Complete evidence required for review: A1 is the valid H1 example; A2 and A4
are every invalid run. The following blocks include every TRACE line, all five
CHECKPOINT lines and the RESULT line for each. A3 and A5 are preserved in the
same raw log at lines 417-509 and
793-881 respectively.

<details>
<summary>A1: complete valid H1 trace, checkpoints and RESULT</summary>

Source: `logs/2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`,
lines 52-133. Copied verbatim; no events omitted.

```log
BUG041-R1 TRACE run=A1 t=-6021 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-5994 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-5985 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-5981 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:50:51.980697 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=-5977 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:50:52.005576 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=-5974 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:50:52.014667 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A1-1792648251857148:2026-10-22T07:50:58.000|2026-10-22T07:50:58.000
BUG041-R1 TRACE run=A1 t=-5966 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-5962 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792648251857148 token=1792648252034862
BUG041-R1 TRACE run=A1 t=-5961 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A1-1792648251857148 start=2026-10-22 07:50:58.000 delay=5s
BUG041-R1 TRACE run=A1 t=-5959 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:50:52.034324 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A1-1792648251857148:2026-10-22T07:50:58.000|2026-10-22T07:50:58.000
BUG041-R1 TRACE run=A1 t=-5958 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792648251857148 token=1792648252040921
BUG041-R1 TRACE run=A1 t=-5958 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A1-1792648251857148 start=2026-10-22 07:50:58.000 delay=5s
BUG041-R1 TRACE run=A1 t=-4860 src=screen data=[RunModeDiag] Active session cleared route=/tasks
BUG041-R1 TRACE run=A1 t=-4821 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792648251857148 route=/tasks
BUG041-R1 TRACE run=A1 t=-4792 src=persisted data=status=scheduled scheduledStart=2026-10-22T07:50:58.000 actualStart=null theoreticalEnd=2026-10-22T08:15:58.000 noticeSentAt=2026-10-22T07:50:52.030570 updatedAt=2026-10-22T07:50:52.030570
BUG041-R1 TRACE run=A1 t=-4765 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=false ready=false
BUG041-R1 TRACE run=A1 t=-4381 src=frame data=pump_us=382335
BUG041-R1 TRACE run=A1 t=-4379 src=vm data=status=idle phase=null remaining=0 starts=0
BUG041-R1 TRACE run=A1 t=-4378 src=timer-service data=group=null status=idle phase=pomodoro remaining=0 phaseStartedAt=null
BUG041-R1 TRACE run=A1 t=-4357 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=false ready=false
BUG041-R1 TRACE run=A1 t=-4341 src=vm data=status=idle phase=null remaining=1500 starts=0
BUG041-R1 TRACE run=A1 t=-4337 src=screen data=[RunModeDiag] Timer load group=bug041-r1-A1-1792648251857148 result=PomodoroGroupLoadResult.loaded status=scheduled route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-4184 src=frame data=pump_us=173012
BUG041-R1 TRACE run=A1 t=-4055 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3761 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3463 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3211 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3154 src=frame data=pump_us=57122
BUG041-R1 TRACE run=A1 t=-2929 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2642 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2346 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2143 src=frame data=pump_us=53863
BUG041-R1 TRACE run=A1 t=-2079 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1813 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1510 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1210 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-911 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-661 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-394 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-181 src=pending data=previous=null value=bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-180 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A1-1792648251857148 screen=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-177 src=screen data=[RunModeDiag] Auto-start attempt group=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-175 src=screen data=[RunModeDiag] Auto-start abort (not due) status=scheduled scheduledStart=2026-10-22 07:50:58.000 now=2026-10-22 07:50:57.823993
BUG041-R1 TRACE run=A1 t=-175 src=pending data=previous=bug041-r1-A1-1792648251857148 value=null
BUG041-R1 TRACE run=A1 t=-175 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=bug041-r1-A1-1792648251857148 next=null screen=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-136 src=screen data=[RunModeDiag] Auto-start skip pending=null screen=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=-135 src=frame data=pump_us=60158
BUG041-R1 TRACE run=A1 t=-121 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=25 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A1-1792648251857148 now=2026-10-22 07:50:58.024911
BUG041-R1 TRACE run=A1 t=25 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=true preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=27 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:50:58.025970 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A1-1792648251857148:2026-10-22T07:50:58.000|2026-10-22T07:50:58.000
BUG041-R1 TRACE run=A1 t=32 src=persisted data=status=running scheduledStart=2026-10-22T07:50:58.000 actualStart=2026-10-22T07:50:58.000 theoreticalEnd=2026-10-22T08:15:58.000 noticeSentAt=2026-10-22T07:50:52.030570 updatedAt=2026-10-22T07:50:58.030690
BUG041-R1 TRACE run=A1 t=35 src=pending data=previous=null value=bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=35 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A1-1792648251857148 screen=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=35 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792648251857148 token=1792648258035654
BUG041-R1 TRACE run=A1 t=36 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=48 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A1-1792648251857148 now=2026-10-22 07:50:58.048513
BUG041-R1 TRACE run=A1 t=49 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=50 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:50:58.049315 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=55 src=coordinator data=[ScheduledGroups][running-open-timer] mode=local now=2026-10-22 07:50:58.049315 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=56 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792648251857148 token=1792648258055864
BUG041-R1 TRACE run=A1 t=57 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792648251857148 route=/timer/bug041-r1-A1-1792648251857148
BUG041-R1 TRACE run=A1 t=105 src=frame data=pump_us=81476
BUG041-R1 TRACE run=A1 t=181 src=frame data=pump_us=69347
BUG041-R1 TRACE run=A1 t=224 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=292 src=frame data=pump_us=68420
BUG041-R1 TRACE run=A1 t=443 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=709 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=975 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1242 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1508 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1774 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2060 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2324 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2574 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2841 src=ui data=route=/timer/bug041-r1-A1-1792648251857148 preRun=false start=true ready=true
BUG041-R1 CHECKPOINT run=A1 t=-1976 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792648251857148 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=-461 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792648251857148 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=510 persisted.status=running persisted.actualStart=2026-10-22T07:50:58.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792648251857148 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792648251857148 timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=2010 persisted.status=running persisted.actualStart=2026-10-22T07:50:58.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792648251857148 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792648251857148 timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=3008 persisted.status=running persisted.actualStart=2026-10-22T07:50:58.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792648251857148 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792648251857148 timerService=idle:0
BUG041-R1 RESULT run=A1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=177 latency_ms=1
```

</details>

<details>
<summary>A2: complete INVALID:V3 trace, checkpoints and RESULT</summary>

Source: `logs/2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`,
lines 231-317. Copied verbatim; no events omitted.

```log
BUG041-R1 TRACE run=A2 t=-6691 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=-6689 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=-6688 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=-6686 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:51:01.309314 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A2 t=-6685 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:51:01.310933 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A2 t=-6685 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:01.312178 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A2-1792648261304866:2026-10-22T07:51:08.000|2026-10-22T07:51:08.000
BUG041-R1 TRACE run=A2 t=-6683 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=-6682 src=coordinator-action data=type=openTimer group=bug041-r1-A2-1792648261304866 token=1792648261317006
BUG041-R1 TRACE run=A2 t=-6682 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A2-1792648261304866 start=2026-10-22 07:51:08.000 delay=6s
BUG041-R1 TRACE run=A2 t=-6680 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:01.316750 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A2-1792648261304866:2026-10-22T07:51:08.000|2026-10-22T07:51:08.000
BUG041-R1 TRACE run=A2 t=-6680 src=coordinator-action data=type=openTimer group=bug041-r1-A2-1792648261304866 token=1792648261319672
BUG041-R1 TRACE run=A2 t=-6680 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A2-1792648261304866 start=2026-10-22 07:51:08.000 delay=6s
BUG041-R1 TRACE run=A2 t=-6617 src=screen data=[RunModeDiag] Active session cleared route=/tasks
BUG041-R1 TRACE run=A2 t=-6614 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A2-1792648261304866 route=/tasks
BUG041-R1 TRACE run=A2 t=-6611 src=persisted data=status=scheduled scheduledStart=2026-10-22T07:51:08.000 actualStart=null theoreticalEnd=2026-10-22T08:16:08.000 noticeSentAt=2026-10-22T07:51:01.315740 updatedAt=2026-10-22T07:51:01.315740
BUG041-R1 TRACE run=A2 t=-6610 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=false ready=false
BUG041-R1 TRACE run=A2 t=-6489 src=frame data=pump_us=120716
BUG041-R1 TRACE run=A2 t=-6489 src=vm data=status=idle phase=null remaining=0 starts=0
BUG041-R1 TRACE run=A2 t=-6488 src=timer-service data=group=null status=idle phase=pomodoro remaining=0 phaseStartedAt=null
BUG041-R1 TRACE run=A2 t=-6477 src=vm data=status=idle phase=null remaining=1500 starts=0
BUG041-R1 TRACE run=A2 t=-6476 src=screen data=[RunModeDiag] Timer load group=bug041-r1-A2-1792648261304866 result=PomodoroGroupLoadResult.loaded status=scheduled route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-6413 src=frame data=pump_us=66131
BUG041-R1 TRACE run=A2 t=-6308 src=frame data=pump_us=86275
BUG041-R1 TRACE run=A2 t=-6288 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-6203 src=frame data=pump_us=84973
BUG041-R1 TRACE run=A2 t=-5995 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-5744 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-5446 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-5176 src=frame data=pump_us=67307
BUG041-R1 TRACE run=A2 t=-5163 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-4913 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-4662 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-4350 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-4096 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-3795 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-3543 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-3343 src=frame data=pump_us=52948
BUG041-R1 TRACE run=A2 t=-3277 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-2981 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-2727 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-2478 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-2180 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-1911 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-1614 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-1358 src=frame data=pump_us=54958
BUG041-R1 TRACE run=A2 t=-1344 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-1043 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-747 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-495 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=-411 src=pending data=previous=null value=bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-410 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A2-1792648261304866 screen=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-409 src=screen data=[RunModeDiag] Auto-start attempt group=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-408 src=screen data=[RunModeDiag] Auto-start abort (not due) status=scheduled scheduledStart=2026-10-22 07:51:08.000 now=2026-10-22 07:51:07.591762
BUG041-R1 TRACE run=A2 t=-407 src=pending data=previous=bug041-r1-A2-1792648261304866 value=null
BUG041-R1 TRACE run=A2 t=-407 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=bug041-r1-A2-1792648261304866 next=null screen=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-383 src=screen data=[RunModeDiag] Auto-start skip pending=null screen=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=-230 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=true start=false ready=false
BUG041-R1 TRACE run=A2 t=30 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A2-1792648261304866 now=2026-10-22 07:51:08.029669
BUG041-R1 TRACE run=A2 t=31 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=true preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=32 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A2-1792648261304866 now=2026-10-22 07:51:08.031951
BUG041-R1 TRACE run=A2 t=32 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A2 t=34 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:08.031833 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A2-1792648261304866:2026-10-22T07:51:08.000|2026-10-22T07:51:08.000
BUG041-R1 TRACE run=A2 t=35 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:08.032492 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A2-1792648261304866:2026-10-22T07:51:08.000|2026-10-22T07:51:08.000
BUG041-R1 TRACE run=A2 t=36 src=persisted data=status=running scheduledStart=2026-10-22T07:51:08.000 actualStart=2026-10-22T07:51:08.000 theoreticalEnd=2026-10-22T08:16:08.000 noticeSentAt=2026-10-22T07:51:01.315740 updatedAt=2026-10-22T07:51:08.035971
BUG041-R1 TRACE run=A2 t=38 src=pending data=previous=null value=bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=38 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A2-1792648261304866 screen=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=39 src=coordinator-action data=type=openTimer group=bug041-r1-A2-1792648261304866 token=1792648268038766
BUG041-R1 TRACE run=A2 t=39 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A2-1792648261304866 route=/timer/bug041-r1-A2-1792648261304866
BUG041-R1 TRACE run=A2 t=71 src=frame data=pump_us=53131
BUG041-R1 TRACE run=A2 t=77 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=341 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=607 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=876 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=1141 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=1407 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=1674 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=1943 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=2210 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=2475 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=2744 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 TRACE run=A2 t=3008 src=ui data=route=/timer/bug041-r1-A2-1792648261304866 preRun=false start=true ready=true
BUG041-R1 CHECKPOINT run=A2 t=-1976 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A2-1792648261304866 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A2 t=-494 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A2-1792648261304866 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A2 t=508 persisted.status=running persisted.actualStart=2026-10-22T07:51:08.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A2-1792648261304866 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A2-1792648261304866 timerService=idle:0
BUG041-R1 CHECKPOINT run=A2 t=2008 persisted.status=running persisted.actualStart=2026-10-22T07:51:08.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A2-1792648261304866 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A2-1792648261304866 timerService=idle:0
BUG041-R1 CHECKPOINT run=A2 t=3008 persisted.status=running persisted.actualStart=2026-10-22T07:51:08.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A2-1792648261304866 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A2-1792648261304866 timerService=idle:0
BUG041-R1 RESULT run=A2 validity=INVALID:V3 interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=409 latency_ms=0
```

</details>

<details>
<summary>A4: complete INVALID:V3 trace, checkpoints and RESULT</summary>

Source: `logs/2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`,
lines 605-693. Copied verbatim; no events omitted.

```log
BUG041-R1 TRACE run=A4 t=-6870 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=-6869 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=-6868 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=-6866 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:51:21.129789 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A4 t=-6865 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 07:51:21.131042 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A4 t=-6865 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:21.132262 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A4-1792648281125441:2026-10-22T07:51:28.000|2026-10-22T07:51:28.000
BUG041-R1 TRACE run=A4 t=-6863 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=-6863 src=coordinator-action data=type=openTimer group=bug041-r1-A4-1792648281125441 token=1792648281136365
BUG041-R1 TRACE run=A4 t=-6863 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A4-1792648281125441 start=2026-10-22 07:51:28.000 delay=6s
BUG041-R1 TRACE run=A4 t=-6862 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:21.136244 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A4-1792648281125441:2026-10-22T07:51:28.000|2026-10-22T07:51:28.000
BUG041-R1 TRACE run=A4 t=-6860 src=coordinator-action data=type=openTimer group=bug041-r1-A4-1792648281125441 token=1792648281139124
BUG041-R1 TRACE run=A4 t=-6860 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A4-1792648281125441 start=2026-10-22 07:51:28.000 delay=6s
BUG041-R1 TRACE run=A4 t=-6805 src=screen data=[RunModeDiag] Active session cleared route=/tasks
BUG041-R1 TRACE run=A4 t=-6803 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A4-1792648281125441 route=/tasks
BUG041-R1 TRACE run=A4 t=-6801 src=persisted data=status=scheduled scheduledStart=2026-10-22T07:51:28.000 actualStart=null theoreticalEnd=2026-10-22T08:16:28.000 noticeSentAt=2026-10-22T07:51:21.135479 updatedAt=2026-10-22T07:51:21.135479
BUG041-R1 TRACE run=A4 t=-6799 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=false ready=false
BUG041-R1 TRACE run=A4 t=-6719 src=frame data=pump_us=80217
BUG041-R1 TRACE run=A4 t=-6719 src=vm data=status=idle phase=null remaining=0 starts=0
BUG041-R1 TRACE run=A4 t=-6719 src=timer-service data=group=null status=idle phase=pomodoro remaining=0 phaseStartedAt=null
BUG041-R1 TRACE run=A4 t=-6706 src=vm data=status=idle phase=null remaining=1500 starts=0
BUG041-R1 TRACE run=A4 t=-6705 src=screen data=[RunModeDiag] Timer load group=bug041-r1-A4-1792648281125441 result=PomodoroGroupLoadResult.loaded status=scheduled route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-6656 src=frame data=pump_us=51668
BUG041-R1 TRACE run=A4 t=-6558 src=frame data=pump_us=79150
BUG041-R1 TRACE run=A4 t=-6478 src=frame data=pump_us=60677
BUG041-R1 TRACE run=A4 t=-6464 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-6387 src=frame data=pump_us=76673
BUG041-R1 TRACE run=A4 t=-6179 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-5899 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-5586 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-5297 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-4997 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-4855 src=frame data=pump_us=88310
BUG041-R1 TRACE run=A4 t=-4744 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-4446 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-4144 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-3878 src=frame data=pump_us=67778
BUG041-R1 TRACE run=A4 t=-3855 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-3604 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-3310 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-3010 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-2895 src=frame data=pump_us=68863
BUG041-R1 TRACE run=A4 t=-2728 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-2447 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-2144 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-1893 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-1596 src=frame data=pump_us=52446
BUG041-R1 TRACE run=A4 t=-1582 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-1328 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-1030 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-730 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-654 src=pending data=previous=null value=bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-653 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A4-1792648281125441 screen=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-652 src=screen data=[RunModeDiag] Auto-start attempt group=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-651 src=screen data=[RunModeDiag] Auto-start abort (not due) status=scheduled scheduledStart=2026-10-22 07:51:28.000 now=2026-10-22 07:51:27.348398
BUG041-R1 TRACE run=A4 t=-651 src=pending data=previous=bug041-r1-A4-1792648281125441 value=null
BUG041-R1 TRACE run=A4 t=-650 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=bug041-r1-A4-1792648281125441 next=null screen=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-634 src=screen data=[RunModeDiag] Auto-start skip pending=null screen=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=-430 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=-177 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=true start=false ready=false
BUG041-R1 TRACE run=A4 t=23 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A4-1792648281125441 now=2026-10-22 07:51:28.022066
BUG041-R1 TRACE run=A4 t=24 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=true preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=24 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A4-1792648281125441 now=2026-10-22 07:51:28.024376
BUG041-R1 TRACE run=A4 t=24 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A4 t=25 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:28.024277 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A4-1792648281125441:2026-10-22T07:51:28.000|2026-10-22T07:51:28.000
BUG041-R1 TRACE run=A4 t=26 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 07:51:28.024891 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A4-1792648281125441:2026-10-22T07:51:28.000|2026-10-22T07:51:28.000
BUG041-R1 TRACE run=A4 t=27 src=persisted data=status=running scheduledStart=2026-10-22T07:51:28.000 actualStart=2026-10-22T07:51:28.000 theoreticalEnd=2026-10-22T08:16:28.000 noticeSentAt=2026-10-22T07:51:21.135479 updatedAt=2026-10-22T07:51:28.027006
BUG041-R1 TRACE run=A4 t=28 src=pending data=previous=null value=bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=28 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A4-1792648281125441 screen=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=29 src=coordinator-action data=type=openTimer group=bug041-r1-A4-1792648281125441 token=1792648288029062
BUG041-R1 TRACE run=A4 t=29 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A4-1792648281125441 route=/timer/bug041-r1-A4-1792648281125441
BUG041-R1 TRACE run=A4 t=71 src=frame data=pump_us=50074
BUG041-R1 TRACE run=A4 t=77 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=341 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=608 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=877 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=1143 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=1425 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=1692 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=1959 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=2225 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=2492 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=2761 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 TRACE run=A4 t=3025 src=ui data=route=/timer/bug041-r1-A4-1792648281125441 preRun=false start=true ready=true
BUG041-R1 CHECKPOINT run=A4 t=-1998 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A4-1792648281125441 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A4 t=-493 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A4-1792648281125441 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A4 t=509 persisted.status=running persisted.actualStart=2026-10-22T07:51:28.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A4-1792648281125441 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A4-1792648281125441 timerService=idle:0
BUG041-R1 CHECKPOINT run=A4 t=2026 persisted.status=running persisted.actualStart=2026-10-22T07:51:28.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A4-1792648281125441 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A4-1792648281125441 timerService=idle:0
BUG041-R1 CHECKPOINT run=A4 t=3025 persisted.status=running persisted.actualStart=2026-10-22T07:51:28.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A4-1792648281125441 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A4-1792648281125441 timerService=idle:0
BUG041-R1 RESULT run=A4 validity=INVALID:V3 interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=652 latency_ms=0
```

</details>

Next action for Claude: review the exact test repair, all attempt-2 evidence
and the V3 invalidations. The owner decides any further harness change or
execution. No fix or further run is authorized by this record.

### Claude review of attempt 2 and V3 (2026-10-22)

Analysis only. The attempt-2 results above are unchanged: A2 and A4 remain
`INVALID:V3` and attempt 2 does not satisfy the R1 gate. Attempt 3 must meet the
closure criteria on its own.

Test repair: the applied file is byte-identical to the authorized result
(sha256 `47b96386…`); compared with the original (`75f52f66…`) only the 26
typing lines differ. V1-V5, S1-S5, the RESULT protocol and the production paths
were not touched.

What the old V3 rule checked: the `now=` values printed by production code had
to be non-decreasing in the order the lines were emitted, across all emitters.

Mechanism of both invalidations (A2 trace #57-#62; A4 shows the same pattern):

| t (ms) | Event |
|---:|---|
| 30 | Coordinator start timer 1 fires, logs `start-timer-fired now=.029669`, enters `_handleGroupsAsync` (1) |
| 31 | (1) logs `timer-state`, takes `now` = .031833 (`scheduled_group_coordinator.dart:276`) and suspends on an `await` (L277) |
| 32 | Start timer 2 fires and logs `start-timer-fired now=.031951` (taken when printing) |
| 34 | (1) resumes and logs `[evaluate] now=.031833` (L340-347 -> L702), the value taken before t=32: an apparent 118-us step back |

Three different orders were mixed by the old rule:

- Capture of `now`: `[evaluate]` and `[no-groups]` print the value taken at
  function entry, after several awaits; `start-timer-fired` takes it when
  printing.
- Emission: the instant the test captures each line, synchronously. It never
  decreases in any of the five runs.
- Writing of the human log: `debugPrintThrottled` buffers and delays lines (some
  A2 lines appear under the "run 1" label). This affects only the log file, not
  the trace.

Conclusion: a valid asynchronous interleaving and a limitation of the
instrumentation rule; no clock defect. In all five runs every logged `now` is
at or before its own line (within the 1-ms resolution of the printed trace) and
at most 38 ms older.

Rule change (approved 2026-10-22; applied in attempt 3 through
`codex_handoff.md` section 12): each logged `now` is compared with its own line
instead of with other emitters. The test's capture instants must never decrease
(this detects a backward wall-clock jump at any of ~80 events per run, not only
at the ~10 lines that carry `now`). Every logged `now` must satisfy
`0 <= capture - now <= 250 ms` (250 ms is V4's stall bound). "No `running`
before T0" and "`start-timer-fired` never before T0" are unchanged. Checked with
the old and new blocks copied verbatim into a standalone Dart program:

| Case | Old V3 | New V3 |
|---|---|---|
| Real A2/A4 pattern | INVALID (false positive) | VALID |
| Capture instant goes backwards | not detected | INVALID |
| Logged `now` later than its own line | not detected | INVALID |
| Logged `now` 300 ms old | not detected | INVALID |
| `start-timer-fired` before T0 | INVALID | INVALID |

Offline, as analysis only and not a reclassification: under the new V3, and
with V4 and V5, all five attempt-2 runs would be valid.

Audit of what attempt 2 shows. All five runs follow the same chain and report
the same `FAIL[S1,S2,S4,S5]`. Run Mode opens in Pre-Run by itself; the Pre-Run
handler fires 177-652 ms before T0; the attempt aborts as "not due" within
0-1 ms; at T0 the coordinator persists `running` with `actualStartTime = T0`
(S3 passes); there is no `startFromAutoStart`; the ViewModel stays idle at
25:00 with Start and Ready visible from T0+0.5 s to T0+3 s.

Not demonstrated yet:

1. Which guard blocks the start. `Auto-start skip pending=null`, about 25 ms
   after the abort, can only come from the post-frame callback of
   `_maybeAutoStartScheduled` (`timer_screen.dart:334-337`), which sets
   `_autoStartHandled = true` and is reset only on a group switch (L222). The
   Fix 18 guard (L468-470) is inferred. Neither `return` logs anything.
2. Causality of the early abort. This needs a control in which the handler does
   not fire before T0 (R2a/R2b).
3. Correspondence with the owner's physical Samsung device.
4. R1-B and H2.

Diagnostic finding for R2 (no change authorized): in every run the coordinator
schedules and fires two start timers, because several `_handleGroupsAsync`
evaluations run concurrently at mount. In these runs there was a single
`running` write and no visible effect. This concurrency produced the V3
interleaving. It is not claimed as a defect.

### Intento 3 — execution results (2026-10-22)

Executed handoff section 12.3 once, 08:41:28–08:50:14 CEST.
`RUNNER_EXIT=1`, `SEQUENCE=COMPLETED suite_status=FAIL flutter_rc=1`.
The full suite verdict is `SUITE_FAIL`, with only the expected R1 specification
failures. This is a completed reproduction sequence, not a full-suite PASS,
a production fix, or bug closure. No stage was manually restarted.

Attempt 3 alone meets the recorded automated R1 thresholds: R1.0 PASS;
R1-A 5/5 VALID, 5/5 H1 with the same failure signature; R1-B VALID/H1 with
that signature; existing 219/219 PASS and no unexpected failure. Acceptance
by Claude and the owner's decision remain pending. Attempts 1 and 2, their
results, and Claude's V3 review above remain unchanged.

| Stage / run | delta_ms | latency_ms | Interleaving | Validity | Failed S checks | Notes |
|---|---|---|---|---|---|---|
| r1.0 | - | - | - | PASS (environment only) | - | Clock delta 0 ms; timer 302 ms; first pump 27,338 us; periodic ticks 1003, 2002, 3003 ms. |
| r1a/A1 | 905 | 1 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| r1a/A2 | 424 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| r1a/A3 | 608 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| r1a/A4 | 575 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| r1a/A5 | 561 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| r1b/B1 | 538 | 1 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/A1 | 127 | 1 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/A2 | 382 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/A3 | 599 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/A4 | 610 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/A5 | 604 | 0 | H1 | VALID | S1, S2, S4, S5 | S3 passes; exception=none; expected SPEC-FAIL. |
| full/R1.0 | - | - | - | PASS (environment only) | - | Clock delta 0 ms; timer 303 ms; first pump 28,877 us; ticks 1002, 2002, 3002 ms. |
| full/B1 | n/a | n/a | not run in this stage | skipped by design | not evaluated here | BUG041_LONG is not defined for the full suite; B1 ran separately in r1b above. |

Results in the three required groups:

1. Existing passing checks: analyzer no issues (36.4 s), exit 0; stage
   `existing` has 219/219 successes, no JSON errors, Flutter exit 0.
   R1.0 passes both separately and within the full suite. The full gate confirms
   all 219 existing tests pass again.
2. New tests failing against the specification: five R1-A tests and B1 all
   report VALID/H1, `FAIL[S1,S2,S4,S5]`, `exception=none`. The independent
   full-suite invocation of A1-A5 has the same validity, H1 classification and
   signature. Each failing test has exactly one JSON error, the framework's
   generic TestFailure; the unchanged gate accepts them as SPEC_FAIL.
3. Unexpected/unstable failures: none. No INVALID, INFRA, OTHER or alternative
   interleaving appears in attempt 3. Full suite: 220 successes (219 existing
   plus R1.0), five expected SPEC-FAIL tests, one intentional B1 skip; Flutter
   exit 1. There is no new failure in an existing test and no unexpected skip.

R1-B comparison with R1-A:

- A1-A5 mount inside the already-open five-minute notice window, six or more
  seconds before T0. All five attempt auto-start 424–905 ms before T0, then
  abort as not due within a reported 0–1 ms.
- B1 mounts before the one-minute window and follows the production pre-alert
  timer. `schedule-prealert-timer` is observed at T0-65,811 ms;
  `prealert-timer-fired` at T0-59,967 ms; first sampled Pre-Run UI at
  T0-59,392 ms (earlier than the required T0-50 s).
- B1 attempts auto-start at T0-538 ms and aborts as not due with reported
  latency 1 ms. The start timer fires at T0+34 ms; the persisted group is running
  at T0+40 ms with actualStartTime=T0 and the planned theoretical end.
  Checkpoints at +531, +2031 and +3080 ms still show ViewModel idle/1500 s,
  TimerService idle, enabled Start and Ready.
- A and B therefore show the same first symptom and S1/S2/S4/S5 signature while
  S3 passes. Opening the app before rather than inside the notice window does
  not remove the observed failure. Full-suite A runs repeat the same signature
  with earlier-attempt deltas 127–610 ms and reported latencies 0–1 ms.

What this demonstrates and what remains open:

- The automated Local Mode production entry paths reproduce the missing
  scheduled auto-start: persisted running at the correct anchor while the
  visible Run Mode and ViewModel remain Ready/idle at 25:00 through T0+3 s.
  Zero runtime starts/start sounds are observed in these failing runs; that
  does not validate duplicate prevention in a successful start.
- The ordered early-attempt -> not-due abort -> coordinator promotion -> pending
  id again -> no runtime start chain is consistent with the H1 classification.
  Silent guards and causality still need controls/review: H1 is not established
  as the production root cause. H2/alternating clocks, delayed manual Start,
  navigation/lifecycle recovery and completion at the planned end are not
  tested here.
- No physical Samsung validation, R1-C, R2/R3 or production correction was
  performed. BUG-041 remains Open, P1 provisional.

Changes, execution and integrity:

- Initial test SHA-256:
  `47b96386eee004d7918ac9f96c6613c1da2a7bce03c1a1cfa954c4530f5a7a0d`.
- Applied/tested/post-run test SHA-256:
  `1d92a9b9629627c6183581247e3d5762a71255f34387aa4fd0bf24312f723c66`.
- Applied only the extracted section 12.1 V3 diff with the section 12.3 step-2
  command. `git apply --check` succeeded; `dart format` reported 1 file,
  0 changed. No changes to other validity rules, S checks, classification,
  timing, mounting, timeouts, production paths or test logic outside that diff.
- Handoff SHA-256 before/after:
  `3e0975b0371401616d334c13461a6ce99f043ffa1ce50b00e1546583a8ea2fcc`.
  Runner-block SHA-256 before/after:
  `d0be6d7c2af0da792fceafab600cf908018b9885f149f176da7bfa8fdb33124a`.
  Neither was edited.
- Branch `fix/local-scheduled-autostart`, HEAD `1561ead` throughout.
  Tracked and staged diffs are empty. Only the authorized test, plan and
  checklist were edited; twelve separate `_a3_` logs were produced.
  No .git mutation, staging, commit, push, PR or merge. No production, other
  test, dependency, configuration, spec, roadmap or canonical bug/ledger/dev-log
  change. Four pre-existing private files remain untouched. The Drive temp
  directory listed during precheck was never accessed or changed by this task.
- No shell fallback and no new doubles. Production `FocusIntervalApp`, real
  Local repositories, coordinator, ViewModel and TimerService are retained.
  The five overrides and their reasons are unchanged from the attempt-1
  inventory: memory Local app-mode service, auth/firestore platform stubs,
  sound recorder and real device-info service initialized with a fixed test id.
  Default Android test platform; no test navigation/taps or post-mount writes.
- Group-seed references remain `task_list_screen.dart:1418-1447`,
  `task_group_planning_screen.dart:686-704` and
  `task_run_notice_service.dart:8-10`.

Exact runner invocation (section 12.3, one invocation):

```bash
F=docs/bugs/validation_bug041_2026_10_20
BUG041_ATTEMPT=3 /bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' "$F/codex_handoff.md"); echo "RUNNER_EXIT=$?"
```

The stage commands, including every tracked test argument, are preserved in
the `### cmd:` header of each human log and in the unchanged handoff runner.
The enclosing echo command exits 0; the actual runner reports
`RUNNER_EXIT=1`. Do not mistake the enclosing shell status for a passing suite.

Full attempt-3 summary (verbatim):

```log
08:41:28 SEQUENCE=START runner=bug041-r1 attempt=3 head=1561ead date=2026-10-22
08:41:29 ENV Flutter 3.41.2 • channel stable • https://github.com/flutter/flutter.git
08:41:29 STAGE=precheck VERDICT=PASS
08:42:09 STAGE=analyze VERDICT=PASS flutter_rc=0
08:43:42 STAGE=existing VERDICT=PASS flutter_rc=0 tests=219
08:43:55 STAGE=r1.0 VERDICT=PASS flutter_rc=0 tests=1
08:44:52 RUNS A1:H1:FAIL[S1,S2,S4,S5] A2:H1:FAIL[S1,S2,S4,S5] A3:H1:FAIL[S1,S2,S4,S5] A4:H1:FAIL[S1,S2,S4,S5] A5:H1:FAIL[S1,S2,S4,S5]
08:44:52 H1_SIGNATURE=FAIL[S1,S2,S4,S5]
08:44:52 STAGE=r1a VERDICT=EXPECTED_SPEC_FAIL flutter_rc=1 tests=5 detail=SPEC_FAIL:5 non_h1=0
08:46:16 RUNS B1:H1:FAIL[S1,S2,S4,S5]
08:46:16 H1_SIGNATURE=FAIL[S1,S2,S4,S5]
08:46:16 STAGE=r1b VERDICT=EXPECTED_SPEC_FAIL flutter_rc=1 tests=1 detail=SPEC_FAIL:1 non_h1=0
08:50:14 RUNS_FULL A1:VALID:H1:FAIL[S1,S2,S4,S5]
08:50:14 RUNS_FULL A2:VALID:H1:FAIL[S1,S2,S4,S5]
08:50:14 RUNS_FULL A3:VALID:H1:FAIL[S1,S2,S4,S5]
08:50:14 RUNS_FULL A4:VALID:H1:FAIL[S1,S2,S4,S5]
08:50:14 RUNS_FULL A5:VALID:H1:FAIL[S1,S2,S4,S5]
08:50:14 STAGE=full VERDICT=SUITE_FAIL flutter_rc=1 existing_pass=219 r1_spec_fail=5 r1_pass=1 r1_skipped=1
08:50:14 SEQUENCE=COMPLETED suite_status=FAIL flutter_rc=1
08:50:14 NOTE suite_status=FAIL with only R1 SPEC-FAIL failures is the expected reproduction outcome; it is not a PASS.
```

All attempt-3 RESULT lines (verbatim; stage names keep independent invocations
of A1-A5 distinct):

Stage `r1a`:

```log
BUG041-R1 RESULT run=A1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=905 latency_ms=1
BUG041-R1 RESULT run=A2 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=424 latency_ms=0
BUG041-R1 RESULT run=A3 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=608 latency_ms=0
BUG041-R1 RESULT run=A4 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=575 latency_ms=0
BUG041-R1 RESULT run=A5 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=561 latency_ms=0
```

Stage `r1b`:

```log
BUG041-R1 RESULT run=B1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=538 latency_ms=1
```

Stage `full`:

```log
BUG041-R1 RESULT run=A1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=127 latency_ms=1
BUG041-R1 RESULT run=A2 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=382 latency_ms=0
BUG041-R1 RESULT run=A3 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=599 latency_ms=0
BUG041-R1 RESULT run=A4 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=610 latency_ms=0
BUG041-R1 RESULT run=A5 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=604 latency_ms=0
```

Historical checksum verification before attempt 3 (verbatim stdout):

```text
2026-10-22_bug041_analyze_1561ead_macos_debug.log: OK
2026-10-22_bug041_analyze_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_a2_1561ead_macos_debug.log: OK
```

Historical checksum verification after attempt 3 (verbatim stdout):

```text
2026-10-22_bug041_analyze_1561ead_macos_debug.log: OK
2026-10-22_bug041_analyze_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_existing_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r10_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_1561ead_macos_debug.log: OK
2026-10-22_bug041_r1a_json_a2_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_1561ead_macos_debug.log: OK
2026-10-22_bug041_summary_a2_1561ead_macos_debug.log: OK
```

New attempt-3 files (all under this packet's `logs/`; all twelve produced):

- `2026-10-22_bug041_analyze_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_existing_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_existing_json_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_full_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_full_json_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r10_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r10_json_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1a_json_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1b_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_r1b_json_a3_1561ead_macos_debug.log`
- `2026-10-22_bug041_summary_a3_1561ead_macos_debug.log`

Post-run `git status --short` (verbatim):

```text
?? FOCUSINTERVAL-notas-todo.txt
?? chat-claude.md
?? chatgpt-chat.md
?? docs/bugs/validation_bug041_2026_10_20/
?? docs/features/feature_2026_10_15_v1-store-release/respuesta-claude.md
?? test/presentation/timer_screen_local_scheduled_autostart_test.dart
```

`git diff --stat`: empty (exit 0). Staged diff also empty.

Complete trace locations for all observed runs:

- `r1a/A1`: `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`, lines 52-138, 81 TRACE lines plus checkpoints/RESULT.
- `r1a/A2`: `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`, lines 236-324, 83 TRACE lines plus checkpoints/RESULT.
- `r1a/A3`: `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`, lines 424-514, 85 TRACE lines plus checkpoints/RESULT.
- `r1a/A4`: `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`, lines 610-698, 83 TRACE lines plus checkpoints/RESULT.
- `r1a/A5`: `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`, lines 796-885, 84 TRACE lines plus checkpoints/RESULT.
- `r1b/B1`: `logs/2026-10-22_bug041_r1b_a3_1561ead_macos_debug.log`, lines 51-376, 320 TRACE lines plus checkpoints/RESULT.
- `full/A1`: `logs/2026-10-22_bug041_full_a3_1561ead_macos_debug.log`, lines 1241-1319, 73 TRACE lines plus checkpoints/RESULT.
- `full/A2`: `logs/2026-10-22_bug041_full_a3_1561ead_macos_debug.log`, lines 1413-1499, 81 TRACE lines plus checkpoints/RESULT.
- `full/A3`: `logs/2026-10-22_bug041_full_a3_1561ead_macos_debug.log`, lines 1597-1687, 85 TRACE lines plus checkpoints/RESULT.
- `full/A4`: `logs/2026-10-22_bug041_full_a3_1561ead_macos_debug.log`, lines 1789-1877, 83 TRACE lines plus checkpoints/RESULT.
- `full/A5`: `logs/2026-10-22_bug041_full_a3_1561ead_macos_debug.log`, lines 1979-2067, 83 TRACE lines plus checkpoints/RESULT.

<details>
<summary>r1a/A1: complete valid H1 trace, five checkpoints and RESULT</summary>

Copied verbatim from `logs/2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log`,
lines 52-138; every TRACE line is included.

```log
BUG041-R1 TRACE run=A1 t=-6820 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-6789 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-6780 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-6775 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 08:44:02.181444 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=-6771 src=coordinator data=[ScheduledGroups][no-groups] mode=local now=2026-10-22 08:44:02.210876 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=-6767 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 08:44:02.219903 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A1-1792651442055561:2026-10-22T08:44:09.000|2026-10-22T08:44:09.000
BUG041-R1 TRACE run=A1 t=-6758 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=-6755 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792651442055561 token=1792651442242257
BUG041-R1 TRACE run=A1 t=-6754 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A1-1792651442055561 start=2026-10-22 08:44:09.000 delay=6s
BUG041-R1 TRACE run=A1 t=-6752 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 08:44:02.241649 scheduled=1 overdue=0 activeSession=n/a sample=bug041-r1-A1-1792651442055561:2026-10-22T08:44:09.000|2026-10-22T08:44:09.000
BUG041-R1 TRACE run=A1 t=-6751 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792651442055561 token=1792651442248296
BUG041-R1 TRACE run=A1 t=-6751 src=coordinator data=[ScheduledGroups] schedule-start-timer group=bug041-r1-A1-1792651442055561 start=2026-10-22 08:44:09.000 delay=6s
BUG041-R1 TRACE run=A1 t=-5608 src=screen data=[RunModeDiag] Active session cleared route=/tasks
BUG041-R1 TRACE run=A1 t=-5569 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792651442055561 route=/tasks
BUG041-R1 TRACE run=A1 t=-5539 src=persisted data=status=scheduled scheduledStart=2026-10-22T08:44:09.000 actualStart=null theoreticalEnd=2026-10-22T09:09:09.000 noticeSentAt=2026-10-22T08:44:02.236934 updatedAt=2026-10-22T08:44:02.236934
BUG041-R1 TRACE run=A1 t=-5513 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=false ready=false
BUG041-R1 TRACE run=A1 t=-5133 src=frame data=pump_us=378656
BUG041-R1 TRACE run=A1 t=-5131 src=vm data=status=idle phase=null remaining=0 starts=0
BUG041-R1 TRACE run=A1 t=-5130 src=timer-service data=group=null status=idle phase=pomodoro remaining=0 phaseStartedAt=null
BUG041-R1 TRACE run=A1 t=-5109 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=false ready=false
BUG041-R1 TRACE run=A1 t=-5093 src=vm data=status=idle phase=null remaining=1500 starts=0
BUG041-R1 TRACE run=A1 t=-5089 src=screen data=[RunModeDiag] Timer load group=bug041-r1-A1-1792651442055561 result=PomodoroGroupLoadResult.loaded status=scheduled route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-4936 src=frame data=pump_us=173119
BUG041-R1 TRACE run=A1 t=-4820 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-4519 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-4221 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3969 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3865 src=frame data=pump_us=57343
BUG041-R1 TRACE run=A1 t=-3706 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3455 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-3398 src=frame data=pump_us=57115
BUG041-R1 TRACE run=A1 t=-3186 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2883 src=frame data=pump_us=55380
BUG041-R1 TRACE run=A1 t=-2870 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2557 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2316 src=frame data=pump_us=50103
BUG041-R1 TRACE run=A1 t=-2297 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-2019 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1736 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1488 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-1221 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-923 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-909 src=pending data=previous=null value=bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-907 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A1-1792651442055561 screen=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-905 src=screen data=[RunModeDiag] Auto-start attempt group=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-903 src=screen data=[RunModeDiag] Auto-start abort (not due) status=scheduled scheduledStart=2026-10-22 08:44:09.000 now=2026-10-22 08:44:08.096173
BUG041-R1 TRACE run=A1 t=-903 src=pending data=previous=bug041-r1-A1-1792651442055561 value=null
BUG041-R1 TRACE run=A1 t=-903 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=bug041-r1-A1-1792651442055561 next=null screen=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-858 src=screen data=[RunModeDiag] Auto-start skip pending=null screen=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=-857 src=frame data=pump_us=66628
BUG041-R1 TRACE run=A1 t=-654 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-357 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=-106 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=true start=false ready=false
BUG041-R1 TRACE run=A1 t=8 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A1-1792651442055561 now=2026-10-22 08:44:09.008188
BUG041-R1 TRACE run=A1 t=8 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=true preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=10 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 08:44:09.009022 scheduled=1 overdue=1 activeSession=n/a sample=bug041-r1-A1-1792651442055561:2026-10-22T08:44:09.000|2026-10-22T08:44:09.000
BUG041-R1 TRACE run=A1 t=14 src=persisted data=status=running scheduledStart=2026-10-22T08:44:09.000 actualStart=2026-10-22T08:44:09.000 theoreticalEnd=2026-10-22T09:09:09.000 noticeSentAt=2026-10-22T08:44:02.236934 updatedAt=2026-10-22T08:44:09.012543
BUG041-R1 TRACE run=A1 t=18 src=pending data=previous=null value=bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=18 src=screen data=[RunModeDiag] scheduledAutoStartGroupId changed prev=null next=bug041-r1-A1-1792651442055561 screen=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=20 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792651442055561 token=1792651449019702
BUG041-R1 TRACE run=A1 t=22 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=69 src=frame data=pump_us=75212
BUG041-R1 TRACE run=A1 t=81 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-A1-1792651442055561 now=2026-10-22 08:44:09.081213
BUG041-R1 TRACE run=A1 t=82 src=coordinator data=[ScheduledGroups] timer-state reason=handle-groups scheduled=false preAlert=false runningExpiry=false
BUG041-R1 TRACE run=A1 t=83 src=coordinator data=[ScheduledGroups][evaluate] mode=local now=2026-10-22 08:44:09.082514 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=88 src=coordinator data=[ScheduledGroups][running-open-timer] mode=local now=2026-10-22 08:44:09.082514 scheduled=0 overdue=0 activeSession=n/a sample=n/a
BUG041-R1 TRACE run=A1 t=89 src=coordinator-action data=type=openTimer group=bug041-r1-A1-1792651442055561 token=1792651449089248
BUG041-R1 TRACE run=A1 t=90 src=autostarter data=[RunModeDiag] Auto-start navigate group=bug041-r1-A1-1792651442055561 route=/timer/bug041-r1-A1-1792651442055561
BUG041-R1 TRACE run=A1 t=168 src=frame data=pump_us=88299
BUG041-R1 TRACE run=A1 t=175 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=449 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=716 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=983 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1250 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1515 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=1759 src=frame data=pump_us=76425
BUG041-R1 TRACE run=A1 t=1766 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2032 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2300 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2566 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 TRACE run=A1 t=2817 src=ui data=route=/timer/bug041-r1-A1-1792651442055561 preRun=false start=true ready=true
BUG041-R1 CHECKPOINT run=A1 t=-1965 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792651442055561 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=-456 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792651442055561 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=516 persisted.status=running persisted.actualStart=2026-10-22T08:44:09.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792651442055561 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792651442055561 timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=2033 persisted.status=running persisted.actualStart=2026-10-22T08:44:09.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792651442055561 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792651442055561 timerService=idle:0
BUG041-R1 CHECKPOINT run=A1 t=3017 persisted.status=running persisted.actualStart=2026-10-22T08:44:09.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-A1-1792651442055561 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-A1-1792651442055561 timerService=idle:0
BUG041-R1 RESULT run=A1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=905 latency_ms=1
```

</details>

B1 pre-alert/boundary evidence excerpt (selected lines, not the complete trace;
the complete 320-event trace is at the location listed above):

```log
BUG041-R1 TRACE run=B1 t=-65811 src=coordinator data=[ScheduledGroups] schedule-prealert-timer group=bug041-r1-B1-1792651505979832 preAlertStart=2026-10-22 08:45:12.000 delay=5s
BUG041-R1 TRACE run=B1 t=-59967 src=coordinator data=[ScheduledGroups] prealert-timer-fired group=bug041-r1-B1-1792651505979832 now=2026-10-22 08:45:12.031037
BUG041-R1 TRACE run=B1 t=-59392 src=ui data=route=/timer/bug041-r1-B1-1792651505979832 preRun=true start=false ready=false
BUG041-R1 TRACE run=B1 t=-538 src=screen data=[RunModeDiag] Auto-start attempt group=bug041-r1-B1-1792651505979832 route=/timer/bug041-r1-B1-1792651505979832
BUG041-R1 TRACE run=B1 t=-537 src=screen data=[RunModeDiag] Auto-start abort (not due) status=scheduled scheduledStart=2026-10-22 08:46:12.000 now=2026-10-22 08:46:11.462614
BUG041-R1 TRACE run=B1 t=34 src=coordinator data=[ScheduledGroups] start-timer-fired group=bug041-r1-B1-1792651505979832 now=2026-10-22 08:46:12.034262
BUG041-R1 TRACE run=B1 t=40 src=persisted data=status=running scheduledStart=2026-10-22T08:46:12.000 actualStart=2026-10-22T08:46:12.000 theoreticalEnd=2026-10-22T09:11:12.000 noticeSentAt=2026-10-22T08:45:12.036330 updatedAt=2026-10-22T08:46:12.038871
BUG041-R1 CHECKPOINT run=B1 t=-1992 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-B1-1792651505979832 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=B1 t=-394 persisted.status=scheduled persisted.actualStart=null vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-B1-1792651505979832 ui.preRun=true ui.start=false ui.ready=false pending=null timerService=idle:0
BUG041-R1 CHECKPOINT run=B1 t=531 persisted.status=running persisted.actualStart=2026-10-22T08:46:12.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-B1-1792651505979832 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-B1-1792651505979832 timerService=idle:0
BUG041-R1 CHECKPOINT run=B1 t=2031 persisted.status=running persisted.actualStart=2026-10-22T08:46:12.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-B1-1792651505979832 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-B1-1792651505979832 timerService=idle:0
BUG041-R1 CHECKPOINT run=B1 t=3080 persisted.status=running persisted.actualStart=2026-10-22T08:46:12.000 vm.status=idle vm.remaining=1500 ui.route=/timer/bug041-r1-B1-1792651505979832 ui.preRun=false ui.start=true ui.ready=true pending=bug041-r1-B1-1792651505979832 timerService=idle:0
BUG041-R1 RESULT run=B1 validity=VALID interleaving=H1 spec=FAIL[S1,S2,S4,S5] exception=none delta_ms=538 latency_ms=1
```

No non-H1 or invalid trace exists in attempt 3. All complete raw traces remain
in the named human logs and their JSON counterparts.

Next action for Claude: review the exact V3 diff, R1-A, R1-B and the full-suite
evidence from attempt 3 independently of earlier attempts. Confirm whether R1
is accepted, then let the owner authorize any next step. No production fix,
further run or Git action is authorized by this record.

## Comandos de ejecución

Run from the repo root with the runner embedded in `codex_handoff.md` (executed
verbatim; preserves each real exit code, stops on unexpected or invalid results).

Attempt 2 onwards (approved 2026-10-22; full steps in `codex_handoff.md`
section 11.3). `BUG041_ATTEMPT` is mandatory (integer >= 2); the runner stops
before any write if it is missing or invalid, or if any output of that attempt
already exists:

```bash
BUG041_ATTEMPT=2 /bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' docs/bugs/validation_bug041_2026_10_20/codex_handoff.md); echo "RUNNER_EXIT=$?"
```

Attempt-2 logs carry `_a2` in the fix-id (for example
`2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`). Post-run scan:

```bash
rg -n "VERDICT|SEQUENCE" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_summary_a2_*.log
rg -n "BUG041-R1 RESULT" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_r1[ab]_a2_1561ead_macos_debug.log
```

Attempt 1 (2026-10-22, historical; this command now stops at precheck):

```bash
/bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' docs/bugs/validation_bug041_2026_10_20/codex_handoff.md); echo "RUNNER_EXIT=$?"
```

Expected runner exit: `1` (completed, suite FAIL only from R1 SPEC-FAIL). `2` =
stopped; see the summary log.

Logs written to `docs/bugs/validation_bug041_2026_10_20/logs/` (date = real run
date, hash = HEAD, `1561ead`; attempt N >= 2 adds `_a<N>` after the stage id):

- `<date>_bug041_summary_1561ead_macos_debug.log` (all stage verdicts)
- `<date>_bug041_analyze_1561ead_macos_debug.log`
- `<date>_bug041_existing_1561ead_macos_debug.log` + `_existing_json_`
- `<date>_bug041_r10_1561ead_macos_debug.log` + `_r10_json_`
- `<date>_bug041_r1a_1561ead_macos_debug.log` + `_r1a_json_`
- `<date>_bug041_r1b_1561ead_macos_debug.log` + `_r1b_json_`
- `<date>_bug041_full_1561ead_macos_debug.log` + `_full_json_`

## Log analysis - quick scan

Bug present signals:

```bash
rg -n "VERDICT|SEQUENCE" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_summary_*.log
rg -n "BUG041-R1 RESULT .*interleaving=H1 .*spec=FAIL" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_r1[ab]_1561ead_macos_debug.log
rg -n "Auto-start abort \(not due\)|start-timer-fired|scheduledAutoStartGroupId changed" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_r1[ab]_1561ead_macos_debug.log
```

Fix working signals (for a future fix step; not expected in R1):

```bash
rg -n "BUG041-R1 RESULT .*validity=VALID .*spec=PASS" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_r1[ab]_*.log
rg -n "Auto-start startFromAutoStart" docs/bugs/validation_bug041_2026_10_20/logs/*_bug041_r1[ab]_*.log
```

## Verificación local

- [x] `flutter analyze` PASS (runner stage `analyze`, 2026-10-22, exit 0).
- [x] Existing suite 219/219 PASS (runner stage `existing`, exit 0).
- [x] R1.0 PASS (exit 0; real clock/pump values in the results table).
- [ ] R1-A gate `EXPECTED_SPEC_FAIL`: not obtained; STOPPED/INFRA, Flutter exit 1, no valid RESULT lines.
- [ ] R1-B gate `EXPECTED_SPEC_FAIL`: not run because the runner stopped at R1-A.
- [ ] Real full suite reported as `SUITE_FAIL`: not run because the runner stopped at R1-A.
- [x] `git diff --stat` empty for tracked files; only the authorized new test/packet and pre-existing private untracked paths.

Runner invoked once, with final stdout `RUNNER_EXIT=2`. The handoff remains
byte-identical (SHA-256 `b32a2da91da4ab8b1fb4461feddec7b28209b993aa8d083e77b6d69330a870d9`).
The test remains byte-identical to the attempted run after the stop (SHA-256
`75f52f6693ec657562edb03df006b1fb6461f16378340fc1a08d0783b16f4110`).
No staging, commits, push, PR, merge, device run, R1-C, R2/R3, or production fix.

### Attempt-2 local verification (2026-10-22)

- [x] (intento 2) Pre-check branch/HEAD, clean tracked/index state, original
  test SHA-256, exact eight original log names and all eight checksums matched.
- [x] (intento 2) Exact authorized repair; formatter 0 changed; result SHA-256
  matched and stayed unchanged after the stop.
- [x] (intento 2) `flutter analyze`: no issues, exit 0.
- [x] (intento 2) Existing suite: 219/219 PASS, Flutter exit 0.
- [x] (intento 2) R1.0 PASS, Flutter exit 0; real-clock measurements recorded.
- [ ] (intento 2) R1-A accepted: gate INVALID (A2/A4 V3), not
  `EXPECTED_SPEC_FAIL`; A1/A3/A5 are valid SPEC-FAIL only.
- [ ] (intento 2) R1-B: not run; blocked by the R1-A stop.
- [ ] (intento 2) Real full suite: not run; no `SUITE_FAIL` or PASS claim.
- [x] (intento 2) Runner invoked once, `RUNNER_EXIT=2`; full summary and
  per-run results above. No manual continuation or post-stop test edits.
- [x] (intento 2) Eight original logs verify OK after execution; eight
  separate `_a2_` logs preserved; handoff hash unchanged.
- [x] (intento 2) `git diff --stat` and staged diff empty; authorized
  test/packet remain untracked; four private untracked paths preserved.

### Attempt-3 local verification (2026-10-22)

- [x] (intento 3) Branch/HEAD and clean tracked/index state match;
  initial test hash matches; all sixteen historical log checksums OK before.
- [x] (intento 3) Exact section 12.1 V3 diff; formatter 0 changed;
  result SHA-256 `1d92a9b9629627c6...` matches before/after execution.
- [x] (intento 3) Analyzer no issues, Flutter exit 0.
- [x] (intento 3) Existing suite 219/219 PASS, Flutter exit 0.
- [x] (intento 3) R1.0 PASS separately and in the full suite.
- [x] (intento 3) R1-A gate `EXPECTED_SPEC_FAIL`: 5/5 VALID, 5/5 H1,
  same `FAIL[S1,S2,S4,S5]`, no unexpected exception.
- [x] (intento 3) R1-B gate `EXPECTED_SPEC_FAIL`: VALID/H1, same signature.
- [x] (intento 3) Real full suite `SUITE_FAIL`, Flutter exit 1:
  219 existing PASS, R1.0 PASS, five expected SPEC-FAIL, one intentional B1 skip.
  No global PASS claim.
- [x] (intento 3) One runner invocation; `RUNNER_EXIT=1`,
  `SEQUENCE=COMPLETED`; no manual continuation or post-run test edit.
- [x] (intento 3) All sixteen historical logs still OK; twelve separate
  `_a3_` logs preserved; handoff and runner hashes unchanged.
- [x] (intento 3) Attempts 1/2 and Claude's V3 review retained unchanged;
  full summary, all RESULT lines, table, B1 comparison and complete H1 trace
  recorded in the results block.
- [x] (intento 3) Tracked/staged diffs empty, expected branch/HEAD retained,
  private files and Drive temp files untouched.
- [ ] (intento 3) Claude's acceptance review and owner's next authorization.

### Evidence index — local-only logs (recorded 2026-10-23)

The 28 run logs of attempts 1-3 stay outside Git (`*.log` is ignored as
local-only validation evidence; several contain absolute local paths). They
are kept in this folder locally and in the owner's private backup. Verify a
copy with `shasum -a 256 -c` from `logs/`:

```text
ef069be9afbdebd92382f78bbc1dbe9ebdedc46b43a63910e4435703f2a1e756  2026-10-22_bug041_analyze_1561ead_macos_debug.log
8944e727cd91fccb5c2d546a0bb109e602350d43c7b90e43bc0f84fa2e489cfa  2026-10-22_bug041_analyze_a2_1561ead_macos_debug.log
f3a4082784d898e4cc3d64350eccee4dd19800ddec534586e885c7c7c8b05043  2026-10-22_bug041_analyze_a3_1561ead_macos_debug.log
71d2ffc747293d71afd5715edd564e1bd171038572d106976c47b191ef47e5fc  2026-10-22_bug041_existing_1561ead_macos_debug.log
b0078f86bb2866ba51e54ae21567a2a56962a5a9f20a988ddac8ab1b8e8dd227  2026-10-22_bug041_existing_a2_1561ead_macos_debug.log
e70bd97b422511fc5c911786d09ad6a1133614595b812de6d603aa0335f6ea63  2026-10-22_bug041_existing_a3_1561ead_macos_debug.log
429e40af8f8b3b7e52d1dc1adb04915742776568d2ce510c76c3154ee27acfb1  2026-10-22_bug041_existing_json_1561ead_macos_debug.log
f5dc3316cd92617f62eb68146d18d5998294210ca7383a53d0dc8827887f0659  2026-10-22_bug041_existing_json_a2_1561ead_macos_debug.log
a828ad08bd8430382e1926ecfe3994c364235929845f9887cc666bd0423bcfa7  2026-10-22_bug041_existing_json_a3_1561ead_macos_debug.log
d096d03f0cb27db7f4b2922c90c983ef14d133b1033efeed784e9fd8ea360332  2026-10-22_bug041_full_a3_1561ead_macos_debug.log
af905f832a030d8c5b2a0f8fc5699d5205b7644837c5b668596f03ecd019cf7c  2026-10-22_bug041_full_json_a3_1561ead_macos_debug.log
009b197eef62c0f1a97517414f033b78d5c98ed6e43a2c564f902946e4850e02  2026-10-22_bug041_r10_1561ead_macos_debug.log
23409e89bc2900e3651f5e71ac0622a39df53ac071be23a5fe06f25c223bfc72  2026-10-22_bug041_r10_a2_1561ead_macos_debug.log
72d6c90ca883cc8a098f5fa1040ee5828a4dc425c63bc035b3673bda7ad3a91c  2026-10-22_bug041_r10_a3_1561ead_macos_debug.log
8aeddea26cc7b31253a750ac8f5f5d31980220b7dad45d378ae3b259a00759de  2026-10-22_bug041_r10_json_1561ead_macos_debug.log
fdaeab3e777c228a8222a046082edf7b473faf4b0bc1197e00c66442f9a8bbe6  2026-10-22_bug041_r10_json_a2_1561ead_macos_debug.log
a7958e4f03b6cd07ee77b6458b980a75297ce6e1aae3d732f1bbb1d92c7d3958  2026-10-22_bug041_r10_json_a3_1561ead_macos_debug.log
3f773a1caa74cae009ee0f75dbfa89b63490ca1365ab414984a4913f86738d85  2026-10-22_bug041_r1a_1561ead_macos_debug.log
02a02d8dead6791f49df39e3420c4d74e6c2e08f37ecf1314a169f81daefc020  2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log
16e66e91ad1ae3d2c37c7684d6e42772c22f44e1b148d06a47e5af4f848b4b5c  2026-10-22_bug041_r1a_a3_1561ead_macos_debug.log
c8bb4793b4c105f91de771d30971c4008a1c363e1e0aeda1e781b8333970f2f4  2026-10-22_bug041_r1a_json_1561ead_macos_debug.log
eedd86b040750abe4cbbbf11c0350de4703f61add9b1e5347eea3b2730344df5  2026-10-22_bug041_r1a_json_a2_1561ead_macos_debug.log
491c2834e48c9ab02224faecae2a84a37bbd2b91677961b11149e6be29bcfdc9  2026-10-22_bug041_r1a_json_a3_1561ead_macos_debug.log
6145af2121eb450f75155ff1a598d973bc247fd902ad44e37dfe1dae3e290711  2026-10-22_bug041_r1b_a3_1561ead_macos_debug.log
2289203bfbd3df972638c2dd4cb1fa493d7fa0e7f3693a9a826a56836676fe48  2026-10-22_bug041_r1b_json_a3_1561ead_macos_debug.log
30ae3f395082813a036300962b4410182311a27f948a07828ac7f339e90a2ee5  2026-10-22_bug041_summary_1561ead_macos_debug.log
a615fdf142448b0a7c30e8e5faeee379f7a1e315d5d9303293b2a162a5591284  2026-10-22_bug041_summary_a2_1561ead_macos_debug.log
3ee1ffeb1cf633f4ffa2ddae002a1067388a002ac005667bbb60e471d834424b  2026-10-22_bug041_summary_a3_1561ead_macos_debug.log
```

The R1 reproduction test is also kept outside Git while it fails by design:
`test/presentation/timer_screen_local_scheduled_autostart_test.dart`, sha256
`1d92a9b9629627c6183581247e3d5762a71255f34387aa4fd0bf24312f723c66`. It is to
be committed together with the fix, when its specification checks pass.

## Criterios de cierre

R1 step (reproduction), evaluated by Claude and decided by the owner:
1. R1.0 PASS.
2. R1-A: 5/5 valid, at least 4/5 H1, identical SPEC-FAIL signature including S1
   and S5.
3. R1-B: valid, H1, same signature as R1-A.
4. Existing tests 219/219 PASS; no unexpected failure anywhere.
5. No tracked file modified; no commit.

Bug closure (not this step): requires an approved fix (Step C), regression
coverage, device validation on the physical Samsung in Local Mode, and the
closure flow in `CLAUDE.md` section 11. BUG-041 stays Open, P1 provisional.

## Status

Open - 2026-10-22, attempt 3: `RUNNER_EXIT=1`,
`SEQUENCE=COMPLETED suite_status=FAIL`; full gate `SUITE_FAIL` with
219 existing tests PASS and only five expected R1 SPEC-FAIL tests.
R1-A 5/5 VALID/H1 and B1 VALID/H1 share `FAIL[S1,S2,S4,S5]`.
Automated R1 evidence meets the recorded thresholds on attempt 3 alone;
Claude's review and the owner's decision are pending. Attempts 1/2 and the
V3 review remain unchanged. BUG-041 stays Open, P1 provisional; H1/H2 are
not established as root cause. No production fix, physical-device run,
commit, push, PR or merge.

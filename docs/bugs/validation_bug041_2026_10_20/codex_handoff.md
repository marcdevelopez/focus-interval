# Codex Handoff - BUG-041 Step B / R1 (automated reproduction)

Date: 2026-10-20
Author: Claude (orchestrator, QA) · Consumer: Codex
Owner approval (2026-10-20): R1.0, R1-A and R1-B only. R1-C is deferred and not
authorized. No fix, no R2/R3. BUG-041 stays Open, P1 provisional.

## 1. Branch

- `fix/local-scheduled-autostart` (local, unpublished). Do not switch branches.

## 2. Reference commit

- Base HEAD: `1561ead` (Step A, docs only).
- After this step the working tree contains, uncommitted, only: the new test file
  and this validation folder. No commits are authorized.

## 3. Mandatory read before coding

1. `CLAUDE.md` section 3 (AP-1..AP-4) and section 4 (G-1..G-6).
2. `AGENTS.md` -> "Bug validation workflow".
3. `docs/bugs/bug_log.md` -> BUG-041 (observations, H1/H2 hypotheses, R1-R6 plan).
4. `docs/specs.md` L1567-1597 (scheduled start contract) and section 10.4.1.a
   (L1605-1672, Pre-Run Countdown Mode; L1655: "When the countdown reaches zero,
   the group must auto-start without user action.").
5. `plan_validacion_rapida_fix.md` in this folder.

## 4. Authorization and scope

Authorized:
- Create `test/presentation/timer_screen_local_scheduled_autostart_test.dart`
  (the only new code file).
- Run the runner in section 7 (R1.0 -> R1-A -> R1-B -> real full suite, with
  automatic stop gates).
- Record results in place in `plan_validacion_rapida_fix.md` (section 5 results
  table, section 8, section 10) and `quick_pass_checklist.md`. Logs are written by
  the runner into `logs/`.

Not authorized:
- Any change to `lib/`, existing tests, shared test helpers, `pubspec.yaml`,
  `pubspec.lock`, `analysis_options.yaml`, specs, roadmap, `bug_log.md`,
  `validation_ledger.md`, `dev_log.md`, `.gitignore`, `.git/`.
- `git add`, commit, push, PR, merge, stash, clean, branch switch.
- Touching private untracked files (`FOCUSINTERVAL-notas-todo.txt`,
  `chat-claude.md`, `chatgpt-chat.md`,
  `docs/features/feature_2026_10_15_v1-store-release/respuesta-claude.md`) or the
  Google Drive temp folder `.tmp.driveupload/`.
- R1-C (17-minute "never press Start" run), R2, R3, any fix, any synthetic variant.
- Editing the test, the timing or the classification to obtain a particular
  outcome. The goal is to reproduce and measure the failure, not to confirm H1.
- Re-running stages after a stop. Report first; the owner decides.

## 5. Why one real clock (context, already verified by Claude)

- Production reads `DateTime.now()` directly (no clock seam). The owner did not
  authorize adding one.
- The default `testWidgets` binding advances `Timer`s with fake time while
  `DateTime.now()` stays real, so event orderings could be test artifacts.
  Rejected.
- `LiveTestWidgetsFlutterBinding` (Flutter 3.41.2, checked in the local SDK and
  with a throwaway probe outside the repo on 2026-10-20):
  - `clock` is the real clock (`binding.dart:2424`); measured difference with
    `DateTime.now()` = 0 ms.
  - `pump(duration)` waits on a real `Timer` (`binding.dart:2694-2716`); app timers
    are real.
  - Default per-test timeout is `Timeout.none` (`binding.dart:2434`), so every
    test MUST declare an explicit timeout. Verified: an explicit 2 s timeout fires
    ("Test timed out after 2 seconds").
  - A `fail('...')` inside `testWidgets` reaches the JSON reporter only as the
    generic error `Test failed. See exception logs above.`
    (`test_exception_reporter.dart:28-42`); the original message is printed in the
    test output, twice (when caught and at test end). The runner gate therefore
    classifies by the printed `BUG041-R1 ...` lines, not by the error text.
  - `skip: !const bool.fromEnvironment('BUG041_LONG')` skips without the define and
    runs with `--dart-define=BUG041_LONG=true`. Verified both ways.
  - `--plain-name` is a substring filter; two `--name` flags are ANDed; a filter
    that matches nothing exits 79 ("No tests ran"). Verified on an existing test.
- Code reading behind the expected interleaving (hypothesis H1, NOT a demonstrated
  root cause):
  - Pre-Run tick: `Timer.periodic(1 s)` + `info.end.difference(now).inSeconds`
    truncates to 0 when less than 1 s remains, so `_handlePreRunCountdownFinished`
    can fire before T0 (`timer_screen.dart:918-960`).
  - `_attemptScheduledAutoStart` then aborts with `Auto-start abort (not due)` and
    clears the pending id (`timer_screen.dart:341-396`).
  - The coordinator start timer never acts before T0 (re-checks real time and
    reschedules) and sets `running` with `actualStartTime = scheduledStart`
    (`scheduled_group_coordinator.dart:532-557`, `1306-1367`).
  - Afterwards `_maybeAutoStartScheduled` returns on `_autoStartHandled`
    (`timer_screen.dart:330-339`) and `_maybeAutoStartRunningGroup` returns in
    Local when `actualStartTime != null` (Fix 18 guard, `timer_screen.dart:468-470`).
  - R1 can show the symptom and the event sequence. It cannot prove which guard
    blocks the start (no logs on those returns); that remains an inference.

## 6. Test file specification

### 6.1 Binding, frames, names, timeouts

- First statements of `main()`:
  `final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();`
  `binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;`
- Frames only through helpers `runFor(tester, duration)` / `runUntil(tester,
  instant)` that loop `await tester.pump(const Duration(milliseconds: 16))` and
  record each pump's real duration with a `Stopwatch`. Never `pumpAndSettle`,
  never `runAsync`.
- No `group()`. Exact test names (the runner filters on them):
  - `BUG041 R1.0 clock probe`
  - `BUG041 R1-A run 1` ... `BUG041 R1-A run 5` (generated in a loop)
  - `BUG041 R1-B app open before Pre-Run window`
- Explicit timeouts in this exact literal form (the runner checks it):
  `timeout: const Timeout(Duration(seconds: N))` with N = 30 (R1.0), 60 (each
  R1-A), 180 (R1-B). Never `Timeout.none`.
- R1-B only: `skip: !const bool.fromEnvironment('BUG041_LONG')`.

### 6.2 App and environment (real execution paths)

- Mount the production app (`FocusIntervalApp`: production router,
  `ScheduledGroupAutoStarter` and the other app wrappers) inside
  `UncontrolledProviderScope(container: container, child: ...)`.
- Fallback only if that cannot mount without touching `lib/`: a minimal shell with
  the real `ScheduledGroupAutoStarter` and
  `GoRouter(navigatorKey: rootNavigatorKey, initialLocation: '/tasks')`, where
  `/tasks` is an empty placeholder and `/timer/:id` builds
  `TimerScreen(groupId: id)` exactly like production. Record it as a DEVIATION in
  the plan with the reason. If neither works: stop and report.
- Local Mode with the real local data path:
  - `SharedPreferences.setMockInitialValues({})` at the start of each test.
  - Local mode as in `scheduled_group_coordinator_test.dart`
    (`AppModeService.memory()` defaults to Local).
  - Do NOT override: `taskRunGroupRepositoryProvider` (real
    `LocalTaskRunGroupRepository`), `pomodoroSessionRepositoryProvider` (real
    `NoopPomodoroSessionRepository` in Local), `timeSyncServiceProvider` (disabled
    by production in Local), `scheduledGroupCoordinatorProvider`,
    `pomodoroViewModelProvider`, `timerServiceProvider`, Local task/preset
    repositories.
- Allowed doubles: only platform services already replaced in existing tests
  (Firebase auth/firestore stubs, sound service as a call recorder, notification
  service if required, device info with a fixed id). List every override in the
  plan with its reason.
- Platform: the default test platform (Android). Do not override it.
- Group seed, written before mounting through the real Local repository API
  (equivalent to data persisted in an earlier session). Build it with the same
  fields the production scheduling flow assigns (`task_list_screen.dart` around
  L1426-1446, `task_group_planning_screen.dart` around L693); cite the lines in
  the plan:
  - unique id per run; `status: scheduled`; 1 task, 25-min pomodoro, 1 pomodoro;
  - `noticeMinutes`: 5 in R1-A (production default `defaultNoticeMinutes`,
    `task_run_notice_service.dart:8`; consistent with the owner scheduling less
    than 5 minutes ahead, effective value unconfirmed) and 1 in R1-B (keeps the
    full-window run near 75 s; allowed range 0-15, lines 9-10);
  - `scheduledStartTime: T0`, a whole second with 0 ms;
  - `totalDurationSeconds` and `theoreticalEndTime` computed as production does;
  - `scheduledByDeviceId` = the test device id.
- After mounting, the test only observes: no navigation, no taps, no repository
  writes, no direct ViewModel calls.
- Teardown in `finally`: unmount (`pumpWidget(const SizedBox.shrink())`),
  `container.dispose()` (cancels real timers), restore `debugPrint`.

### 6.3 Instrumentation (observation only)

Record each event with real milliseconds relative to T0 (negative before T0):

| src | Source |
|---|---|
| `screen`, `autostarter` | Captured production `debugPrint` lines with `[RunModeDiag]` |
| `coordinator` | Captured production `debugPrint` lines with `[ScheduledGroups]` |
| `coordinator-action` | `container.listen(scheduledGroupCoordinatorProvider)` (openTimer / openGroupsHub) |
| `persisted` | `container.listen(taskRunGroupStreamProvider)` for this group (status, scheduledStartTime, actualStartTime, theoreticalEndTime, noticeSentAt, updatedAt), attached after the first app frame |
| `pending` | `container.listen(scheduledAutoStartGroupIdProvider)` |
| `vm` | `container.listen(pomodoroViewModelProvider)` (status, phase, remainingSeconds), attached only once `TimerScreen` is in the tree (autoDispose: earlier listening would change its lifecycle) |
| `timer-service` | `container.listen(timerServiceProvider)`, attached at the same moment |
| `ui` | Every 250 ms: route, Pre-Run visible (disabled Pause + Cancel), enabled `Start`, `Ready` label |
| `sound` | Sound recorder calls |
| `frame` | Pumps longer than 50 ms |

Checkpoints at T0-2 s, T0-0.5 s, T0+0.5 s, T0+2 s and T0+3 s, one line each:
`BUG041-R1 CHECKPOINT run=<id> t=<ms> persisted.status=.. persisted.actualStart=.. vm.status=.. vm.remaining=.. ui.route=.. ui.preRun=.. ui.start=.. ui.ready=.. pending=.. timerService=..`
(at each checkpoint also read the group once through the repository `getById`).

Print `BUG041-R1 TRACE run=<id> t=<ms> src=<src> data=<...>` lines and the
checkpoints with `print` only after the observation window ends.

### 6.4 R1.0 - clock probe (gate for everything else)

Fail with `fail('BUG041-R1 INVALID: R1.0 <check> <values>')` if any check fails:
- `WidgetsBinding.instance is LiveTestWidgetsFlutterBinding`;
- `|binding.clock.now() - DateTime.now()| < 50 ms`;
- a `Timer(300 ms)` created in the test fires after 300-1000 ms of `Stopwatch` time;
- `pump(16 ms)` takes at least 16 ms of real time;
- a `Timer.periodic(1 s)` inside a mounted widget fires 3 times within 2.9-3.6 s.
Print `BUG041-R1 PROBE ...` with the measured values.

### 6.5 R1-A - app opened inside the Pre-Run window (5 runs)

Preconditions: T0 = first whole second at least 6 s after test start;
`noticeMinutes: 5`, so the window is already open at mount, as when the owner
scheduled the group less than 5 minutes ahead (spec L1571: app open during the
pre-alert window -> Run Mode opens in Pre-Run); the app starts at `/tasks` and
the coordinator/auto-starter open Run Mode by themselves.

Steps: seed -> mount -> `runUntil(T0 + 3 s)` -> `tester.takeException()` ->
evaluate -> print -> pass/fail -> teardown.

Expected chain if H1 holds (to be measured, not forced):

| Step | Signal |
|---|---|
| E1 | Coordinator handles the open window (`noticeSentAt` write) and emits openTimer |
| E2 | Navigation to `/timer/<id>` without any test navigation |
| E3 | `Timer load group=<id> result=loaded status=scheduled`; Pre-Run visible |
| E4 | At T0-delta (0 < delta < 1 s): `scheduledAutoStartGroupId changed prev=null next=<id>` and `Auto-start attempt` |
| E5 | `Auto-start abort (not due) ... now=<before T0>`; pending id back to null |
| E6 | `start-timer-fired ... now=<T0 or later>`; persisted group `running`, `actualStartTime == T0` |
| E7 | Pending id set to `<id>` again with no new `Auto-start attempt` |
| E8 | No `Auto-start startFromAutoStart`; ViewModel stays `idle` until T0+3 s |

Validity (any failure -> INVALID):
- V1: quick clock check at test start (binding type + clock difference < 50 ms).
- V2: `/timer/<id>` reached without test navigation and Pre-Run visible at least
  2 s before T0.
- V3: no persisted emission shows `running` before T0; production-logged `now=`
  values never go backwards; coordinator `start-timer-fired now=` is at or after T0.
- V4: no pump longer than 250 ms between T0-2 s and T0+3 s.
- V5: every trace entry belongs to this run's group id.

Interleaving classification (always printed):
- `H1`: E4-E8 in order.
- `ALT-due`: the screen itself saves `running` with `actualStartTime > T0` (known
  deviation, R2b territory). Recorded, not a reproduction.
- `ALT-stale`: no `Auto-start attempt` before T0 (possible by code reading if a
  group emission lands in the last second, `timer_screen.dart:1034-1060`).
- `OTHER`: any other sequence.

Spec checks (only meaningful when valid; evaluate all and report together;
sources: specs L1575-1581 and L1655):
- S1: ViewModel `pomodoroRunning` no later than T0+2 s, without user action.
- S2: exactly one start.
- S3: persisted group `running`, `actualStartTime == T0`,
  `theoreticalEndTime == T0 + total`.
- S4: at T0+3 s, remaining = 25:00 - (now - T0) within 1 s.
- S5: at T0+2 s, no enabled `Start` button and no `Ready` label.

Outcome protocol (mandatory, the runner depends on it):
1. `final exc = tester.takeException();`
2. `print` exactly one RESULT line, single tokens, no spaces inside values:
   `BUG041-R1 RESULT run=A<n> validity=<VALID|INVALID:Vx> interleaving=<H1|ALT-due|ALT-stale|OTHER> spec=<PASS|FAIL[S1,S2,...]> exception=<none|RuntimeType> delta_ms=<int|na> latency_ms=<int|na>`
   (`delta_ms` = T0 minus the first `Auto-start attempt` before T0;
   `latency_ms` = abort log time minus attempt log time).
3. Then exactly one of:
   - `exc != null` -> `fail('BUG041-R1 UNEXPECTED-EXCEPTION: <type>')`
   - invalid -> `fail('BUG041-R1 INVALID: <Vx> <detail>')`
   - spec failed -> `fail('BUG041-R1 SPEC-FAIL: <S list> <detail>')`
   - otherwise the test passes.
- Use `print` for RESULT/TRACE/CHECKPOINT/PROBE. Never `expect` for V/S checks
  (its message would not carry the prefix the runner needs).

### 6.6 R1-B - app open before the window (1 run)

Same as R1-A except:
- `noticeMinutes: 1` and T0 = first whole second at least 66 s after test start
  (the window opens about 6 s after mount);
- the coordinator must schedule and fire the pre-alert itself
  (`schedule-prealert-timer`, `prealert-timer-fired`) and the app must open Pre-Run
  by itself at about T0-60 s;
- V2 also requires Pre-Run visible at least 50 s before T0, opened after
  `prealert-timer-fired`;
- RESULT uses `run=B1`.

### 6.7 Prediction (not an assertion)

Code reading predicts H1 with S1, S2, S4 and S5 failing and S3 passing. Record
what actually happens.

## 7. Execution - one command

1. Write the test file following section 6.
2. From the repo root, run the runner verbatim from this handoff (macOS
   `/bin/bash` 3.2; no file is created outside `logs/`):

```bash
/bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' docs/bugs/validation_bug041_2026_10_20/codex_handoff.md); echo "RUNNER_EXIT=$?"
```

Runner exit codes:
- `1`: sequence completed; the real full suite is FAIL with only the expected
  R1 SPEC-FAIL failures. This is the expected outcome and must never be reported
  as PASS.
- `2`: stopped (the reason is in the summary log). Do not continue manually.
- `0`: sequence completed with the full suite PASS (not expected: a spec PASS in
  R1-A stops the runner earlier).

| Stage | What runs | Wall-clock cap | Continues only if |
|---|---|---|---|
| precheck | branch, HEAD `1561ead`, test file present, explicit timeouts, only whitelisted untracked paths, no tracked change | - | all true |
| analyze | `flutter analyze` | 600 s | exit 0 |
| existing | all tracked `test/*_test.dart` (the new untracked file is excluded) | 1200 s | 219 tests, all PASS |
| r1.0 | `--plain-name 'BUG041 R1.0'` | 300 s | 1 test, PASS |
| r1a | `--plain-name 'BUG041 R1-A run '` | 600 s | 5 tests; no INFRA/INVALID/skip; one RESULT per test; no OTHER; at most 1 non-H1; identical H1 signature; not all spec PASS |
| r1b | `--plain-name 'BUG041 R1-B' --dart-define=BUG041_LONG=true` | 600 s | 1 test; not skipped; valid; H1; same signature as R1-A |
| full | `flutter test --concurrency=1` (serial, so the live-clock tests run unloaded) | 2400 s | 219 existing PASS; failures only R1 SPEC-FAIL; reported as `SUITE_FAIL` |

Each stage writes `logs/<date>_<id>_<hash>_macos_debug.log` (human output,
including `FLUTTER_EXIT_CODE=`) and, for test stages, a JSON reporter file
`logs/<date>_<id>_json_<hash>_macos_debug.log`. All verdicts go to
`logs/<date>_bug041_summary_<hash>_macos_debug.log`.

Verified by Claude on 2026-10-20 without touching project files: `run()` returns
the real exit code (0, 1 and 79 tested, argument quoting preserved); the
wall-clock cap returns 142 and otherwise passes the exit code through; the gate
gave the expected verdict in 26 synthetic cases and on real live-binding output
(PASS, SPEC_FAIL, timeout -> INFRA, skip); the gate also requires the Flutter exit
code to match the results (`all_pass`: exit 0; `repro` and `full`: exit 1 if and
only if a test failed), verified in 6 inconsistent cases -> INFRA with the 26
previous verdicts unchanged; the whole runner was dry-run in a temporary clone
with a stub `flutter` in 10 scenarios (expected path -> exit 1 `SUITE_FAIL`;
invalid, spec pass, R1.0 failure, count mismatch, R1-B not enabled, no tests
matched, exit code inconsistent with results (2 cases), tracked change -> exit 2
at the right stage).

### Runner (executed verbatim from this file - do not copy or edit)

```bash
# >>> BUG041 R1 RUNNER
# Runs with macOS /bin/bash 3.2. Execute verbatim from codex_handoff.md (see section 7).
set -u -o pipefail
ROOT=$(git rev-parse --show-toplevel) || exit 2
cd "$ROOT" || exit 2
F=docs/bugs/validation_bug041_2026_10_20
T=test/presentation/timer_screen_local_scheduled_autostart_test.dart
EXPECTED_BRANCH=fix/local-scheduled-autostart
EXPECTED_HEAD=1561ead
H=$(git rev-parse --short=7 HEAD)
D=$(date +%F)
L="$F/logs"
# Attempt 2+ (approved 2026-10-22): BUG041_ATTEMPT is mandatory, an integer >= 2,
# and tags every output as _a<N>; earlier evidence is never overwritten.
ATTEMPT=${BUG041_ATTEMPT:-}
case "$ATTEMPT" in
  [2-9] | [1-9][0-9]*) ;;
  *) echo "SEQUENCE=STOPPED stage=precheck reason=BUG041_ATTEMPT-missing-or-invalid:'$ATTEMPT'"; exit 2 ;;
esac
case "$ATTEMPT" in *[!0-9]*) echo "SEQUENCE=STOPPED stage=precheck reason=BUG041_ATTEMPT-missing-or-invalid:'$ATTEMPT'"; exit 2 ;; esac
SUFFIX="_a$ATTEMPT"
SUMMARY="$L/${D}_bug041_summary${SUFFIX}_${H}_macos_debug.log"
GATE_OUT=''

[ -d "$L" ] || { echo "SEQUENCE=STOPPED stage=precheck reason=missing-logs-dir"; exit 2; }
# Collision check of every output file of this attempt, before any write.
for out in summary analyze existing existing_json r10 r10_json r1a r1a_json r1b r1b_json full full_json; do
  target="${D}_bug041_${out}${SUFFIX}_${H}_macos_debug.log"
  [ ! -e "$L/$target" ] || { echo "SEQUENCE=STOPPED stage=precheck reason=output-exists:$target"; exit 2; }
done

note() { printf '%s %s\n' "$(date '+%T')" "$*" | tee -a "$SUMMARY"; }
stop() { note "SEQUENCE=STOPPED $*"; exit 2; }

# limit <seconds> <cmd...>: hard wall-clock cap; the command exits 142 if exceeded.
limit() {
  local seconds="$1"; shift
  perl -e '$s = shift @ARGV; alarm $s; exec @ARGV or die "exec failed: $!\n"' "$seconds" "$@"
}

# run <log-id> <cmd...>: tees output to the normative log and returns the
# command's real exit code (tee never masks it).
run() {
  local id="$1"; shift
  local log="$L/${D}_${id}${SUFFIX}_${H}_macos_debug.log"
  { printf '### started: %s\n### cmd:' "$(date '+%F %T')"; printf ' %q' "$@"; printf '\n'; } > "$log"
  "$@" 2>&1 | tee -a "$log"
  local rc="${PIPESTATUS[0]}"
  printf '\nFLUTTER_EXIT_CODE=%s\n' "$rc" | tee -a "$log"
  return "$rc"
}

# gate <stage> <mode> <json> <flutter-rc> <expected-count> [ref-signature]
# Exit 0 = continue, 2 = stop (unexpected/invalid/infra), 3 = stop (spec passed).
gate() { python3 -I - "$@" <<'PY'
import json, re, sys

stage, mode, path = sys.argv[1], sys.argv[2], sys.argv[3]
rc, expected = int(sys.argv[4]), int(sys.argv[5])
ref_sig = sys.argv[6] if len(sys.argv) > 6 else ''
TFILE = 'test/presentation/timer_screen_local_scheduled_autostart_test.dart'
BASELINE = 219
RESULT_RE = re.compile(
    r'BUG041-R1 RESULT run=(\S+) validity=(\S+) interleaving=(\S+) spec=(\S+) exception=(\S+)')
GENERIC = 'Test failed. See exception logs above.'
THROWN_RE = re.compile(r'The following (\S+) (?:object )?was thrown[^\n]*:\n([^\n]*)')


def finish(verdict, code, **info):
    parts = ['STAGE=' + stage, 'VERDICT=' + verdict, 'flutter_rc=%d' % rc]
    parts += ['%s=%s' % (k, v) for k, v in info.items()]
    print(' '.join(parts))
    sys.exit(code)


if rc not in (0, 1):
    finish('INFRA', 2, reason='flutter-exit-code-not-0-or-1')

suites, names, suite_of, done, errors, prints = {}, {}, {}, {}, {}, {}
try:
    with open(path, encoding='utf-8') as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw.startswith('{'):
                continue
            ev = json.loads(raw)
            kind = ev.get('type')
            if kind == 'suite':
                suites[ev['suite']['id']] = ev['suite'].get('path') or ''
            elif kind == 'testStart':
                names[ev['test']['id']] = ev['test']['name']
                suite_of[ev['test']['id']] = ev['test'].get('suiteID')
            elif kind == 'testDone':
                done[ev['testID']] = ev
            elif kind == 'error':
                errors.setdefault(ev['testID'], []).append(ev.get('error') or '')
            elif kind == 'print':
                prints.setdefault(ev['testID'], []).append(ev.get('message') or '')
except (OSError, ValueError, KeyError) as exc:
    finish('INFRA', 2, reason='json-unreadable-' + type(exc).__name__)

if not done:
    finish('INFRA', 2, reason='no-test-results')
if any(tid not in done for tid in names):
    finish('INFRA', 2, reason='test-started-but-not-finished')
if any(d.get('hidden') and d.get('result') != 'success' for d in done.values()):
    finish('INFRA', 2, reason='load-setup-or-teardown-failure')

rows = []
for tid, d in sorted(done.items()):
    if d.get('hidden'):
        continue
    errs = errors.get(tid, [])
    text = '\n'.join(prints.get(tid, []))
    # The live binding dumps the same exception twice (when caught and at test
    # end), so require exactly one distinct thrown object: our own TestFailure.
    thrown = set(THROWN_RE.findall(text))
    own = [t for t in thrown if t[0] == 'TestFailure' and t[1].startswith('BUG041-R1 ')]
    single_own_failure = (
        d.get('result') in ('failure', 'error') and len(errs) == 1
        and errs[0].startswith(GENERIC) and 'Multiple exceptions' not in text
        and len(thrown) == 1 and len(own) == 1)
    if d.get('skipped'):
        cls = 'SKIPPED'
    elif d.get('result') == 'success' and not errs:
        cls = 'PASS'
    elif single_own_failure and own[0][1].startswith('BUG041-R1 SPEC-FAIL'):
        cls = 'SPEC_FAIL'
    elif single_own_failure and own[0][1].startswith('BUG041-R1 INVALID'):
        cls = 'INVALID'
    else:
        cls = 'INFRA'
    mine = suites.get(suite_of.get(tid), '').endswith(TFILE)
    found = [m.groups() for m in (RESULT_RE.search(p) for p in prints.get(tid, [])) if m]
    rows.append((names.get(tid, '?'), mine, cls, found))

counts = {}
for row in rows:
    counts[row[2]] = counts.get(row[2], 0) + 1
detail = ','.join('%s:%d' % (k, v) for k, v in sorted(counts.items()))


def first_bad(candidates, classes=None):
    for name, _, cls, _ in candidates:
        if (cls in classes) if classes else (cls != 'PASS'):
            return repr(name)
    return '-'


if mode == 'all_pass':
    if any(r[2] != 'PASS' for r in rows):
        finish('UNEXPECTED_FAILURE', 2, tests=len(rows), detail=detail, first=first_bad(rows))
    if rc != 0:
        finish('INFRA', 2, reason='exit-code-inconsistent-with-results', tests=len(rows))
    if len(rows) != expected:
        finish('COUNT_MISMATCH', 2, tests=len(rows), expected=expected)
    finish('PASS', 0, tests=len(rows))

if mode == 'repro':
    if len(rows) != expected or not all(r[1] for r in rows):
        finish('COUNT_MISMATCH', 2, tests=len(rows), expected=expected)
    if any(r[2] in ('INFRA', 'SKIPPED') for r in rows):
        finish('INFRA', 2, detail=detail, first=first_bad(rows, ('INFRA', 'SKIPPED')))
    if any(r[2] == 'INVALID' for r in rows):
        for name, _, cls, found in rows:
            if cls == 'INVALID':
                print('INVALID_RUN %s %s' % (repr(name), ' '.join(found[0][:2]) if found else 'no-RESULT'))
        finish('INVALID', 2, detail=detail)
    parsed = []
    for name, _, cls, found in rows:
        if len(found) != 1:
            finish('INFRA', 2, reason='missing-or-duplicate-RESULT', test=repr(name))
        run, validity, inter, spec, exc = found[0]
        if exc != 'none':
            finish('INFRA', 2, reason='unexpected-exception-' + exc, test=repr(name))
        if validity != 'VALID' or (cls == 'PASS') != (spec == 'PASS'):
            finish('INFRA', 2, reason='RESULT-inconsistent-with-outcome', test=repr(name))
        parsed.append((run, inter, spec))
    print('RUNS ' + ' '.join('%s:%s:%s' % p for p in parsed))
    failed = sum(1 for r in rows if r[2] != 'PASS')
    if (rc == 1) != (failed > 0):
        finish('INFRA', 2, reason='exit-code-inconsistent-with-results', failed=failed)
    inters = [p[1] for p in parsed]
    non_h1 = sum(1 for i in inters if i != 'H1')
    h1_sigs = sorted({p[2] for p in parsed if p[1] == 'H1'})
    if 'OTHER' in inters:
        finish('UNSTABLE', 2, reason='OTHER-interleaving', detail=detail)
    if all(p[2] == 'PASS' for p in parsed):
        finish('SPEC_PASS', 3, reason='auto-start-worked-H1-not-reproduced')
    if expected > 1 and non_h1 > 1:
        finish('UNSTABLE', 2, reason='more-than-one-non-H1-run', non_h1=non_h1)
    if expected == 1 and non_h1 == 1:
        finish('NON_H1_REVIEW', 2, reason='single-run-not-H1', interleaving=inters[0])
    if len(h1_sigs) > 1:
        finish('UNSTABLE', 2, reason='H1-signatures-differ', sigs='|'.join(h1_sigs))
    if ref_sig and h1_sigs[0] != ref_sig:
        finish('DIVERGENT', 2, reason='signature-differs-from-R1-A', sig=h1_sigs[0], ref=ref_sig)
    print('H1_SIGNATURE=' + h1_sigs[0])
    finish('EXPECTED_SPEC_FAIL', 0, tests=len(rows), detail=detail, non_h1=non_h1)

if mode == 'full':
    others = [r for r in rows if not r[1]]
    mine = [r for r in rows if r[1]]
    if any(r[2] != 'PASS' for r in others):
        finish('UNEXPECTED_FAILURE', 2, detail=detail, first=first_bad(others))
    if len(others) != BASELINE:
        finish('COUNT_MISMATCH', 2, existing=len(others), expected=BASELINE)
    if len(mine) != expected or any(r[2] in ('INFRA', 'INVALID') for r in mine):
        finish('UNEXPECTED_FAILURE', 2, r1_tests=len(mine), detail=detail)
    for name, _, cls, found in mine:
        for run, validity, inter, spec, exc in found:
            if exc != 'none':
                finish('UNEXPECTED_FAILURE', 2, reason='unexpected-exception-' + exc, test=repr(name))
            print('RUNS_FULL %s:%s:%s:%s' % (run, validity, inter, spec))
    spec_fail = sum(1 for r in mine if r[2] == 'SPEC_FAIL')
    if (rc == 1) != (spec_fail > 0):
        finish('INFRA', 2, reason='exit-code-inconsistent-with-results')
    finish('SUITE_' + ('FAIL' if spec_fail else 'PASS'), 0, existing_pass=len(others),
           r1_spec_fail=spec_fail, r1_pass=sum(1 for r in mine if r[2] == 'PASS'),
           r1_skipped=sum(1 for r in mine if r[2] == 'SKIPPED'))

finish('INFRA', 2, reason='unknown-mode')
PY
}

check() {
  local grc
  GATE_OUT=$(gate "$@"); grc=$?
  printf '%s\n' "$GATE_OUT" | while IFS= read -r line; do note "$line"; done
  return "$grc"
}

# --- Stage 0: precheck -------------------------------------------------------
note "SEQUENCE=START runner=bug041-r1 attempt=$ATTEMPT head=$H date=$D"
note "ENV $(flutter --version 2>&1 | head -n 1)"
[ "$(git branch --show-current)" = "$EXPECTED_BRANCH" ] || stop "stage=precheck reason=wrong-branch"
[ "$H" = "$EXPECTED_HEAD" ] || stop "stage=precheck reason=unexpected-head-$H"
[ -f "$T" ] || stop "stage=precheck reason=missing-test-file"
[ "$(grep -c 'timeout: const Timeout(' "$T")" -ge 3 ] || stop "stage=precheck reason=explicit-timeouts-missing"
! grep -q 'Timeout.none' "$T" || stop "stage=precheck reason=Timeout.none-present"
UNEXPECTED=$(git status --porcelain --untracked-files=normal | grep -vxF \
  -e '?? .tmp.driveupload/' -e '?? FOCUSINTERVAL-notas-todo.txt' -e '?? chat-claude.md' \
  -e '?? chatgpt-chat.md' -e '?? docs/features/feature_2026_10_15_v1-store-release/respuesta-claude.md' \
  -e "?? $F/" -e "?? $T")
[ -z "$UNEXPECTED" ] || stop "stage=precheck reason=unexpected-worktree-changes:$(printf '%s' "$UNEXPECTED" | tr '\n' ';')"
note "STAGE=precheck VERDICT=PASS"

# --- Stage 1: analyze --------------------------------------------------------
run bug041_analyze limit 600 flutter analyze; rc=$?
[ "$rc" -eq 0 ] || stop "stage=analyze VERDICT=FAIL flutter_rc=$rc"
note "STAGE=analyze VERDICT=PASS flutter_rc=0"

# --- Stage 2: existing suite (tracked tests only; the new R1 file is excluded)
EXISTING=()
while IFS= read -r f; do EXISTING+=("$f"); done < <(git ls-files -- 'test/*_test.dart')
[ "${#EXISTING[@]}" -gt 0 ] || stop "stage=existing reason=no-tracked-test-files"
J="$L/${D}_bug041_existing_json${SUFFIX}_${H}_macos_debug.log"
run bug041_existing limit 1200 flutter test "${EXISTING[@]}" --reporter expanded --file-reporter "json:$J"; rc=$?
check existing all_pass "$J" "$rc" 219 || stop "stage=existing"

# --- Stage 3: R1.0 clock probe -----------------------------------------------
J="$L/${D}_bug041_r10_json${SUFFIX}_${H}_macos_debug.log"
run bug041_r10 limit 300 flutter test "$T" --plain-name 'BUG041 R1.0' --reporter expanded --file-reporter "json:$J"; rc=$?
check r1.0 all_pass "$J" "$rc" 1 || stop "stage=r1.0"

# --- Stage 4: R1-A x5 --------------------------------------------------------
J="$L/${D}_bug041_r1a_json${SUFFIX}_${H}_macos_debug.log"
run bug041_r1a limit 600 flutter test "$T" --plain-name 'BUG041 R1-A run ' --reporter expanded --file-reporter "json:$J"; rc=$?
check r1a repro "$J" "$rc" 5 || stop "stage=r1a"
SIG=$(printf '%s\n' "$GATE_OUT" | sed -n 's/^H1_SIGNATURE=//p')
[ -n "$SIG" ] || stop "stage=r1a reason=no-H1-signature"

# --- Stage 5: R1-B (gated by --dart-define) ----------------------------------
J="$L/${D}_bug041_r1b_json${SUFFIX}_${H}_macos_debug.log"
run bug041_r1b limit 600 flutter test "$T" --plain-name 'BUG041 R1-B' --dart-define=BUG041_LONG=true --reporter expanded --file-reporter "json:$J"; rc=$?
check r1b repro "$J" "$rc" 1 "$SIG" || stop "stage=r1b"

# --- Stage 6: real full suite, serial so live-clock tests run unloaded --------
J="$L/${D}_bug041_full_json${SUFFIX}_${H}_macos_debug.log"
run bug041_full limit 2400 flutter test --concurrency=1 --reporter expanded --file-reporter "json:$J"; rc=$?
check full full "$J" "$rc" 7 || stop "stage=full"
note "SEQUENCE=COMPLETED suite_status=$([ "$rc" -eq 0 ] && echo PASS || echo FAIL) flutter_rc=$rc"
note "NOTE suite_status=FAIL with only R1 SPEC-FAIL failures is the expected reproduction outcome; it is not a PASS."
exit "$rc"
# <<< BUG041 R1 RUNNER
```

## 8. Stop conditions

The runner stops by itself on every condition in the table above. In addition,
stop and report without changing anything if:
- the app cannot be mounted without touching `lib/`, even with the minimal shell;
- any synthetic state would be needed (manual state reconstruction, editing
  `theoreticalEndTime`, durations the editor rejects);
- a stage ends with exit 142 (wall-clock cap): report `pgrep -fl flutter_tester`
  output; do not kill processes you did not start;
- anything requires a change outside the authorized files.

## 9. Delivery to Claude

- `RUNNER_EXIT` and the full summary log.
- Per-run table: run, delta_ms, latency_ms, interleaving, validity, failed S checks.
- One complete H1 trace (and the trace of every non-H1 or invalid run).
- R1-B result and its comparison with R1-A.
- Results in three separate groups: (1) existing tests that pass; (2) new tests
  that fail on purpose against the spec; (3) unexpected or unstable failures.
- Deviations (shell fallback, doubles used) and the scheduling-flow lines used to
  build the group.
- `git status --short` and `git diff --stat` (tracked diff must be empty).
- Plan (section 5 results, section 8, section 10) and checklist updated in place.

## 10. Commit order

- None. Commits are not authorized. After Claude's evidence review, the owner
  decides whether the reproduction test is committed and what comes next
  (R1-C, R2 or R3).

## 11. Attempt 2 (owner approval 2026-10-22)

Approved scope: apply only the test repair in 11.1 and run the full runner once
with `BUG041_ATTEMPT=2`. Nothing else (no other tests, no R1-C/R2/R3, no `lib/`,
no configuration, no `.git/`, no commits, push, PR or merge).

### 11.0 Attempt 1 outcome and cause (verified by Claude)

- Attempt 1 (2026-10-22 06:45-06:47, original runner): `RUNNER_EXIT=2`,
  `SEQUENCE=STOPPED stage=r1a`, `VERDICT=INFRA detail=INFRA:5`. analyze PASS,
  existing 219/219 PASS, R1.0 PASS. No RESULT line, no reproduction data.
- Cause, harness only: the five observation `container.listen` calls were added
  to a `List<ProviderSubscription<dynamic>>`, so Dart inferred `dynamic` for the
  listener values. `.name` is an enum extension getter and is not found by a
  dynamic call, hence `NoSuchMethodError` (`ScheduledGroupActionType`,
  `TaskRunStatus`, `PomodoroStatus`; `PomodoroPhase` was also exposed). With
  `avoid_dynamic_calls` enabled only in a temporary clone: 36 dynamic accesses,
  all inside those five callbacks (original lines 206-298), none elsewhere. The
  repo lint configuration does not include that rule, so `flutter analyze` passed.
- A2-A5 binding assertions (`!inTest`, `!_expectingFrame`,
  `_pendingFrame == null`) were consequences: the first error arrived
  asynchronously, flutter_test completed A1 while its body kept pumping, and
  `postTest` failed on `!_expectingFrame` (`binding.dart:2780`) before resetting
  `_inTest`, so the next test failed on `!inTest` (`binding.dart:2756`).
- No independent lifecycle fix is required for result validity: runs hit by an
  asynchronous exception print no RESULT, the gate classifies them INFRA and
  stops, and V5 rejects traces from other runs. Known limitation: if an
  asynchronous exception happens again, only the first error in the log is
  diagnostic.

### 11.1 Test repair (Codex applies this exact diff)

Scope: explicit type arguments on the five observation `container.listen` calls,
the subscription list element type (`Object?`, so an untyped `listen` either
infers the exact provider type or fails analysis, never `dynamic`) and one
import. No change to observation logic, timing, mounting, execution paths,
V1-V5, S1-S5, the RESULT/`fail` protocol, test names or timeouts.

- Base file sha256 must start with `75f52f6693ec6575`.
- Result sha256 must start with `47b96386eee004d7`; the result is already
  `dart format` clean.
- Verified by Claude in a temporary clone: `git apply --check` clean; result
  sha256 as above; `dart format --set-exit-if-changed` no change; `flutter
  analyze` no issues with the repo configuration; with `avoid_dynamic_calls`
  added in the clone only, 0 of the 36 dynamic accesses remain.

<!-- BUG041-R1 ATTEMPT2 TEST DIFF -->
```diff
diff --git a/test/presentation/timer_screen_local_scheduled_autostart_test.dart b/test/presentation/timer_screen_local_scheduled_autostart_test.dart
--- a/test/presentation/timer_screen_local_scheduled_autostart_test.dart
+++ b/test/presentation/timer_screen_local_scheduled_autostart_test.dart
@@ -19,6 +19,8 @@ import 'package:focus_interval/data/services/device_info_service.dart';
 import 'package:focus_interval/data/services/firebase_auth_service.dart';
 import 'package:focus_interval/data/services/firestore_service.dart';
 import 'package:focus_interval/data/services/sound_service.dart';
+import 'package:focus_interval/data/services/timer_service.dart'
+    show TimerRuntimeState;
 import 'package:focus_interval/domain/pomodoro_machine.dart';
 import 'package:focus_interval/presentation/providers.dart';
 import 'package:focus_interval/presentation/screens/timer_screen.dart';
@@ -158,7 +160,9 @@ class _Observation {
   final List<_Trace> trace = [];
   final List<_Pump> pumps = [];
   final List<_Checkpoint> checkpoints = [];
-  final List<ProviderSubscription<dynamic>> subscriptions = [];
+  // Object? (not dynamic): an untyped listen() call below must fail analysis
+  // instead of handing dynamic values to the observers at run time.
+  final List<ProviderSubscription<Object?>> subscriptions = [];
   final List<({DateTime at, TaskRunGroup group})> persisted = [];
   late final ProviderContainer container;
   DateTime? firstPreRun;
@@ -199,7 +203,9 @@ class _Observation {
 
   void attachActionObservers() {
     subscriptions.add(
-      container.listen(scheduledGroupCoordinatorProvider, (_, action) {
+      container.listen<
+        ScheduledGroupAction?
+      >(scheduledGroupCoordinatorProvider, (_, action) {
         if (action == null) return;
         record(
           'coordinator-action',
@@ -209,7 +215,10 @@ class _Observation {
       }),
     );
     subscriptions.add(
-      container.listen(scheduledAutoStartGroupIdProvider, (previous, next) {
+      container.listen<String?>(scheduledAutoStartGroupIdProvider, (
+        previous,
+        next,
+      ) {
         record(
           'pending',
           'previous=$previous value=$next',
@@ -225,7 +234,9 @@ class _Observation {
 
   void attachPersistedObserver() {
     subscriptions.add(
-      container.listen(taskRunGroupStreamProvider, (_, groups) {
+      container.listen<
+        AsyncValue<List<TaskRunGroup>>
+      >(taskRunGroupStreamProvider, (_, groups) {
         for (final group in groups.value ?? const <TaskRunGroup>[]) {
           if (group.id != groupId) continue;
           persisted.add((at: DateTime.now(), group: group));
@@ -276,7 +287,10 @@ class _Observation {
     if (!vmAttached && find.byType(TimerScreen).evaluate().isNotEmpty) {
       vmAttached = true;
       subscriptions.add(
-        container.listen(pomodoroViewModelProvider, (previous, next) {
+        container.listen<PomodoroState>(pomodoroViewModelProvider, (
+          previous,
+          next,
+        ) {
           if (next.status == PomodoroStatus.pomodoroRunning) {
             firstRunning ??= DateTime.now();
             if (previous?.status != PomodoroStatus.pomodoroRunning) starts += 1;
@@ -289,7 +303,7 @@ class _Observation {
         }, fireImmediately: true),
       );
       subscriptions.add(
-        container.listen(timerServiceProvider, (_, next) {
+        container.listen<TimerRuntimeState>(timerServiceProvider, (_, next) {
           record(
             'timer-service',
             'group=${next.groupId} status=${next.status.name} '
```

### 11.2 Runner protection (already applied by Claude in the section 7 block)

- `BUG041_ATTEMPT` is mandatory and must be an integer >= 2 (attempt 1 is
  consumed). Missing or invalid: the runner stops before writing anything.
- Every output of attempt N is named with `_a<N>` inside the fix-id, keeping the
  repo convention, e.g. `2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log`.
- Before any write the runner checks the 12 outputs of the attempt (summary,
  analyze, existing, existing_json, r10, r10_json, r1a, r1a_json, r1b, r1b_json,
  full, full_json) and stops if any of them exists.
- Unchanged: gate code (byte-identical to attempt 1), classification, stop
  criteria, stage order and caps.
- The section 7 command (without `BUG041_ATTEMPT`) now stops at precheck by
  design. Use 11.3.

### 11.3 Execution steps for Codex (one run)

1. Pre-checks (stop if any differs):

```bash
F=docs/bugs/validation_bug041_2026_10_20
T=test/presentation/timer_screen_local_scheduled_autostart_test.dart
git branch --show-current                     # fix/local-scheduled-autostart
git rev-parse --short HEAD                    # 1561ead
git diff --quiet && git diff --cached --quiet && echo "tracked: clean"
shasum -a 256 "$T"                            # 75f52f6693ec6575...
ls "$F/logs"                                  # exactly the 8 files of 11.4
(cd "$F/logs" && shasum -a 256 -c <<'SUMS'
ef069be9afbdebd92382f78bbc1dbe9ebdedc46b43a63910e4435703f2a1e756  2026-10-22_bug041_analyze_1561ead_macos_debug.log
71d2ffc747293d71afd5715edd564e1bd171038572d106976c47b191ef47e5fc  2026-10-22_bug041_existing_1561ead_macos_debug.log
429e40af8f8b3b7e52d1dc1adb04915742776568d2ce510c76c3154ee27acfb1  2026-10-22_bug041_existing_json_1561ead_macos_debug.log
009b197eef62c0f1a97517414f033b78d5c98ed6e43a2c564f902946e4850e02  2026-10-22_bug041_r10_1561ead_macos_debug.log
8aeddea26cc7b31253a750ac8f5f5d31980220b7dad45d378ae3b259a00759de  2026-10-22_bug041_r10_json_1561ead_macos_debug.log
3f773a1caa74cae009ee0f75dbfa89b63490ca1365ab414984a4913f86738d85  2026-10-22_bug041_r1a_1561ead_macos_debug.log
c8bb4793b4c105f91de771d30971c4008a1c363e1e0aeda1e781b8333970f2f4  2026-10-22_bug041_r1a_json_1561ead_macos_debug.log
30ae3f395082813a036300962b4410182311a27f948a07828ac7f339e90a2ee5  2026-10-22_bug041_summary_1561ead_macos_debug.log
SUMS
)
```

2. Apply the test repair (extracted verbatim from 11.1), then check it:

```bash
extract() { awk '/^<!-- BUG041-R1 ATTEMPT2 TEST DIFF -->$/{f=1;next} f&&/^```diff$/{g=1;next} g&&/^```$/{exit} g{print}' "$F/codex_handoff.md"; }
extract | git apply --check && extract | git apply
dart format "$T"                              # expect: 0 changed
shasum -a 256 "$T"                            # 47b96386eee004d7...
git diff --quiet && echo "tracked: clean"     # the test file stays untracked
```

3. Run the full runner once:

```bash
BUG041_ATTEMPT=2 /bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' "$F/codex_handoff.md"); echo "RUNNER_EXIT=$?"
```

4. Post-checks: repeat the `shasum -a 256 -c` block of step 1 (all 8 must be
   `OK`), list the new `_a2_` files, and run `git status --short` and
   `git diff --stat`.

### 11.4 Attempt-1 evidence (must stay byte-identical)

The 8 files and sha256 values listed in step 1 of 11.3. Never move, rename,
edit or delete them.

### 11.5 Stop conditions (in addition to section 8)

- Any pre-check mismatch (branch, HEAD, tracked changes, base sha256, logs
  listing or checksums).
- `git apply --check` fails, or the result sha256 is not `47b96386eee004d7...`.
- Any runner stop (`RUNNER_EXIT=2`) or unexpected behaviour: do not rerun, do not
  edit the test, report.
- Any attempt-1 checksum changes after the run.

### 11.6 Recording and delivery

- Plan: add an "Intento 2" results block (same table format) after the attempt-1
  block; do not edit or delete attempt-1 text. Checklist: mark only items
  evidenced by attempt 2 and tag them `(intento 2)`; keep attempt-1 notes.
- Deliver as in section 9, plus: base and result sha256 of the test file, the
  `shasum -c` output before and after the run, `RUNNER_EXIT`, the full
  `summary_a2` log, and the list of `_a2_` files.

## 12. Attempt 3 (owner approval 2026-10-22)

Approved scope: Codex replaces only the V3 block of `invalidReason` in the test
with the diff in 12.1 and runs the full runner once with `BUG041_ATTEMPT=3`
(R1.0, R1-A, R1-B and the runner's analyze, existing-suite and full-suite
stages). Nothing else: no other test, no `lib/`, no configuration,
dependencies, specs, roadmap or `.git/`, no commits, push, PR or merge, no
production fix, no R1-C/R2/R3.

### 12.0 Why (attempt 2 and the V3 rule)

- Attempt 2 (2026-10-22 07:48-07:51): `RUNNER_EXIT=2`, stopped at r1a with
  `INVALID:2,SPEC_FAIL:3`. A1, A3 and A5 were valid H1 runs with
  `FAIL[S1,S2,S4,S5]`; A2 and A4 were `INVALID:V3`. These results stay as
  recorded and are not reclassified.
- The old V3 required production `now=` values to be non-decreasing across all
  emitters in emission order. `_handleGroupsAsync` prints a `now` taken at entry
  after several awaits (`scheduled_group_coordinator.dart:276`, `L277`,
  `L340-347`, `L702`), so a later-captured value printed by another timer
  callback can appear first. That is a valid asynchronous interleaving. In A2
  and A4 it produced 118-us and 99-us apparent steps back. The test's capture
  instants never decreased. Full analysis: plan section "Claude review of
  attempt 2 and V3".
- New V3: the test's capture instants must never decrease; every logged `now`
  must satisfy `0 <= capture - now <= 250 ms` (V4's stall bound); "no `running`
  before T0" and "`start-timer-fired` never before T0" are unchanged.

### 12.1 V3 repair (Codex applies this exact diff)

Scope: only the V3 block of `invalidReason`. No change to V1, V2, V4, V5,
S1-S5, the RESULT/`fail` protocol, classification, mounting, timing, test names
or timeouts.

- Base file sha256 must start with `47b96386eee004d7` (attempt-2 file).
- Result sha256 must start with `1d92a9b9629627c6`; the result is already
  `dart format` clean.
- Verified by Claude in a temporary clone (2026-10-22): `git apply --check`
  clean; result sha256 as above; `dart format` no change; `flutter analyze` no
  issues with the repo configuration; with `avoid_dynamic_calls` added in the
  clone only, no dynamic access. The old and new blocks, copied verbatim into a
  standalone Dart program, gave: real A2/A4 pattern old INVALID / new VALID;
  capture going backwards, `now` later than its own line and a 300-ms-old `now`
  old VALID (missed) / new INVALID; `start-timer-fired` before T0 INVALID in
  both.

<!-- BUG041-R1 ATTEMPT3 TEST DIFF -->
```diff
diff --git a/test/presentation/timer_screen_local_scheduled_autostart_test.dart b/test/presentation/timer_screen_local_scheduled_autostart_test.dart
--- a/test/presentation/timer_screen_local_scheduled_autostart_test.dart
+++ b/test/presentation/timer_screen_local_scheduled_autostart_test.dart
@@ -443,21 +443,30 @@ class _Observation {
     )) {
       return 'V3';
     }
-    DateTime? lastLoggedNow;
+    // Clock checks use each line's own capture instant, not the order of
+    // `now=` values across emitters: async code may log a `now` taken before an
+    // await after another emitter logged a later one (attempt 2, A2/A4).
+    DateTime? lastCapture;
     final nowPattern = RegExp(
       r'\bnow=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?)',
     );
     for (final event in trace) {
+      // Capture instants are taken synchronously in record order, so a
+      // decrease means the wall clock went backwards during the run.
+      if (lastCapture != null && event.at.isBefore(lastCapture)) return 'V3';
+      lastCapture = event.at;
       final match = nowPattern.firstMatch(event.data);
       if (match == null) continue;
       final loggedNow = DateTime.parse(match.group(1)!);
-      if (lastLoggedNow != null && loggedNow.isBefore(lastLoggedNow)) {
+      // A logged `now` cannot be later than its own line, nor older than the
+      // 250-ms event-loop stall bound that V4 uses.
+      final age = event.at.difference(loggedNow);
+      if (age.isNegative || age > const Duration(milliseconds: 250)) {
         return 'V3';
       }
       if (event.data.contains('start-timer-fired') && loggedNow.isBefore(t0)) {
         return 'V3';
       }
-      lastLoggedNow = loggedNow;
     }
     final from = t0.subtract(const Duration(seconds: 2));
     final to = t0.add(const Duration(seconds: 3));
```

### 12.2 Runner (unchanged)

- The section 7 runner block is not modified. `BUG041_ATTEMPT=3` names every
  output `_a3` (for example `2026-10-22_bug041_r1b_a3_1561ead_macos_debug.log`)
  and the runner stops before any write if any of the 12 `_a3` outputs exists.
- Gates, stop criteria, stage order and caps are unchanged. R1-B runs only if
  the R1-A gate passes; the full suite runs only if R1-B passes.

### 12.3 Execution steps for Codex (one run)

1. Pre-checks (stop if any differs):

```bash
F=docs/bugs/validation_bug041_2026_10_20
T=test/presentation/timer_screen_local_scheduled_autostart_test.dart
git branch --show-current                     # fix/local-scheduled-autostart
git rev-parse --short HEAD                    # 1561ead
git diff --quiet && git diff --cached --quiet && echo "tracked: clean"
shasum -a 256 "$T"                            # 47b96386eee004d7...
ls "$F/logs" | wc -l                          # 16 (the files of 12.4)
(cd "$F/logs" && shasum -a 256 -c <<'SUMS'
ef069be9afbdebd92382f78bbc1dbe9ebdedc46b43a63910e4435703f2a1e756  2026-10-22_bug041_analyze_1561ead_macos_debug.log
8944e727cd91fccb5c2d546a0bb109e602350d43c7b90e43bc0f84fa2e489cfa  2026-10-22_bug041_analyze_a2_1561ead_macos_debug.log
71d2ffc747293d71afd5715edd564e1bd171038572d106976c47b191ef47e5fc  2026-10-22_bug041_existing_1561ead_macos_debug.log
b0078f86bb2866ba51e54ae21567a2a56962a5a9f20a988ddac8ab1b8e8dd227  2026-10-22_bug041_existing_a2_1561ead_macos_debug.log
429e40af8f8b3b7e52d1dc1adb04915742776568d2ce510c76c3154ee27acfb1  2026-10-22_bug041_existing_json_1561ead_macos_debug.log
f5dc3316cd92617f62eb68146d18d5998294210ca7383a53d0dc8827887f0659  2026-10-22_bug041_existing_json_a2_1561ead_macos_debug.log
009b197eef62c0f1a97517414f033b78d5c98ed6e43a2c564f902946e4850e02  2026-10-22_bug041_r10_1561ead_macos_debug.log
23409e89bc2900e3651f5e71ac0622a39df53ac071be23a5fe06f25c223bfc72  2026-10-22_bug041_r10_a2_1561ead_macos_debug.log
8aeddea26cc7b31253a750ac8f5f5d31980220b7dad45d378ae3b259a00759de  2026-10-22_bug041_r10_json_1561ead_macos_debug.log
fdaeab3e777c228a8222a046082edf7b473faf4b0bc1197e00c66442f9a8bbe6  2026-10-22_bug041_r10_json_a2_1561ead_macos_debug.log
3f773a1caa74cae009ee0f75dbfa89b63490ca1365ab414984a4913f86738d85  2026-10-22_bug041_r1a_1561ead_macos_debug.log
02a02d8dead6791f49df39e3420c4d74e6c2e08f37ecf1314a169f81daefc020  2026-10-22_bug041_r1a_a2_1561ead_macos_debug.log
c8bb4793b4c105f91de771d30971c4008a1c363e1e0aeda1e781b8333970f2f4  2026-10-22_bug041_r1a_json_1561ead_macos_debug.log
eedd86b040750abe4cbbbf11c0350de4703f61add9b1e5347eea3b2730344df5  2026-10-22_bug041_r1a_json_a2_1561ead_macos_debug.log
30ae3f395082813a036300962b4410182311a27f948a07828ac7f339e90a2ee5  2026-10-22_bug041_summary_1561ead_macos_debug.log
a615fdf142448b0a7c30e8e5faeee379f7a1e315d5d9303293b2a162a5591284  2026-10-22_bug041_summary_a2_1561ead_macos_debug.log
SUMS
)
```

2. Apply the V3 repair (extracted verbatim from 12.1), then check it:

```bash
extract() { awk '/^<!-- BUG041-R1 ATTEMPT3 TEST DIFF -->$/{f=1;next} f&&/^```diff$/{g=1;next} g&&/^```$/{exit} g{print}' "$F/codex_handoff.md"; }
extract | git apply --check && extract | git apply
dart format "$T"                              # expect: 0 changed
shasum -a 256 "$T"                            # 1d92a9b9629627c6...
git diff --quiet && echo "tracked: clean"     # the test file stays untracked
```

3. Run the full runner once:

```bash
BUG041_ATTEMPT=3 /bin/bash <(sed -n '/^# >>> BUG041 R1 RUNNER$/,/^# <<< BUG041 R1 RUNNER$/p' "$F/codex_handoff.md"); echo "RUNNER_EXIT=$?"
```

4. Post-checks: repeat the `shasum -a 256 -c` block of step 1 (all 16 must be
   `OK`), list the new `_a3_` files, run `shasum -a 256 "$T"` (still
   `1d92a9b9629627c6...`), `git status --short` and `git diff --stat`.

### 12.4 Historical evidence (must stay byte-identical)

The 16 files and sha256 values listed in step 1 of 12.3: 8 from attempt 1 and
8 from attempt 2. Never move, rename, edit or delete them.

### 12.5 Stop conditions (in addition to section 8)

- Any pre-check mismatch (branch, HEAD, tracked changes, base sha256, log count
  or checksums).
- `git apply --check` fails, or the result sha256 is not `1d92a9b9629627c6...`.
- Any runner stop (`RUNNER_EXIT=2`) or unexpected behaviour: do not rerun, do
  not edit the test, report.
- Any historical checksum changes after the run.

### 12.6 Recording and delivery

- Plan: add an "Intento 3" results block (same table format, including B1)
  after the attempt-2 blocks; do not edit or delete attempts 1-2 or Claude's V3
  review. Checklist: mark only items evidenced by attempt 3 and tag them
  `(intento 3)`; keep the earlier notes.
- R1 acceptance is judged on attempt 3 alone (plan "Criterios de cierre").
- Deliver as in section 9, plus: base and result sha256 of the test file, the
  `shasum -c` output before and after the run, `RUNNER_EXIT`, the full
  `summary_a3` log, all RESULT lines (A1-A5 and B1), the R1-B comparison with
  R1-A, the full-suite verdict, and the list of `_a3_` files.

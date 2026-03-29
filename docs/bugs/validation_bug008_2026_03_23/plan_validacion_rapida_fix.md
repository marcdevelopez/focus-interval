# BUGLOG-008A — Validation Plan (Android)

Date: 2026-03-23
Branch: `fix/buglog-008a-android-validation`
Validation baseline commit: `4ef7f42`
Implementation commit: `c6370f4`
Bugs covered: `BUGLOG-008A` (`BUG-008` late-open overdue queue)
Target devices: Android `RMX3771` (Account Mode)

## Objetivo
Validate that late-open overdue scheduled groups are resolved immediately through the late-start overlap queue, without bypass via `Start now`, without empty completion summary artifacts, and with clean navigation into Run Mode.

## Síntoma original
When opening the app late with all planned groups already overdue, the queue did not open immediately. Users could see a false running/completion state, sometimes with empty totals (`0/0/0`), while groups remained scheduled. In that state, `Start now` could bypass overdue resolution and confirm flow could trigger noisy/double navigation.

## Root cause
Documented fix in commit `c6370f4`:
- `ScheduledGroupCoordinator` re-evaluates overdue queue after stale activeSession clear.
- Late-start conflict detection centralized in shared timing utility.
- `GroupsHubScreen` `Start now` path redirects to late-start queue on conflict.
- `LateStartOverlapQueueScreen` uses delayed fallback navigation to avoid double navigation.
- `TimerScreen` skips empty completion summary modal rendering.

## Protocolo de validación

### Scenario A — Late open with all groups overdue (exact repro)
Preconditions:
1. Android in Account Mode.
2. No active running group.
3. Three scheduled groups planned consecutively (15m each, notice 1m):
   - G1 at 06:00
   - G2 at 06:16
   - G3 at 06:32

Steps:
1. Close the app.
2. Re-open around 09:59 (all groups overdue).
3. Observe initial screen behavior.
4. Confirm `Resolve overlaps` with `Continue`.
5. Try `Start now` on the next queued scheduled group.

Expected result with fix:
- `Resolve overlaps` opens immediately on late open.
- Queue includes full chain (`overdue=3`).
- After confirm: scheduler transitions to running first group (`scheduled=2 overdue=0`).
- `Start now` for next queued group does not bypass; blocked by running-conflict modal.
- No empty completion modal (`Tasks group completed` with 0/0/0).

Reference result without fix:
- Queue does not open immediately.
- `Start now` can bypass queue and force direct start.
- Potential empty completion modal and noisy/double transition behavior.

## Comandos de ejecución

```bash
cd /Users/devcodex/development/focus_interval
mkdir -p docs/bugs/validation_bug008_2026_03_23/logs
```

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log
```

```bash
flutter run -v --release -d RMX3771 --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_release.log
```

## Log analysis — quick scan

### Bug present signals
```bash
rg -n "Tasks group completed|Scheduling conflict|overdue=2|overdue=0 activeSession=n/a.*running-open-timer" \
  docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log
```

### Fix working signals
```bash
rg -n "LateStartQueue\] overdue=3|Opening late-start overlap queue|running-open-timer|scheduled=2 overdue=0" \
  docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log
```

## Verificación local
- This cycle is validation-only (no code delta).
- Historical local gate for implementation commit `c6370f4` was already PASS at implementation time (analyze + targeted tests), and current closure relies on new Android device evidence.

## Criterios de cierre
1. Exact repro PASS on Android with queue opening immediately on late open.
2. `Start now` does not bypass overdue queue when a running group exists.
3. No empty completion summary artifact appears in run.
4. Evidence recorded in bug log + validation ledger + dev log with log path.

## Status
Closed/OK

# Codex Handoff - BUG-026 (WIP)

## Branch

- fix/bug026-owner-autostart-routing

## Reference commit

- Base HEAD: 018b6e6
- Working tree includes uncommitted local WIP changes.

## Mandatory read before continuing

1. CLAUDE.md section 3 (anti-patterns AP-1..AP-4)
2. CLAUDE.md section 4 (guardrails)
3. docs/specs.md section 10.4.8 and 10.4.8.b
4. docs/bugs/bug_log.md BUG-026 section

## Current WIP changes (already applied locally)

### 1) TimerScreen guard hardening (partial fix)

- File: lib/presentation/screens/timer_screen.dart
- Change: in VM listener, canceled navigation now requires group-id match:
  - Before: `if (group?.status == TaskRunStatus.canceled && !_cancelNavigationHandled)`
  - After: `if (group?.status == TaskRunStatus.canceled && group?.id == widget.groupId && !_cancelNavigationHandled)`
- Intent: prevent stale canceled VM state from another group forcing unexpected Groups Hub navigation.

### 2) Regression test scaffold for stale-cancel race

- File: test/presentation/timer_screen_completion_navigation_test.dart
- Added helper: DelayedTaskRunGroupRepository
- Added test:
  - "Timer ignores stale canceled vm group when displayed group id differs"
- Current problem: this focused test hangs and must be stabilized before merge.

### 3) BUG-026 narrative expanded

- File: docs/bugs/bug_log.md
- Section rewritten with detailed timeline, log correlation, and split between Root bug A and Root bug B.

## Root-cause decomposition to finish

### Root bug A (primary)

Owner Start now does not deterministically stay in Timer. There is route churn while session is still null and openTimer can re-emit.

Goal:

- Ensure one deterministic owner navigation to /timer/:groupId after Start now confirmation.
- Avoid duplicate/churned openTimer navigation while activeSession propagation is pending.

Likely fix points:

- lib/widgets/scheduled_group_auto_starter.dart
- lib/presentation/screens/task_list_screen.dart
- lib/presentation/viewmodels/scheduled_group_coordinator.dart

### Root bug B (secondary)

Mirror sees a Start CTA during runningWithoutSession hold that is non-actionable.

Goal:

- Disable/hide Start on mirror while runningWithoutSession hold is active.

Likely fix points:

- lib/presentation/screens/timer_screen.dart (\_ControlsBar gating)
- possibly vm ownership/session gating exposed via canControlSession/isMirrorMode.

## Immediate next actions

1. Stabilize the hanging stale-cancel test

- Keep only deterministic timing dependencies.
- Ensure provider lifecycle is explicit in test harness.
- Verify no unresolved async pump loops.

2. Implement root bug A deterministically

- Add strict dedupe key for owner auto-open events.
- Prevent repeated openTimer re-navigation while same group open is already in-flight/active.

3. Implement root bug B UX contract

- Mirror + runningWithoutSession hold => Start CTA not interactive.

4. Run validation commands

- flutter analyze
- flutter test test/presentation/timer_screen_completion_navigation_test.dart
- flutter test test/presentation/timer_screen_syncing_overlay_test.dart

5. Device validation

- Android owner + macOS mirror exact repro run.
- Capture logs in validation_bug026_2026_04_03/logs.

## Risks / watch-outs

1. Do not reintroduce AP-1

- Never cancel/rebind session stream from VM build path except approved attach points.

2. Do not clear missing-session hold on uncorroborated null

- Respect 10.4.8.b single-shot exit contract.

3. Avoid test-only false positives

- If route churn only exists in test harness, verify with real device logs before closure.

## Current repo state snapshot

- Modified:
  - docs/bugs/bug_log.md
  - lib/presentation/screens/timer_screen.dart
  - test/presentation/timer_screen_completion_navigation_test.dart
- Untracked unrelated:
  - docs/backend_decoupling_strategy.md

## Commit plan when ready

1. Commit A (tests + timer guard):
   - fix(bug026): scope canceled navigation to current timer group and add regression test
2. Commit B (owner auto-open deterministic):
   - fix(bug026): dedupe owner auto-open routing during start-now propagation
3. Commit C (mirror CTA contract + docs sync):
   - fix(bug026): disable mirror start CTA during runningWithoutSession hold and sync validation docs

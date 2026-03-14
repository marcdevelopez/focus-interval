# Global Validation Ledger

Date: 2026-03-13
Scope: bugs + features + refactors + roadmap/process validations

## Record format (mandatory)

- `ID`
- `Type`
- `Priority`
- `Status`
- `Source` (path + line)
- `Item`
- `closed_commit_hash` (required on close)
- `closed_commit_message` (required on close)
- `evidence` (required on close)

Allowed status values: `Pending`, `In validation`, `Validated`, `Closed/OK`.

## Snapshot (2026-03-13)

- Roadmap `validation pending`: **69** items.
- Active bug-checklist open items: **2**.
- Profiling checklist open items: **8**.
- 2026-03-09 update: Fix 26 monitoring window reached target date but failed
  (persistent `Syncing session...` + black-screen resume scenario).
- 2026-03-09 partial follow-up: multi-device active run did not reproduce
  irrecoverable syncing, but Fix 26 remains open because the single-device +
  prolonged background + unstable network scenario is still failing.
- 2026-03-09 implementation update: Fix 26 hardening v4 landed (foreground
  bounded-backoff recovery + non-destructive clear recheck + resume listener
  guard + session-gap retry CTA). Exact repro + regression smoke pending.
- 2026-03-09 quick validation packet prepared for iOS + Chrome with planned
  logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
- 2026-03-09 quick packet executed (iOS simulator + Chrome): first run
  reproduced transient reconnect desync (timer projection skew ~45s), then
  follow-up implementation `418c75f` rejected invalid reconnect measurements
  (roundtrip/offset-jump guards + reject cooldown).
- 2026-03-09 re-validation after `418c75f`: PASS. Syncing duration matched
  offline window only; no reconnect timer jump and no irreversible sync hold.
- 2026-03-10 regression observed: Android stuck in irrecoverable `Syncing session...`
  (~12:15 CET) triggered by a Firebase Auth token refresh causing a `runningExpiry=true`
  false-positive (56ms spike) that silently disconnected the Firestore session listener.
  Root cause in second/third-cycle VM hardening (`9bab880`, `4f55010`, `26f0c7e`, `3ad6c98`).
  `418c75f` confirmed uninvolved. Rollback to `961f7eb` baseline performed (commit `4195ef1`).
  Fix 26 reopened — P0-F26-001 requires re-validation.
- 2026-03-10 rollback partial re-validation on commit `4195ef1` (Android + macOS logs)
  shows resumed snapshots and no irrecoverable hold during the sampled window, but
  runtime is still <1h, so closure is explicitly blocked until extended soak + exact repro.
- 2026-03-10 process hardening applied: mandatory listener-lifecycle guardrails
  documented in Fix 26 plan/checklist; next implementation cannot bypass these
  gates.
- 2026-03-10 Fix 26 follow-up implementation added cursor auto-repair for
  inconsistent activeSession reopen states (`currentPomodoro > totalPomodoros`,
  task cursor mismatch). Regression test added; manual device validation pending.
- 2026-03-10 Fix 26 follow-up v2 expanded recovery for `TaskRunGroup.status=running`
  + `activeSession.status=finished` inconsistent pairs. Added dedicated regression
  test; targeted analyze/test PASS; device validation still pending.
- 2026-03-10 Fix 26 follow-up v3 added stale non-active ownership recovery:
  when `running` group coexists with stale `finished` session, current device claims
  a rebuilt active snapshot; targeted analyze/test PASS.
- 2026-03-10 `P0-F26-003` closure validation PASS on commit `250c24d`
  (Android RMX3771 + macOS): no `sessionMissing`/`Syncing session...` signatures,
  deterministic owner handoff observed, and timer projection remained coherent with
  wall-clock and phase window in run-mode screenshots.
- 2026-03-13 Phase 5 docs-first diagnostic scope opened for Fix 26:
  mandatory lifecycle observability (`vmToken`, `SessionSub` open/close reasons,
  scheduled-action bridge diagnostics, stale-clear decision diagnostics) added to
  specs/contracts before runtime changes.
- 2026-03-13 Phase 5 runtime instrumentation implemented:
  `[VMLifecycle]`, `[SessionSub]`, `[SyncOverlay]` vmToken extension,
  `[ScheduledActionDiag]`, and `[StaleClearDiag]` now emit in runtime.
  Local Phase 5 smoke tests pass; item moved to `In validation` pending device logs.
- 2026-03-13 Phase 5 device validation closed the diagnostics packet:
  root cause confirmed from Chrome+iOS debug logs (`provider-dispose` while
  `/timer/:groupId` remained active), with B1+B2 split established.
- 2026-03-13 Phase 6 runtime (B1+B2) implemented and locally validated:
  keepAlive grace window + auto-open VM-disposed recovery refresh.
  Device exact-repro validation remains pending before closure.

## Already validated/closed (reference)

- [x] ID: `DONE-IDEA032` | Type: feature | Priority: P2 | Status: Closed/OK | Source: `docs/features/feature_2026_03_02_plan-group-notice-control/feature_plan.md:5`, `docs/features/feature_2026_03_02_plan-group-notice-control/feature_checklist.md:5` | Item: Plan Group Pre-Run Notice Control validated and closed. | closed_commit_hash: `not-backfilled` | closed_commit_message: `not-backfilled` | evidence: checklist status + feature docs.
- [x] ID: `DONE-FIX27` | Type: bug | Priority: P0 | Status: Closed/OK | Source: `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:16`, `docs/roadmap.md:261` | Item: Local -> Account re-entry overdue auto-start fixed and validated. | closed_commit_hash: `not-backfilled` | closed_commit_message: `not-backfilled` | evidence: iOS + Chrome logs listed in fix docs.

## Priority queue

### P0 blockers (must close before new feature work)

- [ ] ID: `P0-F26-001` | Type: bug | Priority: P0 | Status: In validation | Source: `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:174`, `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:187`, `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md:330` | Item: Re-validate exact single-device degraded-network repro after rollback to 961f7eb baseline (commit `4195ef1`); expected no irrecoverable `Syncing session...` hold and no black-screen resume. | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: Previously closed at `418c75f` (09/03/2026 PASS), then regression observed 10/03/2026 (Android stuck ~40min, `runningExpiry` false-positive disconnected session listener). Rollback to `961f7eb` performed. Partial logs on rollback (`2026_03_10_fix26_observation_partial_android_4195ef1.log`, `2026_03_10_fix26_observation_partial_macos_4195ef1.log`) show recovery, but window is <1h. Keep `In validation` until extended soak (>=4h) + exact degraded-network repro pass, with the new mandatory guardrails enforced before any new Fix 26 code changes.
- [x] ID: `P0-F26-004` | Type: refactor | Priority: P0 | Status: Closed/OK | Source: `docs/specs.md:2251`, `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:320`, `docs/dev_log.md:10556` | Item: Fix 26 Phase 5 runtime instrumentation — emit correlated lifecycle diagnostics with stable `vmToken` across `PomodoroViewModel` init/dispose, `SessionSub` open/close (explicit reason), scheduled-action bridge events, and `_clearStaleActiveSessionIfNeeded` clear/keep decisions. | closed_commit_hash: `7daf636` | closed_commit_message: `refactor(f26): phase 5 runtime lifecycle observability instrumentation` | evidence: Phase 5 logs captured (`2026-03-13_fix26_phase5_7daf636_*`) and analyzed; checklist marks Phase 5 COMPLETE with confirmed root cause.
- [ ] ID: `P0-F26-005` | Type: bug | Priority: P0 | Status: **Failed — exact repro FAIL 2026-03-14** | Source: `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:424`, `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md:656`, `docs/dev_log.md` Block 575 | Item: Fix 26 Phase 6 runtime hardening (B1+B2) — focalized patch on VM-disposal + auto-open guard; FAILED device validation 2026-03-14: Android entered `Syncing session...` at 22:21:37 spontaneously (no user-induced cut), cascade to macOS/Chrome/iOS; root cause is architectural — `_sessionMissingWhileRunning` latch fires from any 3s Firestore stream null regardless of VM disposal fix. Soak pass 2 cancelled. Next step: sync architecture rewrite (not more hardenings). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: Pass 1 (1h, 2026-03-13): exact repro REPRODUCED on Android at 22:21:37 → cascade 4 devices; timer frozen. Packet logs in `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_*`. Pass 2 cancelled — architectural redesign required.
- [ ] ID: `P0-F26-006` | Type: refactor | Priority: P0 | Status: In progress | Source: `docs/specs.md:2376`, `docs/roadmap.md:266`, `docs/dev_log.md` Block 584 | Item: Fix 26 rewrite contract + Stage A/B runtime — migrate countdown continuity to app-scope non-autoDispose `TimerService`, delegate VM command path (`start/pause/resume`) to service authority, and expose deterministic ownership sync state machine (`unloaded|owned|mirroring|degraded|recovery`) while preserving legacy ownership/handoff behavior. | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: Stage A runtime bridge (`248d963`) + Invariant 5 executable continuity (`915bd06`) + Stage B docs/test gate (`86594b5`) + Stage B runtime commits (`4112408`, `617cae4`). `[REWRITE-CORE]` now 5 PASS / 0 FAIL. Local smoke suite (`session_gap` + `pause_expiry` + `syncing_overlay`) now 28 PASS / 0 FAIL. Device packet commands + log URLs for exact devices (`HYGUT4GMJJOFVWSS`, `9A6B6687-8DE2-4573-A939-E4FFD0190E1A`, `macos`, `chrome`) registered in validation docs for 2026-03-14 pass1 1h run.
- [x] ID: `P0-F26-003` | Type: bug | Priority: P0 | Status: Closed/OK | Source: `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:195`, `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:227`, `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md:377`, `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md:502` | Item: Reopen/owner-switch must not persist invalid activeSession cursor (`currentPomodoro > totalPomodoros`) and must self-recover `running` group + stale `finished` session mismatches with deterministic owner restoration; app must reopen on correct running task/time and avoid `Pomodoro 2 of 1` / `00:00 Syncing session...`. | closed_commit_hash: `250c24d` | closed_commit_message: `fix(f26): recover stale finished session ownership with expiry-safe guard` | evidence: Postfix logs `2026-03-10_fix26_postfix_250c24d_macos_diag.log` + `2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log` show clean signatures (`sessionMissing/Syncing/Unhandled Exception/cloud_firestore unavailable/runningExpiry` all absent), stable run-mode alignment on both devices, and deterministic owner handoff while preserving coherent timer progression.
- [x] ID: `P0-F26-002` | Type: bug | Priority: P0 | Status: Closed/OK | Source: `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md:15` | Item: Final closure recorded in validation docs. | closed_commit_hash: `418c75f` | closed_commit_message: `fix: guard timesync offset against reconnect poisoning` | evidence: `quick_pass_checklist.md` and `plan_validacion_rapida_fix.md` updated to Closed/OK with re-validation PASS notes (09/03/2026). Regression note added 10/03/2026; closure will be re-issued after P0-F26-001 re-validation.
- [ ] ID: `P0-F25-001` | Type: bug | Priority: P0 | Status: Pending | Source: `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md:34` | Item: Local -> Account without false overlaps; ownership request delivered (Fix 25). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.

### P1 reopened roadmap validation items

- [ ] ID: `RVP-063` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:250` | Item: - Phase 10 — Auto-adjust breaks on valid pomodoro changes and break edits (focus-loss adjustment; Task Editor + Edit Preset) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-064` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:251` | Item: - Phase 10 — Task weight (%) is selection-scoped in Edit Task + info modal (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-065` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:252` | Item: - Phase 13 — Mirror session gaps must not drop Run Mode to Ready (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-066` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:269` | Item: - Phase 18 — Mode-specific breaks (global long-break counter in Mode A) implemented; validation pending. | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-067` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:270` | Item: - Phase 18 — Run Mode task transition catch-up after background/resume (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-068` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:282` | Item: - Phase 18 — Completion modal + Groups Hub navigation must work on owner and mirror devices (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-069` | Type: roadmap | Priority: P1 | Status: Pending | Source: `docs/roadmap.md:286` | Item: - Phase 18 — Initial ownership assignment must be deterministic when multiple devices are open (implemented; validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.

### P2 roadmap backlog validation items

- [ ] ID: `RVP-001` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:55` | Item: 26/01/2026: Scheduled auto-start + resume/launch catch-up implemented (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-002` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:89` | Item: 02/02/2026: Completion modal now navigates to Groups Hub; placeholder Groups Hub route added (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-003` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:90` | Item: 02/02/2026: Cancel running group now confirms and navigates to Groups Hub (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-004` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:92` | Item: 02/02/2026: Phase 19 Groups Hub core UI implemented (sections + actions); Task List banner + Run Mode indicator now open Groups Hub (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-005` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:93` | Item: 02/02/2026: Task List banner now clears stale sessions when group ends (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-006` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:94` | Item: 02/02/2026: Scheduled auto-start rechecks when active session ends; expired running groups auto-complete to unblock scheduled starts (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-007` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:95` | Item: 02/02/2026: Running group expiry now clears stale active sessions (Task List banner updates; validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-008` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:96` | Item: 02/02/2026: Scheduling now reserves the full Pre-Run window (noticeMinutes) and blocks invalid times (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-009` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:97` | Item: 02/02/2026: Pre-Run entry points added for scheduled groups (Task List banner + Groups Hub action; no AppBar changes) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-010` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:98` | Item: 02/02/2026: Task List now exposes a persistent Groups Hub CTA even with no active group (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-011` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:99` | Item: 02/02/2026: Task List running banner now falls back to running groups when no active session exists (Local Mode) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-012` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:100` | Item: 02/02/2026: Groups Hub hides notice/pre-run info for “Start now” groups (scheduledStartTime == null) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-013` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:101` | Item: 03/02/2026: Auto-adjust short/long breaks on valid pomodoro changes and break edits (Task Editor + Edit Preset) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-014` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:102` | Item: 03/02/2026: Break auto-adjust on break edits now applies on focus loss (no per-keystroke adjustments) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-015` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:103` | Item: 03/02/2026: Pomodoro Integrity Warning actions now show exact configuration source names (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-016` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:104` | Item: 03/02/2026: Pomodoro Integrity Warning now lists visual options per distinct structure + Default Preset badge (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-017` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:105` | Item: 03/02/2026: Run Mode now auto-exits to Groups Hub when a group is canceled (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-018` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:106` | Item: 03/02/2026: Integrity Warning copy clarified with explicit instruction + default badge moved below cards (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-019` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:107` | Item: 03/02/2026: Groups Hub summary modal expanded with timing, totals, and task breakdown (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-020` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:108` | Item: 03/02/2026: Groups Hub summary hides Scheduled start for non-planned runs (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-021` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:109` | Item: 03/02/2026: Groups Hub cards hide Scheduled row for non-planned runs (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-022` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:110` | Item: 03/02/2026: TimerScreen reloads on groupId changes; /timer routes now use page keys to prevent stale state (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-023` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:111` | Item: 03/02/2026: Cancel navigation uses root navigator and retries if still on /timer (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-024` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:112` | Item: 03/02/2026: Cancel now persists canceled status before clearing activeSession (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-025` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:113` | Item: 03/02/2026: Groups Hub "Go to Task List" CTA moved to top of content (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-026` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:114` | Item: 03/02/2026: Completed retention no longer evicted by canceled groups (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-027` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:115` | Item: 03/02/2026: Classic Pomodoro default now deduped on account-local preset push (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-028` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:116` | Item: 03/02/2026: Run Mode cancel navigation fallback added in build (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-029` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:122` | Item: 02/03/2026: ActiveSession idempotent writes now persist payload changes on equal sessionRevision (remainingSeconds and phase fields no longer dropped) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-030` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:125` | Item: 02/03/2026: Run Mode owner sync stabilization: owner keeps local machine as render authority, projection allows local fallback without server offset, and resync paths guard against disposed provider refs (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-031` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:163` | Item: 08/02/2026: Planning redistribution max-fit + inline adjusted-end notice + unit tests added (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-032` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:165` | Item: 11/02/2026: Ownership publish guard + ownership UI refresh to prevent stale owner flips (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-033` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:167` | Item: 11/02/2026: Desktop inactive resync keepalive to surface ownership requests while the window is inactive (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-034` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:169` | Item: 11/02/2026: Ownership auto-claim without request + stale threshold 45s + post-request resync (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-035` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:171` | Item: 11/02/2026: Paused ownership stability rules + Android paused heartbeats (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-036` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:173` | Item: 11/02/2026: Ownership API hardening (request vs claim split, owner-only clears) (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-037` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:175` | Item: 11/02/2026: Stale ownership checks ignore missing lastUpdatedAt to avoid phantom auto-claims/cleanup (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-038` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:177` | Item: 11/02/2026: Running-group expiry waits for the first activeSession snapshot to avoid completing paused sessions on resume (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-039` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:179` | Item: 11/02/2026: Running-group expiry now requires an activeSession that is running and matches the groupId (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-040` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:181` | Item: 11/02/2026: Removed repository auto-complete-on-read; expiry is enforced only by coordinator/viewmodel guards (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-041` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:183` | Item: 12/02/2026: Ownership requests re-sync on resume with a post-resume resubscription to surface pending requests (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-042` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:185` | Item: 12/02/2026: Mirror request indicator now shows pending immediately (optimistic UI) while waiting for ownership approval (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-043` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:187` | Item: 12/02/2026: Ownership request banner dismisses immediately on reject (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-044` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:189` | Item: 12/02/2026: Ownership reject dismiss no longer reappears on transient session gaps (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-045` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:193` | Item: 12/02/2026: Run Mode ownership indicator always visible (syncing variant); manual sync removed; VM now listens to the shared session stream; control gating requires a valid session snapshot (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-046` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:197` | Item: 12/02/2026: Session-missing gating now always blocks controls while a running group has no activeSession; auto-start performs a sync-then-start check; ownership indicator shows neutral state when no session exists (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-047` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:199` | Item: 12/02/2026: Sync-gap handling now neutralizes session-derived ownership state to avoid stale mirror/owner derivations (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-048` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:201` | Item: 12/02/2026: Ownership pending indicator now overrides syncing/no-session visuals on the requester (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-049` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:203` | Item: 12/02/2026: Optimistic ownership request now survives owner->mirror reset to avoid amber indicator flicker (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-050` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:205` | Item: 12/02/2026: Optimistic pending now overrides older rejected ownership snapshots to prevent request indicator flicker (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-051` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:207` | Item: 12/02/2026: Optimistic pending no longer cleared by stale rejected requests from other devices (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-052` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:209` | Item: 12/02/2026: Local pending gating keeps requester UI stable and disables duplicate request taps during snapshot lag (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-053` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:211` | Item: 12/02/2026: Ownership requests now include requestId to reconcile optimistic pending with remote snapshots (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-054` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:214` | Item: 12/02/2026: Requester pending UI now stays active until the owner responds (accept/reject) or another pending request appears (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-055` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:216` | Item: 12/02/2026: Request action moved to the ownership sheet; mirror control row no longer shows a Request button (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-056` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:218` | Item: 12/02/2026: Retry CTA now lives in the ownership sheet when a pending request becomes stale (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-057` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:221` | Item: 12/02/2026: CRITICAL: ownership request UI locked to AppBar sheet only; pending state remains stable until owner response (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-058` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:224` | Item: 12/02/2026: Reject now clears local pending; request keys use requestId to prevent suppressing new requests after rejection (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-059` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:226` | Item: 12/02/2026: Owner-side reject modal dismissal stabilized against requestId materialization flicker (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-060` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:232` | Item: 18/02/2026: Early overlap warning + mirror CTA + persistent conflict SnackBar implemented (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-061` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:235` | Item: 19/02/2026: Phase 17 scope extended — postpone follows running group in real time (no repeat modal) + paused overlap alerts implemented (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `RVP-062` | Type: roadmap | Priority: P2 | Status: Pending | Source: `docs/roadmap.md:239` | Item: 20/02/2026: Phase 17 scope extended — late-start queue owner-only flow (request/auto-claim), server-anchored projections with live updates, queue-confirm session bootstrap, and chained postpone for queued groups (validation pending). | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.

### P3 process/profiling validation items

- [ ] ID: `P3-MEM-94` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:94` | Item: Launch app in profile mode | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-95` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:95` | Item: Record initial RSS | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-96` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:96` | Item: Start a group | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-97` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:97` | Item: Pause / Resume | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-98` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:98` | Item: Cancel group | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-99` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:99` | Item: Reorder task list items | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-100` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:100` | Item: Confirm RSS stabilizes | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.
- [ ] ID: `P3-MEM-101` | Type: process | Priority: P3 | Status: Pending | Source: `docs/devtools-memory-profiling.md:101` | Item: Confirm Dart Heap does not grow indefinitely | closed_commit_hash: `-` | closed_commit_message: `-` | evidence: `-`.

## Enforcement rules

- Before switching to unrelated work, update current item status in this ledger and in source docs.
- Do not leave closure without commit + evidence fields completed.
- If one implementation closes multiple IDs, close each ID explicitly (no implicit closure).
- If an item becomes obsolete, set status `Closed/OK` and explain reason in `evidence`.

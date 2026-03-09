# Quick Pass Checklist — Fix 26 cycle 4

Date: 2026-03-07
Last reviewed: 2026-03-09
Status: **Reopened / FAIL (monitoring window)**

- [x] iOS + Chrome run completed with debug logs saved.
- [x] Original Fix 26 symptom (indefinite `Syncing session...`) not reproduced in first practical runs.
- [x] Owner cancel path observed without indefinite mirror lock.
- [x] Two-day monitoring window completed (target: 2026-03-09) — **FAIL**.
- [ ] Final closure recorded in validation docs.
- [x] Fix 27 exact repro PASS (Local -> Account after missed scheduled start opens Run Mode without restart).
- [x] Fix 27 regression smoke PASS (Fix 24, Fix 26, overlaps flow — iOS + Chrome logs confirm no regressions).

## Fix 26 Reopen Evidence (2026-03-08)
- Exact repro context:
  - macOS owner went to sleep/background.
  - Android remained as the only app/device open, with intermittent screen-off cycles.
  - First stuck observation: around 19:00 (2026-03-08), confirmed by screenshot timestamp 19:02.
  - Stuck window remained until around 20:45 (2026-03-08) with no recovery.
- Observed result:
  - Android stayed indefinitely on `Syncing session...` with amber ring from first observation (~19:00) through ~20:45, without recovery even after screen/navigation changes.
  - macOS resumed in `Syncing session...` with black screen after wake from sleep.
- Evidence:
  - Screenshot:
    - `docs/bugs/validation_fix_2026_03_07-01/screenshots/Screenshot_2026-03-08-19-02-12-76_24a6c2193a9deb7da51ed61dc48f62e5.jpg`
  - Logs:
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_android_cc5f55b.log`
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_macos_cc5f55b.log`
  - Key log signals:
    - Android: repeated Firestore `UNAVAILABLE` and `UnknownHostException` while session stayed stale.
    - macOS: repeated `Missing snapshot; clearing session` + `Resync missing; clearing state` after resume path.
- Decision:
  - Fix 26 remains open (not closable on 2026-03-09).

## Fix 27 Evidence
- iOS log: `2026_03_07_fix27v2_ios_debug.log` line 51016 — `Auto-start opening TimerScreen` at 22:49:03 for group `c2b7f11d`.
- Chrome log: `2026_03_07_fix27v2_chrome_debug.log` lines 2086–2090 — `Active session change route=/tasks` → `Attempting auto-open` → `Auto-open confirmed in timer route=/timer/c2b7f11d`.
- Root cause: `ref.invalidate(scheduledGroupCoordinatorProvider)` was disposing the coordinator's listeners, creating a race window where Firestore stream data arrived before the new coordinator instance rebuilt its subscriptions.
- Fix: removed the invalidation — coordinator's `ref.listen<AppMode>` handles mode transitions naturally via `_resetForModeChange()` + `_handleGroups()`.
- Fix commit: Block 550 in dev_log.md.

# Quick Pass Checklist — Fix 26 cycle 4

Date: 2026-03-07
Status: **Monitoring**

- [x] iOS + Chrome run completed with debug logs saved.
- [x] Original Fix 26 symptom (indefinite `Syncing session...`) not reproduced in first practical runs.
- [x] Owner cancel path observed without indefinite mirror lock.
- [ ] Two-day monitoring window completed (target: 2026-03-09).
- [ ] Final closure recorded in validation docs.
- [x] Fix 27 exact repro PASS (Local -> Account after missed scheduled start opens Run Mode without restart).
- [x] Fix 27 regression smoke PASS (Fix 24, Fix 26, overlaps flow — iOS + Chrome logs confirm no regressions).

## Fix 27 Evidence
- iOS log: `2026_03_07_fix27v2_ios_debug.log` line 51016 — `Auto-start opening TimerScreen` at 22:49:03 for group `c2b7f11d`.
- Chrome log: `2026_03_07_fix27v2_chrome_debug.log` lines 2086–2090 — `Active session change route=/tasks` → `Attempting auto-open` → `Auto-open confirmed in timer route=/timer/c2b7f11d`.
- Root cause: `ref.invalidate(scheduledGroupCoordinatorProvider)` was disposing the coordinator's listeners, creating a race window where Firestore stream data arrived before the new coordinator instance rebuilt its subscriptions.
- Fix: removed the invalidation — coordinator's `ref.listen<AppMode>` handles mode transitions naturally via `_resetForModeChange()` + `_handleGroups()`.
- Fix commit: Block 550 in dev_log.md.

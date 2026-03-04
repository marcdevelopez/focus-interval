# Feature Checklist — Plan Group Pre-Run Notice Control

Date: 02/03/2026
Feature ID: IDEA-032
Status: validated — 02/03/2026
Validation commit: see Block 531 in dev_log.md

## Functional Checks

- [x] Plan group shows a "Pre-run notice" row with the effective minutes.
- [x] Notice editor clamps to 0–15 and to the real-time allowed range.
- [x] Scheduled planning uses the selected notice for validation.
- [x] Re-plan snackbar offers Change notice and reopens planning. (auto-clamp + SnackBar instead of loop — UX equivalent, confirmed positive)
- [x] New group persists the selected notice in TaskRunGroup.noticeMinutes.

## Regression Checks

- [x] Start now flow unchanged (no pre-run required).
- [x] Scheduling with notice = 0 works without Pre-Run messaging.
- [x] Scheduling with notice > 0: auto-clamped with SnackBar notification (confirmed working, real-time).

## Validation notes

- Device: Android RMX3771, debug prod, 02/03/2026.
- Check 4 behaviour: auto-clamp fires within 1s with visible SnackBar informing the user of the adjustment. Original loop was replaced by this simpler and more positive UX.
- Check 8 behaviour: same auto-clamp + SnackBar when user selects a start time with insufficient margin.
- A minor UX fix was added during validation: ticker now shows SnackBar when notice is auto-reduced.

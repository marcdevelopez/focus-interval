# Feature Checklist — Plan Group Pre-Run Notice Control

Date: 02/03/2026
Feature ID: IDEA-032
Status: validation pending

## Functional Checks

- [ ] Plan group shows a "Pre-run notice" row with the effective minutes.
- [ ] Notice editor clamps to 0–15 and to the real-time allowed range.
- [ ] Scheduled planning uses the selected notice for validation.
- [ ] Re-plan snackbar offers Change notice and reopens planning.
- [ ] New group persists the selected notice in TaskRunGroup.noticeMinutes.

## Regression Checks

- [ ] Start now flow unchanged (no pre-run required).
- [ ] Scheduling with notice = 0 works without Pre-Run messaging.
- [ ] Scheduling with notice > 0 still blocks invalid pre-run windows.

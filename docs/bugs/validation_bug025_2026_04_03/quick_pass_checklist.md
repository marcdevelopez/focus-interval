## Exact repro

- [ ] Scenario A PASS on Android owner (exact boundary conflict in paused state).
- [ ] Scenario B PASS on Android/macOS (decision already active before entering Run Mode).
- [ ] Scenario C PASS on re-entry after route switch with still-valid conflict.

## Regression smoke

- [ ] Scenario D PASS (`Postpone scheduled` does not trigger immediate duplicate modal).
- [ ] Existing overlap modal actions (`End current group` / `Postpone scheduled` / `Cancel scheduled`) still work.

## Local gate

- [x] flutter analyze PASS (`2026-04-03_bug025_547de2b_local_analyze.log`).
- [x] Targeted overlap test pack PASS (`2026-04-03_bug025_547de2b_local_targeted-tests.log`).

## Closure rule

Close only when all boxes above are checked and evidence is synchronized in bug_log + validation_ledger + dev_log.

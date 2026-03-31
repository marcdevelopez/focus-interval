## Exact repro

- [x] Scenario A PASS: synthetic `Custom` option not shown in Preset dropdown.
- [x] Scenario B PASS: real preset named `Custom` appears once and is selectable.
- [x] Scenario C PASS: linked -> manual edit -> unlinked transition is deterministic.

## Regression smoke

- [x] Existing Preset dropdown behavior still shows real persisted presets.
- [x] `Save as new preset` visibility toggles correctly with linked/unlinked state.

## Local gate

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task preset selector"` PASS.

## Closure rule

- [x] Close only when all checks above have evidence recorded in bug log + validation ledger + dev log.

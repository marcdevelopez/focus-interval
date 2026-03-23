## Exact repro

- [x] Android Account Mode late-open scenario executed with 3 overdue groups.
- [x] `Resolve overlaps` opened immediately on app open.
- [x] Queue contained all 3 groups (`LateStartQueue overdue=3`).
- [x] After `Continue`, scheduler moved to running flow without overdue bypass.
- [x] `Start now` on following queued group did not bypass (blocked by running conflict).
- [x] No empty completion modal (`Tasks group completed` 0/0/0) observed.

## Regression smoke

- [x] No `overdue=2` re-queue signature after confirm.
- [x] No `Scheduling conflict` re-trigger signature in this validation window.
- [x] Transition to timer executed cleanly (`running-open-timer` + auto-open).

## Local gate

- [x] Validation-only closure (no new code changes in this cycle).
- [x] Historical implementation gate covered under fix commit `c6370f4`.

## Closure rule

- [x] Exact repro PASS.
- [x] Regression smoke PASS.
- [x] Evidence captured in log path and reflected in bug/ledger/dev docs.

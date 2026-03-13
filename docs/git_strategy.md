# Git Strategy — Focus Interval

Last updated: 2026-03-14

---

## Active branches

| Branch | Base | Status | Purpose |
|--------|------|--------|---------|
| `main` | — | stable | Releases only. Never merge known-bug states. |
| `fix26-reopen-black-syncing-2026-03-09` | `main` | frozen (ancestor of refactor) | Historical branch for early Fix 26 cycles. Keep read-only. |
| `refactor-run-mode-sync-core` | `fix26-reopen-black-syncing-2026-03-09` | active (synced with origin) | Current working branch with Phases 2–6 refactor, diagnostics, and failure docs. |

### Relationship

```text
main
 └─ fix26-reopen-black-syncing-2026-03-09  (b085ea6)  <- ancestor
     └─ refactor-run-mode-sync-core         (51ccf0a) <- current HEAD
         └─ rewrite-sync-architecture       (TBD)      <- next branch
```

`fix26-reopen-black-syncing-2026-03-09` is fully contained in
`refactor-run-mode-sync-core`.

---

## Merge policy for `main`

Never merge to `main` while any P0 sync bug remains open.

PR-to-main gate:
1. P0 sync item (`P0-F26-005` successor or equivalent) is closed with exact repro PASS.
2. Regression smoke PASS on all target devices.
3. Soak window >=4h without irrecoverable `Syncing session...`.
4. `flutter analyze` has no errors and test suite passes.
5. Roadmap/dev-log/validation ledger are synchronized with evidence.

---

## Safe sequence (no progress loss)

### 1. Keep current active branch as source of truth

```bash
git checkout refactor-run-mode-sync-core
git pull --ff-only origin refactor-run-mode-sync-core
```

### 2. Freeze a historical tag for the failed Phase 6 state

```bash
git tag fix26-phase6-failed-2026-03-14 b1cb17e
git push origin fix26-phase6-failed-2026-03-14
```

### 3. Create the rewrite branch from current refactor HEAD

```bash
git checkout -b rewrite-sync-architecture
git push -u origin rewrite-sync-architecture
```

Do not branch from `main`: the rewrite depends on diagnostics/contracts already present in `refactor-run-mode-sync-core`.

### 4. Keep legacy branches until rewrite closure

Keep both historical branches (`fix26-reopen...`, `refactor-run-mode-sync-core`) until rewrite is validated and merged.

---

## Flutter-generated iOS file noise

| File | Why it changes | Policy |
|------|----------------|--------|
| `ios/Flutter/AppFrameworkInfo.plist` | `flutter run -d ios` removes `MinimumOSVersion` | File normalized in commit `1b1dc33`; do not manually edit it. |

If it appears modified again:

```bash
git checkout -- ios/Flutter/AppFrameworkInfo.plist
```

Only commit this file again if Flutter SDK generation behavior changed intentionally.

---

## Quick reference commands

```bash
# Branch and tracking state
git branch -vv --all

# Full graph
git log --oneline --graph --decorate --all

# Discard plist noise
git checkout -- ios/Flutter/AppFrameworkInfo.plist

# Push active branch
git push origin refactor-run-mode-sync-core
```

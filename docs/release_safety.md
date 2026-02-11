# Release Safety and Data Evolution Policy

This document defines the non-negotiable rules for shipping production updates and
changing Firebase/Firestore data structures without breaking existing users.

Scope:
- Firestore data models, queries, and indexes
- Firestore security rules
- Sync and ownership logic
- Authentication providers and identity flows
- Any change that can impact production data or compatibility

If a change touches any of the above, this policy must be followed and referenced
in the dev log.

## Environments and data isolation

1. Development (DEV)
- Default to Firebase Emulator for local development.
- DEV must never point to production by default.
- If DEV must hit a real backend, use STAGING only.

2. Staging (STG)
- Separate Firebase project from production.
- Mirrors production configuration (indexes, rules, auth providers).
- Used for schema/rules validation and release candidates.

3. Production (PROD)
- Used only by release builds.
- Any change must be backward compatible with older clients.

## Compatibility rules (production is always backward compatible)

- Never remove, rename, or change the type of existing fields in a way that older
  clients cannot read.
- Additive changes are allowed (new fields with safe defaults).
- Clients must tolerate missing fields and null values.
- Avoid breaking query changes (e.g., switching required filters or ordering) until
  old clients are no longer active.

## Versioned data (required for critical models)

Critical documents must include a version marker when the shape or behavior changes.
Examples: PomodoroTask, TaskRunGroup, PomodoroSession, Presets.

Recommended field:
- dataVersion: int

Clients must be able to read older versions and apply safe defaults or migrations
in memory.

## Safe migration sequence (Firestore)

Use this sequence for any structural change:

1. Define the new fields and update rules to allow both old and new shapes.
2. Release client A:
   - Writes new fields.
   - Reads new fields when present, otherwise falls back to old fields.
3. Backfill data (script or one-time migration job) in STAGING first, then PROD.
4. Monitor for stability and confirm adoption.
5. Release client B that prefers the new shape and treats the old shape as legacy.
6. Only after old clients are largely gone, remove legacy paths and fields.

Never combine steps 1-6 in a single release.

## Firestore rules changes

- Any new collection or document path must be added to `firestore.rules` and
  redeployed (emulator -> STAGING -> PROD).
- Rules must remain compatible with both old and new clients during migrations.
- Test rules in the emulator first, then STAGING.
- Never deploy a rule change that blocks existing production clients without a
  coordinated forced upgrade strategy.

## Release sequencing (client + backend)

- Do not ship a client change that depends on a breaking backend change.
- Prefer decoupling:
  - Release A: add new fields and compatibility.
  - Backend: update rules and indexes with compatibility.
  - Release B: enforce new behavior after adoption.

## Rollout and safety

- Use staged rollouts (where supported) to limit blast radius.
- Keep a rollback plan (last known good build).
- Use feature flags for risky or experimental behavior.

If Remote Config is not used, a Firestore "featureFlags" document may be used as
an explicit kill switch with safe defaults.

## Testing matrix before production release

At minimum:
- Latest release client vs production data.
- Previous release client vs production data.
- Mixed-version sync (owner on new release, mirror on old release).
- Emulator or STAGING validation for rules and migrations.

## Documentation and logging requirements

- Update `docs/specs.md` before any authoritative behavior change.
- Record the migration plan and rollout steps in `docs/dev_log.md`.
- If a migration reopens earlier phase work, list it in the Reopened phases.

## Tooling guardrails

- Environment setup and staging steps live in `docs/environments.md`.
- Run `tools/check_release_safety.sh` before commits that touch Firestore rules
  or model schema files.

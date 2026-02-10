# STAGING Setup Checklist (focus-interval-staging)

Use this checklist to make the STAGING Firebase project mirror PROD, while keeping
DEV on local emulators only.

## 0) Environment mapping (authoritative)

- PROD: `focus-interval` (original project).
- STAGING: `focus-interval-staging`.
- DEV: local emulators only (no real Firebase project).

## 1) Create the STAGING project

- Create a Firebase project named `focus-interval-staging`.
- Use the same Firestore region as PROD (region cannot be changed later).
- Confirm billing plan if any required Firebase products need it.

Billing plan note:
- STAGING is currently on Spark (as of 10/02/2026).
- Upgrade to Blaze only if a required product needs it or you want to match PROD.

## 2) Enable the same Firebase products as PROD

- Firestore (Native mode).
- Firebase Auth.
- Storage / Hosting / Functions / Analytics (only if used in PROD).

## 3) Configure Auth providers (match PROD)

- Enable Email/Password.
- Enable Google and/or GitHub if used in PROD.
- Create **separate** OAuth credentials for STAGING.
- Use the callback/redirect URL shown in the STAGING Auth provider setup.

## 4) Register the same apps as PROD

Create all of these apps in the STAGING project:

- Android: package name `com.marcdevelopez.focusinterval`
- iOS: bundle id `com.marcdevelopez.focusinterval`
- macOS: bundle id `com.marcdevelopez.focusinterval.macos`
- Web: `focus_interval (web)`
- Windows: `focus_interval (windows)` (uses web config)

Notes:
- macOS appears as an Apple/iOS app in the console. This is expected.
- If you use Google Sign-In on Android, add the SHA-1/SHA-256 fingerprints
  for the debug and release keystores.

## 5) Generate `firebase_options_staging.dart`

Run FlutterFire CLI:

```
flutterfire configure \
  --project focus-interval-staging \
  --out lib/firebase_options_staging.dart \
  --platforms=android,ios,macos,web,windows
```

Confirm:
- `ios.appId` and `macos.appId` are different.
- Bundle IDs match the values above.

## 6) Handle native config files safely

FlutterFire may overwrite production config files:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

If this happens:

- Restore PROD config from git after generating staging options:
  - `git restore android/app/google-services.json`
  - `git restore ios/Runner/GoogleService-Info.plist`
  - `git restore macos/Runner/GoogleService-Info.plist`
- Keep staging copies locally (or in a private location) if you need to
  test Google Sign-In on STAGING.

## 7) Deploy rules and indexes to STAGING

```
firebase deploy --project focus-interval-staging --only firestore:rules,firestore:indexes
```

## 8) Quick STAGING validation (minimum)

- Run with `APP_ENV=staging`.
- Sign up / sign in using the STAGING project.
- Create a task and confirm it appears in the STAGING Firestore console.
- Confirm data is **not** written to PROD.

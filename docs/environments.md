# Environments (DEV / STAGING / PROD)

This project uses runtime environment selection via `--dart-define=APP_ENV`.

Supported values:
- `dev`
- `staging`
- `prod`

Defaults:
- Debug/Profile builds default to `dev`.
- Release builds must use `prod` (enforced at runtime).
- Non-release builds cannot use `prod`.

Project mapping:
- PROD: Firebase project `focus-interval` (the original project).
- STAGING: Firebase project `focus-interval-staging`.
- DEV: local emulators only (no real Firebase project).

## DEV (Emulators only)

DEV is emulator-only by design.

1. Start emulators (Firestore + Auth):
   - `firebase emulators:start --only firestore,auth`
2. Run the app with DEV env (default), or explicitly:
   - `flutter run -d <device> --dart-define=APP_ENV=dev`

Emulator host defaults:
- Android emulator: `10.0.2.2`
- Others (iOS/macOS/Windows/Web): `localhost`

Override host/ports if needed:
- `--dart-define=FIREBASE_EMULATOR_HOST=<ip>`
- `--dart-define=FIREBASE_AUTH_EMULATOR_PORT=9099`
- `--dart-define=FIRESTORE_EMULATOR_PORT=8080`

If you use a physical device, set `FIREBASE_EMULATOR_HOST` to your machine's LAN IP.

Emulator UI:
- URL: `http://127.0.0.1:4000/`
- Firestore tab: `http://127.0.0.1:4000/firestore`
- Auth tab: `http://127.0.0.1:4000/auth`

## STAGING (separate Firebase project)

Create a dedicated Firebase project for staging and register apps for every platform:
See `docs/staging_checklist.md` for the full step-by-step setup.

Required apps in the STAGING project:
- Android: package name `com.marcdevelopez.focusinterval`
- Apple (iOS): bundle id `com.marcdevelopez.focusinterval`
- Apple (macOS): bundle id `com.marcdevelopez.focusinterval.macos`
- Web (for Web build)
- Web (for Windows build) — Windows uses web config

Note on macOS: Firebase Console does not show a separate "macOS" option.
Create a second Apple app using the macOS bundle ID. It will still appear as an
Apple/iOS app in the console, but it is valid for macOS.

### Generate staging FirebaseOptions

Use FlutterFire CLI to generate `lib/firebase_options_staging.dart`:

```
flutterfire configure \
  --project <staging-project-id> \
  --out lib/firebase_options_staging.dart \
  --platforms=android,ios,macos,web,windows
```

Important:
- The CLI may overwrite `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist` / `macos/Runner/GoogleService-Info.plist`.
- Do **not** commit staging config into production paths. After generating the
  staging options file, restore production config files if needed.

Recommended approach for staging auth:
- Keep production `google-services.json` and `GoogleService-Info.plist` in repo.
- For staging tests that require Google Sign-In, temporarily swap the config
  files locally or add build flavors (post-MVP).

Run with staging:
- `flutter run -d <device> --dart-define=APP_ENV=staging`

## Linux desktop note

- Linux desktop runs in Local Mode only (no Firebase Auth/Firestore).
- Rationale: FlutterFire plugins do not officially support Linux desktop.
- Use Web (Chrome) on Linux if you need Account Mode.

## PROD (release only)

Release builds must use production options and cannot run with `APP_ENV=staging`.

Example:
- `flutter build macos --release --dart-define=APP_ENV=prod`

## Summary: commands

DEV (emulator):
- Start emulators: `firebase emulators:start --only firestore,auth`
- `flutter run -d <device> --dart-define=APP_ENV=dev`

STAGING:
- `flutter run -d <device> --dart-define=APP_ENV=staging`

PROD (release):
- `flutter build <platform> --release --dart-define=APP_ENV=prod`

PROD (release + GitHub OAuth):
- `flutter build <platform> --release --dart-define=APP_ENV=prod --dart-define=GITHUB_OAUTH_CLIENT_ID="<your_client_id>"`

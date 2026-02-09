# Focus Interval

Cross-platform Pomodoro app (macOS / Windows / Linux / iOS / Android / Web) built with Flutter.

## 📘 Documentation

- [Specifications](docs/specs.md)
- [Roadmap](docs/roadmap.md)
- [Development Log](docs/dev_log.md)
- [Linux Dependencies](docs/linux_dependencies.md)
- [Team Roles & Collaboration Model](docs/team_roles.md)
- [Agent Guide (internal)](AGENTS.md)

## 🧪 Status

Roadmap phase: 17 — Planning Flow + Conflict Management.

## 🖥️ Target platforms

- macOS (Intel & Apple Silicon)
- Windows 10/11 Desktop
- Linux GTK-based distros (Ubuntu, Fedora, etc.)
- iOS
- Android
- Web (Chrome)

Linux runs in local-only mode (no Firebase Auth/sync).

## 🛠️ Tech Stack

Flutter · Firebase Auth · Firestore · Riverpod · GoRouter · just_audio · flutter_local_notifications · audioplayers (Windows) · local_notifier (Windows/Linux) · shared_preferences (Linux local-only) · MVVM

## Web development (local)

- Run with a fixed port: `flutter run -d chrome --web-port=5001`.
- To persist auth sessions between runs, use a stable Chrome profile:
  `flutter run -d chrome --web-port=5001 --web-browser-flag="--user-data-dir=$HOME/.focus_interval_chrome"`.
- Ensure `http://localhost:5001` is listed in Google OAuth Authorized JavaScript origins.

## GitHub OAuth (desktop)

- Desktop uses **GitHub Device Flow** (no backend).
- Create `.env.local` (not committed) **in the project root** on each machine where you run desktop builds:
  - macOS:
    - `export GITHUB_OAUTH_CLIENT_ID="<Firebase GitHub Client ID (principal)>"`
  - Windows (PowerShell):
    - `$env:GITHUB_OAUTH_CLIENT_ID="<Firebase GitHub Client ID (principal)>"`
- Run:
  - `./scripts/run_macos.sh` (this run --profile --devtools and print macos-log.txt in root /)
  - `powershell -ExecutionPolicy Bypass -File .\scripts\run_windows.ps1`

## Environments (DEV / STAGING / PROD)

- `APP_ENV=dev` (default for debug/profile) uses Firebase emulators only.
- `APP_ENV=staging` targets a separate Firebase project.
- `APP_ENV=prod` is allowed only in release builds.

See `docs/environments.md` for setup steps and platform notes.

## 📦 Android builds

Lightweight release APKs (split ABI):

```
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons   # optional
flutter build apk --release --split-per-abi
```

- APKs are generated per ABI (armeabi-v7a, arm64-v8a, x86_64) in `build/app/outputs/flutter-apk/`.
- Install an APK:
  `adb -s <device> install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- If you need a single universal APK, disable `splits.abi` in `android/app/build.gradle.kts` (or use `flutter build apk --no-split-per-abi` temporarily).
- For Play, use `flutter build appbundle`; Play handles the split.
- Note: release builds use minify/shrink and debug signing by default; for production, configure a keystore in `android/app/build.gradle.kts`.

## 📱 iOS build (release)

- `flutter build ios --release`
- Requires Xcode signing; for CI you can use `--no-codesign` and archive later in Xcode.

## 🖥️ Desktop builds (release)

- macOS: `flutter build macos --release`
- Windows: `flutter build windows --release`
- Linux: `flutter build linux --release`
- Artifacts land under `build/<platform>/...` (release bundles/executables).

## 🌐 Web build (release)

- `flutter build web --release`
- Output is `build/web/` for deployment.

## Release checklist

- Follow `docs/release_safety.md` (backward compatibility and migration rules).
- Run `tools/check_release_safety.sh` before commits that touch Firestore rules or model schemas.
- Validate DEV (emulator) and STAGING before deploying PROD.

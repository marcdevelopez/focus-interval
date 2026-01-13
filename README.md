# Focus Interval
Pomodoro desktop app (macOS / Windows / Linux) built with Flutter.

## 📘 Documentation
- [Specifications](docs/specs.md)
- [Roadmap](docs/roadmap.md)
- [Development Log](docs/dev_log.md)
- [Linux Dependencies](docs/linux_dependencies.md)
- [Team Roles & Collaboration Model](docs/team_roles.md)
- [Agent Guide (internal)](agent.md)

## 🧪 Status
Roadmap phase: 14 — Sounds and Notifications (Linux verification pending).

## 🛠️ Tech Stack
Flutter · Firebase Auth · Firestore · Riverpod · MVVM

## Web development (local)
- Run with a fixed port: `flutter run -d chrome --web-port=5001`.
- Ensure `http://localhost:5001` is listed in Google OAuth Authorized JavaScript origins.

## 📦 Android builds
- Release APKs are generated per ABI (armeabi-v7a, arm64-v8a, x86_64) with minify/shrink enabled. Command: `flutter build apk --release` (or `--split-per-abi`).
- APKs live in `build/app/outputs/flutter-apk/` per architecture.
- If you need a single universal APK, disable `splits.abi` in `android/app/build.gradle.kts` (or use `flutter build apk --no-split-per-abi` temporarily).
- For Play, use `flutter build appbundle`; Play handles the split.

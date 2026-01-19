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
- Ensure `http://localhost:5001` is listed in Google OAuth Authorized JavaScript origins.

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

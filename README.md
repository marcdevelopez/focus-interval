# Focus Interval
Pomodoro Desktop App (macOS / Windows / Linux) built with Flutter.

## 📘 Documentation
- [Specifications](docs/specs.md)
- [Roadmap](docs/roadmap.md)
- [Development Log](docs/dev_log.md)
- [Team Roles & Collaboration Model](docs/team_roles.md)
- [Agent Guide (internal)](agent.md)

## 🧪 Status
Roadmap phase: 10 — Editor de Tarea (Fases 7–9 completadas).

## 🛠️ Tech Stack
Flutter · Firebase Auth · Firestore · Riverpod · MVVM

## 📦 Android builds
- APKs release se generan divididos por ABI (armeabi-v7a, arm64-v8a, x86_64) con minify/shrink activos. Comando: `flutter build apk --release` (o `--split-per-abi`).
- Los APK están en `build/app/outputs/flutter-apk/` por arquitectura.
- Si necesitas un único APK universal, desactiva `splits.abi` en `android/app/build.gradle.kts` (o usa `flutter build apk --no-split-per-abi` si temporal).
- Para publicar en Play, usa `flutter build appbundle`; el split lo hace Play.

# Flutter DevTools – Memory Profiling Guide

This document describes the exact workflow used to validate memory usage and
spot potential leaks in Focus Interval. Follow this guide during regular
verification runs and when closing bugfixes that may affect timers, streams,
or session lifecycle behavior.

The goal is to ensure:
- No Dart heap leaks
- Stable RSS over time
- Correct behavior during run / pause / resume / cancel

## 1. Launching the app in profile mode

Always use profile mode when analyzing memory.

macOS:
```bash
flutter run -d macos --profile --devtools
```

Windows:
```bash
flutter run -d windows --profile --devtools
```

Linux:
```bash
flutter run -d linux --profile --devtools
```

iOS (physical device only):
```bash
flutter run -d ios --profile --devtools
```

Android:
```bash
flutter run --profile --devtools
```

Web (Chrome):
```bash
flutter run -d chrome --profile --devtools --web-port=5001
```

Never evaluate memory in debug mode. Debug mode is not representative.

## 2. Opening DevTools

Always open DevTools from the URL printed by Flutter in the terminal.
Do not open DevTools manually, as it may not attach correctly.

## 3. Key memory metrics

- RSS (Resident Set Size): real memory used by the process.
- Allocated: Dart heap capacity reserved by the VM.
- Dart Heap: actual Dart objects currently in memory.

Important:
- Dart Heap should go up and down.
- RSS may go up but must stabilize.

## 4. Expected memory behavior

Initial app launch:
- RSS ~120–150 MB (macOS Flutter desktop)

Running a group:
- RSS increases due to timers, audio, engine caches

Pause / Resume:
- Dart Heap may increase temporarily
- RSS usually remains stable

Cancel + return to hub:
- RSS may not decrease immediately (normal on macOS)
- Dart Heap should stabilize

## 5. Red flags

Potential memory leak indicators:
- Dart Heap continuously growing after repeated interactions
- RSS growing in steps without stabilizing
- RSS increasing every time a group is started/cancelled

If observed, inspect:
- Timers not cancelled
- StreamSubscriptions not disposed
- Controllers recreated repeatedly

## 6. Memory regression checklist

- [ ] Launch app in profile mode
- [ ] Record initial RSS
- [ ] Start a group
- [ ] Pause / Resume
- [ ] Cancel group
- [ ] Reorder task list items
- [ ] Confirm RSS stabilizes
- [ ] Confirm Dart Heap does not grow indefinitely

Last validated:
- Date: 2026-02-07
- Flutter version: X.Y.Z
- Platform: macOS
- Result: No memory leaks detected

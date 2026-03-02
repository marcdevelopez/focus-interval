# Guia de logs de validacion (bugs)

Este archivo define como capturar logs de validacion y guardarlos dentro del
directorio de la validacion activa en `docs/bugs/`.

## Uso rapido

1. Entra a la raiz del proyecto:

```bash
cd /Users/devcodex/development/focus_interval
```

2. Crea el directorio de logs de la validacion actual:

```bash
mkdir -p docs/bugs/validation_fix_YYYY_MM_DD/logs
```

3. Ejecuta el comando segun plataforma:

### Android (ejemplo RMX3771)

Release (prod):

```bash
flutter run -v --release -d RMX3771 --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_android_RMX3771_diag.log
```

Debug (prod + override temporal):

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_android_RMX3771_debug.log
```

### macOS

Release (prod):

```bash
flutter run -v --release -d macos --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_macos_diag.log
```

Debug (prod + override temporal):

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_macos_debug.log
```

### Windows

Release (prod):

```bash
flutter run -v --release -d windows --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_windows_diag.log
```

Debug (prod + override temporal):

```bash
flutter run -v --debug -d windows --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_windows_debug.log
```

### Linux

Release (prod):

```bash
flutter run -v --release -d linux --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_linux_diag.log
```

Debug (prod + override temporal):

```bash
flutter run -v --debug -d linux --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_linux_debug.log
```

### iOS Simulator (ejemplo iPhone 17 Pro)

```bash
flutter run -v --debug -d "iPhone 17 Pro" --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_ios_simulator_iphone_17_pro_diag.log
```

### Web (Chrome)

Release (prod):

```bash
flutter run -v --release -d chrome --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_web_chrome_diag.log
```

Debug (prod + override temporal):

```bash
flutter run -v --debug -d chrome --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_web_chrome_debug.log
```

## Notas

- Sustituye `YYYY_MM_DD` por la fecha de la validacion actual.
- Sustituye `YYYY-MM-DD` por la fecha real del log.
- Sustituye el id del dispositivo si cambia (ej. `RMX3771`).
- iOS Simulator no soporta `--release` ni `--profile`; usa `--debug`.
- `ALLOW_PROD_IN_DEBUG=true` es temporal para pruebas reales en debug en todas las plataformas hasta que staging este configurado; al usar staging, elimina este override y usa `APP_ENV=staging`.
- Si aparece `No pubspec.yaml`, asegurate de estar en la raiz del repo.

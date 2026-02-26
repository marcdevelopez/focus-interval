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

```bash
flutter run -v --release -d RMX3771 --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_android_RMX3771_diag.log
```

### macOS

```bash
flutter run -v --release -d macos --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_YYYY_MM_DD/logs/YYYY-MM-DD_macos_diag.log
```

## Notas

- Sustituye `YYYY_MM_DD` por la fecha de la validacion actual.
- Sustituye `YYYY-MM-DD` por la fecha real del log.
- Sustituye el id del dispositivo si cambia (ej. `RMX3771`).
- Si aparece `No pubspec.yaml`, asegurate de estar en la raiz del repo.

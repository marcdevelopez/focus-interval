import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb,
        kReleaseMode;

import '../firebase_options.dart';
import '../firebase_options_staging.dart';

enum AppEnv { dev, staging, prod }

class AppConfig {
  final AppEnv appEnv;
  final FirebaseOptions firebaseOptions;
  final bool useFirebaseEmulator;
  final String emulatorHost;
  final int authEmulatorPort;
  final int firestoreEmulatorPort;
  final bool allowProdWrites;

  const AppConfig({
    required this.appEnv,
    required this.firebaseOptions,
    required this.useFirebaseEmulator,
    required this.emulatorHost,
    required this.authEmulatorPort,
    required this.firestoreEmulatorPort,
    required this.allowProdWrites,
  });

  bool get isProd => appEnv == AppEnv.prod;

  String get debugLabel =>
      'env=${appEnv.name} project=${firebaseOptions.projectId} '
      'emulator=$useFirebaseEmulator host=$emulatorHost '
      'ports=auth:$authEmulatorPort,firestore:$firestoreEmulatorPort';

  static AppConfig fromEnvironment() {
    final resolvedEnv = _resolveEnv();
    final allowProdInDebug = _allowProdInDebug();

    if (kReleaseMode && resolvedEnv != AppEnv.prod) {
      throw StateError(
        'Release builds must use APP_ENV=prod (got ${resolvedEnv.name}).',
      );
    }

    if (!kReleaseMode && resolvedEnv == AppEnv.prod && !allowProdInDebug) {
      throw StateError(
        'Non-release builds cannot use APP_ENV=prod. '
        'Use APP_ENV=staging or APP_ENV=dev with emulators. '
        'Temporary iOS debug override: ALLOW_PROD_IN_DEBUG=true.',
      );
    }

    final useEmulator = resolvedEnv == AppEnv.dev
        ? const bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: true)
        : false;

    if (resolvedEnv == AppEnv.dev && !useEmulator) {
      throw StateError(
        'APP_ENV=dev requires Firebase emulators. '
        'Start emulators and keep USE_FIREBASE_EMULATOR=true.',
      );
    }

    final emulatorHost = _resolveEmulatorHost();
    final authPort = const int.fromEnvironment(
      'FIREBASE_AUTH_EMULATOR_PORT',
      defaultValue: 9099,
    );
    final firestorePort = const int.fromEnvironment(
      'FIRESTORE_EMULATOR_PORT',
      defaultValue: 8080,
    );

    final options = _selectFirebaseOptions(resolvedEnv);
    final allowProdWrites =
        (kReleaseMode || allowProdInDebug) && resolvedEnv == AppEnv.prod;

    final config = AppConfig(
      appEnv: resolvedEnv,
      firebaseOptions: options,
      useFirebaseEmulator: useEmulator,
      emulatorHost: emulatorHost,
      authEmulatorPort: authPort,
      firestoreEmulatorPort: firestorePort,
      allowProdWrites: allowProdWrites,
    );

    if (config.isProd && !config.allowProdWrites) {
      throw StateError(
        'Production writes are disabled. Use a release build for APP_ENV=prod.',
      );
    }

    if (kDebugMode) {
      debugPrint('AppConfig: ${config.debugLabel}');
    }

    return config;
  }

  static AppEnv _resolveEnv() {
    final raw = const String.fromEnvironment('APP_ENV');
    if (raw.isNotEmpty) {
      return AppEnv.values.firstWhere(
        (env) => env.name == raw,
        orElse: () => throw StateError(
          'Invalid APP_ENV=$raw. Use dev, staging, or prod.',
        ),
      );
    }
    return kReleaseMode ? AppEnv.prod : AppEnv.dev;
  }

  static bool _allowProdInDebug() {
    // Temporary override for iOS debug simulator validation with real accounts.
    // Remove this once staging is configured and in use.
    if (!kDebugMode) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    return const bool.fromEnvironment(
      'ALLOW_PROD_IN_DEBUG',
      defaultValue: false,
    );
  }

  static FirebaseOptions _selectFirebaseOptions(AppEnv env) {
    switch (env) {
      case AppEnv.dev:
      case AppEnv.prod:
        return DefaultFirebaseOptions.currentPlatform;
      case AppEnv.staging:
        StagingFirebaseOptions.assertConfigured();
        return StagingFirebaseOptions.currentPlatform;
    }
  }

  static String _resolveEmulatorHost() {
    final raw = const String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    if (raw.isNotEmpty) return raw;
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }
}

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'linux_dependency_types.dart';

class LinuxDependencyChecker {
  static Future<LinuxDependencyReport> check() async {
    if (kIsWeb || !Platform.isLinux) {
      return LinuxDependencyReport.empty;
    }

    final osRelease = await _readOsRelease();
    final family = _resolveFamily(osRelease);
    final missing = <LinuxDependency>{};

    if (!_canLoadAny(['libnotify.so.4', 'libnotify.so'])) {
      missing.add(LinuxDependency.notifications);
    }

    final hasGstreamer =
        _canLoadAny(['libgstreamer-1.0.so.0', 'libgstreamer-1.0.so']);
    final hasGstBase =
        _canLoadAny(['libgstbase-1.0.so.0', 'libgstbase-1.0.so']);
    if (!(hasGstreamer && hasGstBase)) {
      missing.add(LinuxDependency.audio);
    }

    return LinuxDependencyReport(
      missing: missing,
      family: family,
      distroId: osRelease.id,
    );
  }

  static bool _canLoadAny(List<String> names) {
    for (final name in names) {
      try {
        DynamicLibrary.open(name);
        return true;
      } catch (_) {}
    }
    return false;
  }

  static Future<_OsRelease> _readOsRelease() async {
    final file = File('/etc/os-release');
    if (!await file.exists()) {
      return const _OsRelease();
    }
    try {
      final lines = await file.readAsLines();
      String? id;
      String? idLike;
      for (final line in lines) {
        if (line.startsWith('ID=')) {
          id = _stripValue(line.substring(3));
        } else if (line.startsWith('ID_LIKE=')) {
          idLike = _stripValue(line.substring(8));
        }
      }
      return _OsRelease(id: id, idLike: idLike);
    } catch (_) {
      return const _OsRelease();
    }
  }

  static LinuxPackageFamily _resolveFamily(_OsRelease osRelease) {
    final tokens = <String>{};
    if (osRelease.id != null && osRelease.id!.isNotEmpty) {
      tokens.add(osRelease.id!.toLowerCase());
    }
    if (osRelease.idLike != null && osRelease.idLike!.isNotEmpty) {
      tokens.addAll(
        osRelease.idLike!
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((token) => token.isNotEmpty),
      );
    }
    if (_matchesAny(tokens, const [
      'ubuntu',
      'debian',
      'linuxmint',
      'pop',
      'elementary',
    ])) {
      return LinuxPackageFamily.debian;
    }
    if (_matchesAny(tokens, const [
      'fedora',
      'rhel',
      'centos',
      'rocky',
      'almalinux',
    ])) {
      return LinuxPackageFamily.fedora;
    }
    if (_matchesAny(tokens, const [
      'arch',
      'manjaro',
      'endeavouros',
    ])) {
      return LinuxPackageFamily.arch;
    }
    if (_matchesAny(tokens, const [
      'suse',
      'opensuse',
      'sles',
    ])) {
      return LinuxPackageFamily.suse;
    }
    return LinuxPackageFamily.unknown;
  }

  static bool _matchesAny(Set<String> tokens, List<String> values) {
    for (final value in values) {
      if (tokens.contains(value)) {
        return true;
      }
    }
    return false;
  }

  static String _stripValue(String value) {
    var trimmed = value.trim();
    if (trimmed.startsWith('"') &&
        trimmed.endsWith('"') &&
        trimmed.length >= 2) {
      trimmed = trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
}

class _OsRelease {
  final String? id;
  final String? idLike;

  const _OsRelease({this.id, this.idLike});
}

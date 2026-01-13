enum LinuxDependency {
  notifications,
  audio,
}

enum LinuxPackageFamily {
  debian,
  fedora,
  arch,
  suse,
  unknown,
}

class LinuxDependencyReport {
  final Set<LinuxDependency> missing;
  final LinuxPackageFamily family;
  final String? distroId;

  const LinuxDependencyReport({
    required this.missing,
    required this.family,
    this.distroId,
  });

  bool get hasIssues => missing.isNotEmpty;

  static const empty = LinuxDependencyReport(
    missing: <LinuxDependency>{},
    family: LinuxPackageFamily.unknown,
  );
}

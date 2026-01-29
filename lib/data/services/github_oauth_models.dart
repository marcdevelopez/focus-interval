class GitHubDeviceFlowData {
  GitHubDeviceFlowData({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresIn,
  });

  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final int interval;
  final int expiresIn;
}

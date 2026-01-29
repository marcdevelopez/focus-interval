import 'github_oauth_models.dart';

class GitHubOAuthService {
  GitHubOAuthService({
    required this.clientId,
    this.timeout = const Duration(minutes: 2),
  });

  final String clientId;
  final Duration timeout;

  Future<GitHubDeviceFlowData> startDeviceFlow() async {
    throw UnsupportedError('GitHub device flow is not supported here.');
  }

  Future<String> pollForAccessToken(GitHubDeviceFlowData flow) async {
    throw UnsupportedError('GitHub device flow is not supported here.');
  }
}

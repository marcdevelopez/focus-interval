class GitHubOAuthService {
  GitHubOAuthService({
    required this.clientId,
    required this.exchangeEndpoint,
    this.timeout = const Duration(minutes: 2),
  });

  final String clientId;
  final Uri exchangeEndpoint;
  final Duration timeout;

  Future<String> authenticateWithLoopback() async {
    throw UnsupportedError('GitHub OAuth loopback is not supported here.');
  }
}

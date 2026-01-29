class GitHubOAuthConfig {
  static const String desktopClientId =
      String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID');

  static const String exchangeEndpoint = String.fromEnvironment(
    'GITHUB_OAUTH_EXCHANGE_ENDPOINT',
    defaultValue:
        'https://us-central1-focus-interval.cloudfunctions.net/githubExchange',
  );
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'github_oauth_models.dart';

class GitHubOAuthService {
  GitHubOAuthService({
    required this.clientId,
    this.timeout = const Duration(minutes: 2),
  });

  final String clientId;
  final Duration timeout;

  Future<GitHubDeviceFlowData> startDeviceFlow() async {
    if (clientId.isEmpty) {
      throw StateError('GitHub OAuth client id is not configured.');
    }

    final response = await http.post(
      Uri.https('github.com', '/login/device/code'),
      headers: const {'Accept': 'application/json'},
      body: {
        'client_id': clientId,
        'scope': 'read:user user:email',
      },
    );

    if (response.statusCode != 200) {
      throw StateError('GitHub device flow failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final deviceCode = data['device_code'] as String?;
    final userCode = data['user_code'] as String?;
    final verificationUri = data['verification_uri'] as String?;
    final interval = data['interval'] as int? ?? 5;
    final expiresIn = data['expires_in'] as int? ?? 900;

    if (deviceCode == null || userCode == null || verificationUri == null) {
      throw StateError('GitHub device flow response was incomplete.');
    }

    final uri = Uri.parse(verificationUri);
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    return GitHubDeviceFlowData(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri: uri,
      interval: interval,
      expiresIn: expiresIn,
    );
  }

  Future<String> pollForAccessToken(GitHubDeviceFlowData flow) async {
    final deadline = DateTime.now().add(Duration(seconds: flow.expiresIn));
    var interval = flow.interval;

    while (DateTime.now().isBefore(deadline)) {
      final response = await http.post(
        Uri.https('github.com', '/login/oauth/access_token'),
        headers: const {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'device_code': flow.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'] as String?;
      if (error == null) {
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          throw StateError('GitHub access token missing.');
        }
        return token;
      }

      if (error == 'authorization_pending') {
        await Future<void>.delayed(Duration(seconds: interval));
        continue;
      }
      if (error == 'slow_down') {
        interval += 5;
        await Future<void>.delayed(Duration(seconds: interval));
        continue;
      }
      if (error == 'access_denied') {
        throw StateError('GitHub authorization was denied.');
      }
      if (error == 'expired_token') {
        throw StateError('GitHub device code expired.');
      }

      throw StateError('GitHub device flow failed: $error');
    }

    throw StateError('GitHub sign-in timed out.');
  }
}

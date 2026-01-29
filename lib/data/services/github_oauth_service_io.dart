import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

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
    if (clientId.isEmpty) {
      throw StateError('GitHub OAuth client id is not configured.');
    }

    const port = 51289;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final redirectUri = Uri.parse('http://127.0.0.1:$port/oauth');
    final state = const Uuid().v4();

    final authUri = Uri.https(
      'github.com',
      '/login/oauth/authorize',
      {
        'client_id': clientId,
        'redirect_uri': redirectUri.toString(),
        'scope': 'read:user user:email',
        'state': state,
      },
    );

    if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
      await server.close(force: true);
      throw StateError('Unable to open the browser for GitHub sign-in.');
    }

    try {
      final request = await server.first.timeout(timeout);
      if (request.uri.path != '/oauth') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        throw StateError('Invalid OAuth callback path.');
      }

      final code = request.uri.queryParameters['code'];
      final returnedState = request.uri.queryParameters['state'];
      if (code == null || returnedState == null || returnedState != state) {
        await _respondWithMessage(request.response, success: false);
        throw StateError('Invalid OAuth state or code.');
      }

      await _respondWithMessage(request.response, success: true);
      final token = await _exchangeCode(code, redirectUri);
      return token;
    } on TimeoutException {
      throw StateError('GitHub sign-in timed out.');
    } finally {
      await server.close(force: true);
    }
  }

  Future<String> _exchangeCode(String code, Uri redirectUri) async {
    final response = await http.post(
      exchangeEndpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'redirectUri': redirectUri.toString(),
      }),
    );

    if (response.statusCode != 200) {
      throw StateError('GitHub exchange failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('GitHub access token missing.');
    }
    return token;
  }

  Future<void> _respondWithMessage(
    HttpResponse response, {
    required bool success,
  }) async {
    response.headers.contentType = ContentType.html;
    response.write('''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Focus Interval</title></head>
<body>
<h3>${success ? 'Sign-in completed' : 'Sign-in failed'}</h3>
<p>You can close this window and return to the app.</p>
</body>
</html>
''');
    await response.close();
  }
}

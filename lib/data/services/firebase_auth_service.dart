import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

import 'github_oauth_config.dart';
import 'github_oauth_models.dart';
import 'github_oauth_service.dart';

/// Authentication service.
/// Implements Google Sign-In for Android/iOS/Web and email/password everywhere.
abstract class AuthService {
  User? get currentUser;
  bool get isSignedIn;
  bool get isEmailVerified;
  bool get requiresEmailVerification;
  bool get isGitHubSignInSupported;
  bool get isGitHubDesktopOAuthSupported;
  Stream<User?> get authStateChanges;
  Stream<User?> get userChanges;

  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithGitHub();
  Future<UserCredential> linkWithCredential(AuthCredential credential);
  Future<UserCredential> linkWithGitHubProvider();
  Future<GitHubDeviceFlowData> startGitHubDeviceFlow();
  Future<UserCredential> completeGitHubDeviceFlow(GitHubDeviceFlowData flow);
  Future<UserCredential> linkWithGitHubDeviceFlow(GitHubDeviceFlowData flow);

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> reloadCurrentUser();

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Stream<User?> get userChanges => _auth.userChanges();

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  bool get isGitHubSignInSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  bool get isGitHubDesktopOAuthSupported =>
      _isDesktop && GitHubOAuthConfig.desktopClientId.isNotEmpty;

  @override
  bool get requiresEmailVerification {
    final user = _auth.currentUser;
    if (user == null) return false;
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!hasPasswordProvider) return false;
    return !user.emailVerified;
  }

  bool get _isGoogleSignInSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (!_isGoogleSignInSupported) {
      throw UnsupportedError(
        'Google Sign-In is not available on this platform; use email/password.',
      );
    }

    final googleUser = await _google.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'The user canceled sign-in.',
      );
    }

    final auth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithGitHub() async {
    if (!isGitHubSignInSupported) {
      throw UnsupportedError(
        'GitHub Sign-In is not available on this platform.',
      );
    }

    final provider = GithubAuthProvider();
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to link credentials.');
    }
    return user.linkWithCredential(credential);
  }

  @override
  Future<UserCredential> linkWithGitHubProvider() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to link credentials.');
    }

    final provider = GithubAuthProvider();
    if (kIsWeb) {
      return user.linkWithPopup(provider);
    }
    return user.linkWithProvider(provider);
  }

  @override
  Future<GitHubDeviceFlowData> startGitHubDeviceFlow() async {
    if (!isGitHubDesktopOAuthSupported) {
      throw UnsupportedError('GitHub device flow is not supported here.');
    }
    final clientId = GitHubOAuthConfig.desktopClientId;
    final oauth = GitHubOAuthService(clientId: clientId);
    return oauth.startDeviceFlow();
  }

  @override
  Future<UserCredential> completeGitHubDeviceFlow(
    GitHubDeviceFlowData flow,
  ) async {
    if (!isGitHubDesktopOAuthSupported) {
      throw UnsupportedError('GitHub device flow is not supported here.');
    }
    final clientId = GitHubOAuthConfig.desktopClientId;
    final oauth = GitHubOAuthService(clientId: clientId);
    final token = await oauth.pollForAccessToken(flow);
    final credential = GithubAuthProvider.credential(token);
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> linkWithGitHubDeviceFlow(
    GitHubDeviceFlowData flow,
  ) async {
    if (!isGitHubDesktopOAuthSupported) {
      throw UnsupportedError('GitHub device flow is not supported here.');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to link credentials.');
    }
    final clientId = GitHubOAuthConfig.desktopClientId;
    final oauth = GitHubOAuthService(clientId: clientId);
    final token = await oauth.pollForAccessToken(flow);
    final credential = GithubAuthProvider.credential(token);
    return user.linkWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_isGoogleSignInSupported) {
      await _google.signOut();
    }
  }
}

/// Stub implementation to avoid crashes if called without configuring Firebase.
class StubAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  bool get isEmailVerified => false;

  @override
  bool get requiresEmailVerification => false;

  @override
  bool get isGitHubSignInSupported => false;

  @override
  bool get isGitHubDesktopOAuthSupported => false;

  @override
  Future<GitHubDeviceFlowData> startGitHubDeviceFlow() {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> completeGitHubDeviceFlow(GitHubDeviceFlowData flow) {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> linkWithGitHubDeviceFlow(GitHubDeviceFlowData flow) {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Stream<User?> get userChanges => const Stream.empty();

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> signInWithGitHub() {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> linkWithGitHubProvider() {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<void> reloadCurrentUser() async {
    throw UnsupportedError(
      'Firebase Auth is not configured. Set credentials before using it.',
    );
  }

  @override
  Future<void> signOut() async {}
}

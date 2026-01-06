import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication service.
/// Implements Google Sign-In for supported platforms (not macOS desktop)
/// and email/password for all (especially macOS).
abstract class AuthService {
  User? get currentUser;
  bool get isSignedIn;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithGoogle();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });

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

  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS && !kIsWeb;

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (_isMacOS) {
      throw UnsupportedError(
        'Google Sign-In is not available on macOS; use email/password.',
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
  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}

/// Stub implementation to avoid crashes if called without configuring Firebase.
class StubAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential> signInWithGoogle() {
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
  Future<void> signOut() async {}
}

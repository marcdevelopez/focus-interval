import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación.
/// Implementa Google Sign-In para plataformas soportadas (no macOS desktop)
/// y email/password para todas (especialmente macOS).
abstract class AuthService {
  User? get currentUser;
  bool get isSignedIn;

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

  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS && !kIsWeb;

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (_isMacOS) {
      throw UnsupportedError(
        'Google Sign-In no está disponible en macOS; usa email/password.',
      );
    }

    final googleUser = await _google.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'El usuario canceló el inicio de sesión.',
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

/// Implementación stub para evitar crashes si se llama sin configurar Firebase.
class StubAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnsupportedError(
      'Firebase Auth no está configurado. Configura credenciales antes de usarlo.',
    );
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      'Firebase Auth no está configurado. Configura credenciales antes de usarlo.',
    );
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      'Firebase Auth no está configurado. Configura credenciales antes de usarlo.',
    );
  }

  @override
  Future<void> signOut() async {}
}

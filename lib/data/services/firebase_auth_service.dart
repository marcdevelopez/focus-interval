import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación.
/// Para producción, reemplazar la implementación Stub con la real
/// cuando se configure Firebase (fase 6 en adelante).
abstract class AuthService {
  User? get currentUser;
  bool get isSignedIn;

  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
}

/// Implementación real (Google Sign-In) — aún no configurada.
/// No se utiliza hasta que tengamos credenciales.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Future<UserCredential> signInWithGoogle() async {
    // Nota: requiere configuración de Google Sign-In (fase 6 real).
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
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
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
  Future<void> signOut() async {}
}

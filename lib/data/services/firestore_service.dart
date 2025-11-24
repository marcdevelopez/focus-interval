import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstracción de Firestore para facilitar pruebas e inyección.
abstract class FirestoreService {
  FirebaseFirestore get instance;
}

class FirebaseFirestoreService implements FirestoreService {
  @override
  FirebaseFirestore get instance => FirebaseFirestore.instance;
}

class StubFirestoreService implements FirestoreService {
  @override
  FirebaseFirestore get instance => throw UnsupportedError(
        'Firestore no está configurado. Configura credenciales antes de usarlo.',
      );
}

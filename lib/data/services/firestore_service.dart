import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore abstraction to ease testing and injection.
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
        'Firestore is not configured. Set credentials before using it.',
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> get changes;
  Future<void> signIn(String email, String password);
  Future<void> signInAnonymously();
  Future<void> signUp(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount({String? password});
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get changes => _auth.authStateChanges();

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<void> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase no devolvió el usuario creado.');
    }
    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'collection': <String, int>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay una sesión activa.');

    if (!user.isAnonymous) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw StateError('Es necesaria la contraseña para eliminar la cuenta.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    }

    await _deleteUserData(user.uid);
    await user.delete();
  }

  Future<void> _deleteUserData(String uid) async {
    final userDocument = _firestore.collection('users').doc(uid);
    while (true) {
      final predictions = await userDocument
          .collection('predictions')
          .limit(400)
          .get();
      final batch = _firestore.batch();
      for (final prediction in predictions.docs) {
        batch.delete(prediction.reference);
      }
      if (predictions.docs.isEmpty) batch.delete(userDocument);
      await batch.commit();
      if (predictions.docs.isEmpty) return;
    }
  }
}

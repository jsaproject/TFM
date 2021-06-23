import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthenticationService {


  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);

  final firestoreInstance = FirebaseFirestore.instance;
  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();



  Future<String> signIn({String email, String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Signed in";
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
  }


  Future<String> signUp({String email, String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      await firestoreInstance.collection("users").doc(email).set(
          {
            'Perro':0,
            'Caballo':0,
            'Elefante':0,
            'Mariposa':0,
            'Gallina':0,
            'Gato':0,
            'Vaca':0,
            'Oveja':0,
            'Araña':0,
            'Ardilla':0
          }).then((value){
        print("Success save new user");
      });
      return "Signed up";
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
  }


  Future<String> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return "Signed out";
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
  }


  User getUser() {
    try {
      return _firebaseAuth.currentUser;
    } on FirebaseAuthException {
      return null;
    }
  }

}
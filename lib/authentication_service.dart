import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthenticationService {

  final FirebaseAnalytics _analytics = FirebaseAnalytics();

  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);

  final firestoreInstance = FirebaseFirestore.instance;


  Stream<User> get authStateChanges => _firebaseAuth.userChanges();



  Future<String> signIn({String email, String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      await _analytics.logLogin(loginMethod: 'email');
      return "Logueado con usuario y contraseña";
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
  }

  Future<String> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
      await _analytics.logLogin(loginMethod: 'anonymous');
      return "Logueado anónimo";
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
        print("Usuario registrado con exito");
      });
      return "Logueado";
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
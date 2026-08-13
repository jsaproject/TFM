import 'package:animalspredictor/welcome_gate.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authService, required this.settings});

  final AuthService? authService;
  final SettingsController settings;
  AuthService get _auth =>
      authService ??
      FirebaseAuthService(FirebaseAuth.instance, FirebaseFirestore.instance);

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _auth.changes,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se ha podido comprobar la sesión. Vuelve a abrir la aplicación.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return snapshot.data == null
          ? SignInPage(authService: _auth)
          : WelcomeGate(
              user: snapshot.data!,
              authService: _auth,
              settings: settings,
            );
    },
  );
}

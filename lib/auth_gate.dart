import 'package:animalspredictor/welcome_gate.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
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
          ? const SignInPage()
          : WelcomeGate(user: snapshot.data!);
    },
  );
}

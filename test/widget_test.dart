import 'package:animalspredictor/sign_in_page.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el acceso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignInPage(authService: _AuthStub())),
    );
    expect(find.text('La granja de Michi'), findsOneWidget);
  });
}

class _AuthStub implements AuthService {
  @override
  Stream<User?> get changes => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signInAnonymously() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount({String? password}) async {}
  @override
  Future<void> signUp(String email, String password) async {}
}

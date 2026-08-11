import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthService {
  bool anonymousSignInCalled = false;

  @override
  Stream<User?> get changes => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signInAnonymously() async => anonymousSignInCalled = true;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signUp(String email, String password) async {}
}

void main() {
  testWidgets('valida el correo y la contraseña', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignInPage(authService: FakeAuthService())),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('permite continuar como invitado', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MaterialApp(home: SignInPage(authService: auth)));
    await tester.tap(find.text('Continuar como invitado'));
    await tester.pump();

    expect(auth.anonymousSignInCalled, isTrue);
  });
}

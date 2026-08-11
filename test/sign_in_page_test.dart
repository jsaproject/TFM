import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthService {
  bool anonymousSignInCalled = false;
  String? signedInEmail;
  String? signedUpEmail;
  String? resetEmail;
  Object? signInError;

  @override
  Stream<User?> get changes => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) async => resetEmail = email;

  @override
  Future<void> signIn(String email, String password) async {
    if (signInError != null) throw signInError!;
    signedInEmail = email;
  }

  @override
  Future<void> signInAnonymously() async => anonymousSignInCalled = true;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp(String email, String password) async =>
      signedUpEmail = email;
}

Widget _app(FakeAuthService auth) =>
    MaterialApp(home: SignInPage(authService: auth));

Future<void> _tapAfterScrolling(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
}

void main() {
  testWidgets('valida el correo y la contraseña', (tester) async {
    await tester.pumpWidget(_app(FakeAuthService()));
    await _tapAfterScrolling(
      tester,
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
    );
    await tester.pump();

    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('inicia sesión con las credenciales introducidas', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'michi@granja.es');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await _tapAfterScrolling(
      tester,
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
    );
    await tester.pump();

    expect(auth.signedInEmail, 'michi@granja.es');
  });

  testWidgets('permite mostrar la contraseña y crear una cuenta', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await _tapAfterScrolling(tester, find.text('Crear una cuenta'));
    await tester.pump();
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.enterText(find.byType(TextFormField).at(0), 'michi@granja.es');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await _tapAfterScrolling(
      tester,
      find.widgetWithText(FilledButton, 'Crear cuenta'),
    );
    await tester.pump();

    expect(auth.signedUpEmail, 'michi@granja.es');
    expect(find.text('Cuenta creada'), findsOneWidget);
  });

  testWidgets('permite continuar como invitado', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await _tapAfterScrolling(tester, find.text('Continuar como invitado'));
    await tester.pump();

    expect(auth.anonymousSignInCalled, isTrue);
  });

  testWidgets('envía el correo de recuperación', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await _tapAfterScrolling(tester, find.text('He olvidado mi contraseña'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'michi@granja.es');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();

    expect(auth.resetEmail, 'michi@granja.es');
    expect(find.textContaining('Hemos enviado un enlace'), findsOneWidget);
  });

  testWidgets('muestra un error accionable de Firebase', (tester) async {
    final auth = FakeAuthService()
      ..signInError = FirebaseAuthException(code: 'network-request-failed');
    await tester.pumpWidget(_app(auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'michi@granja.es');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await _tapAfterScrolling(
      tester,
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
    );
    await tester.pump();

    expect(find.textContaining('No hay conexión a internet'), findsOneWidget);
  });
}

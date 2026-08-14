import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/services/guest_session_service.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthService {
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
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount({String? password}) async {}

  @override
  Future<void> signUp(String email, String password) async =>
      signedUpEmail = email;
}

class _GuestSessionServiceStub implements GuestSessionService {
  var started = false;

  @override
  Future<bool> isActive() async => started;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => started = false;
}

Widget _app(FakeAuthService auth, {_GuestSessionServiceStub? guest}) =>
    MaterialApp(
      home: SignInPage(
        authService: auth,
        guestSessionService: guest ?? _GuestSessionServiceStub(),
      ),
    );

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
      find.widgetWithText(FilledButton, TextosAdulto.accesoBoton),
    );
    await tester.pumpAndSettle();

    expect(find.text(TextosAdulto.correoInvalido), findsOneWidget);
    expect(find.text(TextosAdulto.contrasenaCorta), findsOneWidget);
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
      find.widgetWithText(FilledButton, TextosAdulto.accesoBoton),
    );
    await tester.pump();

    expect(auth.signedInEmail, 'michi@granja.es');
  });

  testWidgets('permite mostrar la contraseña y crear una cuenta', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await _tapAfterScrolling(tester, find.text(TextosAdulto.irARegistro));
    await tester.pump();
    await tester.tap(find.byTooltip(TextosAdulto.mostrarContrasena));
    await tester.enterText(find.byType(TextFormField).at(0), 'michi@granja.es');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await _tapAfterScrolling(
      tester,
      find.widgetWithText(FilledButton, TextosAdulto.registroBoton),
    );
    await tester.pump();

    expect(auth.signedUpEmail, 'michi@granja.es');
    expect(find.text(TextosAdulto.cuentaCreadaTitulo), findsOneWidget);
  });

  testWidgets('permite continuar como invitado', (tester) async {
    final auth = FakeAuthService();
    final guest = _GuestSessionServiceStub();
    await tester.pumpWidget(_app(auth, guest: guest));
    await _tapAfterScrolling(tester, find.text(TextosAdulto.invitadoBoton));
    await tester.pump();

    expect(guest.started, isTrue);
  });

  testWidgets('envía el correo de recuperación', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth));
    await _tapAfterScrolling(tester, find.text(TextosAdulto.olvideContrasena));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'michi@granja.es');
    await tester.tap(find.text(TextosAdulto.recuperarBoton));
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
      find.widgetWithText(FilledButton, TextosAdulto.accesoBoton),
    );
    await tester.pump();

    expect(find.textContaining('No hay conexión a internet'), findsOneWidget);
  });
}

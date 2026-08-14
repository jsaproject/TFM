import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/profile/domain/adult_gate_challenge.dart';
import 'package:animalspredictor/features/profile/presentation/profile_page.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  testWidgets('mantiene los ajustes y el borrado detrás de la puerta adulta', (
    tester,
  ) async {
    final permissions = _PermissionServiceStub();
    final settings = SettingsController(_SettingsRepositoryStub());
    addTearDown(settings.dispose);
    await settings.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: ProfilePage(
          displayName: 'Ana',
          collection: const UserCollection(counts: {'Vaca': 1}),
          email: null,
          isAnonymous: true,
          authService: _AuthServiceStub(),
          settings: settings,
          permissionService: permissions,
          adultGateChallenge: const AdultGateChallenge(
            leftFactor: 12,
            rightFactor: 13,
          ),
        ),
      ),
    );

    expect(find.text('Ana'), findsOneWidget);
    expect(
      find.text(TextosNino.tienesAnimales(1, animalCatalog.length)),
      findsOneWidget,
    );
    expect(find.text(TextosAdulto.eliminarCuenta), findsNothing);
    expect(find.text(TextosAdulto.privacidadTitulo), findsNothing);
    expect(permissions.overviewRequests, 0);

    await tester.enterText(find.byType(TextField), '156');
    final gateSubmit = find.byKey(const Key('adult-gate-submit'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(gateSubmit);
    await tester.pumpAndSettle();

    expect(permissions.overviewRequests, 1);
    expect(find.text(TextosAdulto.perfilTitulo), findsOneWidget);

    final adultList = find.descendant(
      of: find.byType(AdultSettingsPage),
      matching: find.byType(ListView),
    );
    await tester.drag(adultList, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(
      OutlinedButton,
      TextosAdulto.eliminarCuenta,
    );
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text(TextosAdulto.eliminarCuentaCasilla), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('cerrar sesión vuelve a la primera ruta', (tester) async {
    final auth = _AuthServiceStub();
    await _openAdultSettings(tester, auth);

    final signOutButton = find.widgetWithText(
      FilledButton,
      TextosAdulto.cerrarSesion,
    );
    await _scrollToAction(tester, signOutButton);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(find.text(_rootRouteText), findsOneWidget);
    expect(find.byType(AdultSettingsPage), findsNothing);
  });

  testWidgets('eliminar una cuenta invitada vuelve a la primera ruta', (
    tester,
  ) async {
    final auth = _AuthServiceStub();
    await _openAdultSettings(tester, auth);

    final deleteButton = find.widgetWithText(
      OutlinedButton,
      TextosAdulto.eliminarCuenta,
    );
    await _scrollToAction(tester, deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, TextosAdulto.eliminarCuentaBoton),
    );
    await tester.pumpAndSettle();

    expect(auth.deleteAccountCalls, 1);
    expect(auth.deletedWithPassword, isNull);
    expect(find.text(_rootRouteText), findsOneWidget);
    expect(find.byType(AdultSettingsPage), findsNothing);
  });

  testWidgets('eliminar una cuenta registrada conserva la reautenticación', (
    tester,
  ) async {
    final auth = _AuthServiceStub();
    await _openAdultSettings(
      tester,
      auth,
      isAnonymous: false,
      email: 'ana@example.com',
    );

    final deleteButton = find.widgetWithText(
      OutlinedButton,
      TextosAdulto.eliminarCuenta,
    );
    await _scrollToAction(tester, deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secreto');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, TextosAdulto.eliminarCuentaBoton),
    );
    await tester.pumpAndSettle();

    expect(auth.deleteAccountCalls, 1);
    expect(auth.deletedWithPassword, 'secreto');
    expect(find.text(_rootRouteText), findsOneWidget);
    expect(find.byType(AdultSettingsPage), findsNothing);
  });
}

const _rootRouteText = 'Pantalla de acceso de prueba';

Future<void> _openAdultSettings(
  WidgetTester tester,
  AuthService authService, {
  bool isAnonymous = true,
  String? email,
}) async {
  final settings = SettingsController(_SettingsRepositoryStub());
  addTearDown(settings.dispose);
  await settings.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: MichiTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AdultSettingsPage(
                    email: email,
                    isAnonymous: isAnonymous,
                    authService: authService,
                    settings: settings,
                    permissionService: _PermissionServiceStub(),
                  ),
                ),
              ),
              child: const Text(_rootRouteText),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(_rootRouteText));
  await tester.pumpAndSettle();
}

Future<void> _scrollToAction(WidgetTester tester, Finder action) async {
  final scrollable = find.descendant(
    of: find.byType(AdultSettingsPage),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(action, 500, scrollable: scrollable);
  await tester.pumpAndSettle();
}

class _PermissionServiceStub implements PermissionService {
  var overviewRequests = 0;

  @override
  Future<PermissionOverview> getOverview() async {
    overviewRequests++;
    return const PermissionOverview(
      camera: AppPermissionStatus.granted,
      photos: AppPermissionStatus.granted,
    );
  }

  @override
  Future<bool> openSettings() async => true;
}

class _SettingsRepositoryStub implements SettingsRepository {
  @override
  Future<ProfileSettings> load() async => const ProfileSettings();

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {}

  @override
  Future<void> saveSoundEnabled(bool enabled) async {}

  @override
  Future<void> saveTheme(AppThemePreference theme) async {}
}

class _AuthServiceStub implements AuthService {
  var signOutCalls = 0;
  var deleteAccountCalls = 0;
  String? deletedWithPassword;

  @override
  Stream<User?> get changes => const Stream<User?>.empty();

  @override
  Future<void> deleteAccount({String? password}) async {
    deleteAccountCalls++;
    deletedWithPassword = password;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<void> signUp(String email, String password) async {}
}

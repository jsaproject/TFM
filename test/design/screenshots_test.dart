@Tags(['design'])
library;

import 'dart:io';

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/profile/presentation/profile_page.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Retrata las pantallas para poder mirarlas: no es una prueba de regresion,
/// es una forma de ver el diseno sin un movil delante.
///
/// Se ejecuta a mano:
///
///   MICHI_DESIGN=1 flutter test test/design --update-goldens
///
/// y las imagenes salen en test/design/goldens/, que no se versiona: cada
/// maquina pinta las fuentes un poco distinto y compararlas no aportaria nada.
/// En una pasada normal de `flutter test` estas pruebas se saltan.
void main() {
  final habilitado = Platform.environment['MICHI_DESIGN'] == '1';
  setUpAll(() async {
    await _loadAppFonts();
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget page, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MichiTheme.light(),
        home: page,
      ),
    );
    // Las imagenes solo se decodifican fuera del reloj falso del test.
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget as Image;
        await precacheImage(imagen.image, elemento);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets(skip: !habilitado, 'acceso', (tester) async {
    await shoot(tester, '01-acceso', SignInPage(authService: _Auth()));
  });

  testWidgets(skip: !habilitado, 'inicio sin foto', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final settings = await _settings(tester);
    await shoot(
      tester,
      '02-inicio',
      ClassifierPage(
        controller: controller,
        settings: settings,
        collection: const UserCollection(counts: {'Vaca': 2, 'Gato': 1}),
        greetingName: 'Ana',
        onConfirmPrediction: (_) async => const Celebration(animal: 'Vaca'),
      ),
    );
  });

  testWidgets(skip: !habilitado, 'coleccion', (tester) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '03-coleccion',
      Scaffold(
        body: CollectionPage(
          userId: 'u1',
          isAnonymous: false,
          settings: settings,
          repository: _Repository(),
          onStartIdentifying: () {},
        ),
      ),
    );
  });

  testWidgets(skip: !habilitado, 'perfil', (tester) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '04-perfil',
      ProfilePage(
        displayName: 'Ana',
        collection: const UserCollection(counts: {'Vaca': 2, 'Gato': 1}),
        email: 'ana@granja.es',
        isAnonymous: false,
        authService: _Auth(),
        settings: settings,
        permissionService: _Permissions(),
      ),
    );
  });
}

Future<SettingsController> _settings(WidgetTester tester) async {
  final settings = SettingsController(_SettingsRepository());
  addTearDown(settings.dispose);
  await settings.load();
  return settings;
}

ClassifierController _controller() =>
    ClassifierController(classifier: _Classifier(), photoPicker: _Picker());

Future<void> _loadAppFonts() async {
  const familias = {
    'Andika': [
      'assets/fonts/Andika-Regular.ttf',
      'assets/fonts/Andika-Bold.ttf',
    ],
    'Atkinson Hyperlegible': [
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
      'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    ],
  };
  final iconos = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconos.load();
  for (final entrada in familias.entries) {
    final loader = FontLoader(entrada.key);
    for (final ruta in entrada.value) {
      loader.addFont(rootBundle.load(ruta));
    }
    await loader.load();
  }
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<ProfileSettings> load() async => const ProfileSettings();
  @override
  Future<void> saveHapticsEnabled(bool enabled) async {}
  @override
  Future<void> saveSoundEnabled(bool enabled) async {}
  @override
  Future<void> saveTheme(AppThemePreference theme) async {}
}

class _Permissions implements PermissionService {
  @override
  Future<PermissionOverview> getOverview() async => const PermissionOverview(
    camera: AppPermissionStatus.granted,
    photos: AppPermissionStatus.granted,
  );
  @override
  Future<bool> openSettings() async => true;
}

class _Auth implements AuthService {
  @override
  Stream<User?> get changes => const Stream<User?>.empty();
  @override
  Future<void> deleteAccount({String? password}) async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signUp(String email, String password) async {}
}

class _Repository implements CollectionRepository {
  final _collection = UserCollection(
    counts: const {'Vaca': 3, 'Gato': 1, 'Perro': 2},
    lastIdentified: {'Vaca': DateTime(2026, 8, 12)},
  );

  @override
  Future<void> markAchievementsSeen(String uid, Iterable<String> ids) async {}

  @override
  Future<void> savePrediction(String uid, String animal) async {}
  @override
  Future<void> updatePrediction(
    String uid,
    CollectionPrediction prediction,
    String? animal,
  ) async {}
  @override
  Stream<UserCollection> watch(String uid) =>
      Stream<UserCollection>.value(_collection);
  @override
  Stream<List<CollectionPrediction>> watchPredictions(String uid) =>
      Stream<List<CollectionPrediction>>.value(const [
        CollectionPrediction(id: 'p1', animal: 'Vaca'),
      ]);
}

class _Picker implements PhotoPickerService {
  @override
  Future<PickedPhoto?> pick(ImageSource source) async =>
      PickedPhoto(path: '/tmp/a.jpg', bytes: Uint8List.fromList([1, 2, 3]));
}

class _Classifier implements ClassifierService {
  @override
  Future<ClassificationResult> classify(String imagePath) async =>
      ClassificationResult(
        primary: const Prediction(animal: 'Vaca', confidence: 0.92),
        alternatives: const [Prediction(animal: 'Caballo', confidence: 0.04)],
      );
  @override
  Future<void> dispose() async {}
  @override
  Future<void> load() async {}
}

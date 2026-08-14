@Tags(['design'])
library;

import 'dart:async';
import 'dart:io';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/animal_detail_page.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/features/collection/presentation/collection_history_page.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/profile/domain/adult_gate_challenge.dart';
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

/// Capturas manuales de los estados de la fase 1.
///
/// No usa un móvil ni servicios reales: todo el contenido procede de dobles
/// locales. Se ejecuta bajo demanda con:
///
///   MICHI_DESIGN=1 flutter test test/design --update-goldens
void main() {
  final enabled = Platform.environment['MICHI_DESIGN'] == '1';

  setUpAll(_loadAppFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget page, {
    Future<void> Function(WidgetTester tester)? arrange,
    bool settleAfterArrange = true,
    bool settleInitial = true,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
    TextScaler? textScaler,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MichiTheme.light(),
        darkTheme: MichiTheme.dark(),
        themeMode: themeMode,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: textScaler == null
                ? mediaQuery
                : mediaQuery.copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: page,
      ),
    );
    if (settleInitial) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(seconds: 1));
    }
    if (arrange != null) {
      await arrange(tester);
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          final image = element.widget as Image;
          await precacheImage(image.image, element);
        }
      });
      if (settleAfterArrange) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/fase1/$name.png'),
    );
  }

  testWidgets(skip: !enabled, 'procesando una foto', (tester) async {
    final classifier = _PendingClassifier();
    final controller = _controller(classifier: classifier);
    addTearDown(controller.dispose);
    final settings = await _settings(tester);
    Future<void>? classifying;

    await shoot(
      tester,
      '05-procesando',
      _classifierPage(controller: controller, settings: settings),
      arrange: (_) {
        classifying = controller.selectAndClassifyPhoto(ImageSource.camera);
        return Future<void>.value();
      },
      settleAfterArrange: false,
    );

    classifier.complete(_reliableResult);
    await classifying;
    await tester.pumpAndSettle();
  });

  testWidgets(skip: !enabled, 'resultado reconocido', (tester) async {
    final controller = _controller(
      classifier: _ResultClassifier(_reliableResult),
    );
    addTearDown(controller.dispose);
    final settings = await _settings(tester);

    await shoot(
      tester,
      '06-resultado-reconocido',
      _classifierPage(controller: controller, settings: settings),
      arrange: (_) => controller.selectAndClassifyPhoto(ImageSource.camera),
    );
  });

  testWidgets(skip: !enabled, 'resultado incierto', (tester) async {
    final controller = _controller(
      classifier: _ResultClassifier(_uncertainResult),
    );
    addTearDown(controller.dispose);
    final settings = await _settings(tester);

    await shoot(
      tester,
      '07-resultado-incierto',
      _classifierPage(controller: controller, settings: settings),
      arrange: (_) => controller.selectAndClassifyPhoto(ImageSource.camera),
    );
  });

  testWidgets(skip: !enabled, 'error al identificar', (tester) async {
    final controller = _controller(classifier: _ThrowingClassifier());
    addTearDown(controller.dispose);
    final settings = await _settings(tester);

    await shoot(
      tester,
      '08-error-identificacion',
      _classifierPage(controller: controller, settings: settings),
      arrange: (_) => controller.selectAndClassifyPhoto(ImageSource.camera),
    );
  });

  testWidgets(skip: !enabled, 'coleccion vacia', (tester) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '09-coleccion-vacia',
      Scaffold(
        body: CollectionPage(
          userId: 'fase1',
          isAnonymous: true,
          repository: _Repository(collection: const UserCollection()),
          settings: settings,
          onStartIdentifying: () {},
        ),
      ),
    );
  });

  testWidgets(skip: !enabled, 'coleccion con error', (tester) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '10-coleccion-error',
      Scaffold(
        body: CollectionPage(
          userId: 'fase1',
          isAnonymous: true,
          repository: _Repository(error: StateError('fallo simulado')),
          settings: settings,
          onStartIdentifying: () {},
        ),
      ),
    );
  });

  testWidgets(skip: !enabled, 'ajustes de invitado', (tester) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '11-ajustes-invitado',
      AdultSettingsPage(
        email: null,
        isAnonymous: true,
        authService: _Auth(),
        settings: settings,
        permissionService: _Permissions(),
      ),
    );
  });

  testWidgets(skip: !enabled, 'permiso de camara denegado', (tester) async {
    final controller = _controller(
      classifier: _ResultClassifier(_reliableResult),
      picker: const _PermissionPicker('Déjame usar la cámara.'),
    );
    addTearDown(controller.dispose);
    final settings = await _settings(tester);

    await shoot(
      tester,
      '12-permiso-denegado',
      _classifierPage(controller: controller, settings: settings),
      arrange: (_) => controller.selectAndClassifyPhoto(ImageSource.camera),
    );
  });

  testWidgets(skip: !enabled, 'historial', (tester) async {
    final repository = _populatedRepository();
    await shoot(
      tester,
      '13-historial',
      CollectionHistoryPage(
        repository: repository,
        userId: 'fase1',
        onEdit: (_, _) async {},
      ),
    );
  });

  testWidgets(skip: !enabled, 'detalle de especie', (tester) async {
    final repository = _populatedRepository();
    await shoot(
      tester,
      '14-detalle-especie',
      AnimalDetailPage(
        animal: animalCatalog.first,
        repository: repository,
        userId: 'fase1',
        onEdit: (_, _) async {},
      ),
    );
  });

  testWidgets(skip: !enabled, 'respuesta incorrecta en puerta adulta', (
    tester,
  ) async {
    final settings = await _settings(tester);
    await shoot(
      tester,
      '15-puerta-adulta-error',
      ProfilePage(
        displayName: 'Michi',
        collection: const UserCollection(counts: {'Vaca': 1}),
        email: null,
        isAnonymous: true,
        authService: _Auth(),
        settings: settings,
        permissionService: _Permissions(),
        adultGateChallenge: const AdultGateChallenge(
          leftFactor: 12,
          rightFactor: 12,
        ),
      ),
      arrange: (tester) async {
        await tester.enterText(find.byType(TextField), '1');
        await tester.tap(find.byKey(const Key('adult-gate-submit')));
      },
    );
  });

  testWidgets(skip: !enabled, 'matriz de inicio', (tester) async {
    const sizes = <String, Size>{
      '320x568': Size(320, 568),
      '360x640': Size(360, 640),
      '390x844': Size(390, 844),
      '430x932': Size(430, 932),
      '768x1024': Size(768, 1024),
      '1180x820': Size(1180, 820),
    };
    const variants = <String, (ThemeMode, TextScaler?)>{
      'claro-100': (ThemeMode.light, null),
      'claro-200': (ThemeMode.light, TextScaler.linear(2)),
      'oscuro-100': (ThemeMode.dark, null),
      'oscuro-200': (ThemeMode.dark, TextScaler.linear(2)),
    };

    for (final size in sizes.entries) {
      for (final variant in variants.entries) {
        final controller = _controller(
          classifier: _ResultClassifier(_reliableResult),
        );
        addTearDown(controller.dispose);
        final settings = await _settings(tester);
        await shoot(
          tester,
          'matriz/inicio-${size.key}-${variant.key}',
          _classifierPage(controller: controller, settings: settings),
          size: size.value,
          themeMode: variant.value.$1,
          textScaler: variant.value.$2,
          settleInitial: false,
        );
      }
    }
  });

  testWidgets(skip: !enabled, 'matriz de coleccion y perfil', (tester) async {
    const sizes = <String, Size>{
      '320x568': Size(320, 568),
      '360x640': Size(360, 640),
      '390x844': Size(390, 844),
      '430x932': Size(430, 932),
      '768x1024': Size(768, 1024),
      '1180x820': Size(1180, 820),
    };
    const variants = <String, (ThemeMode, TextScaler?)>{
      'claro-100': (ThemeMode.light, null),
      'claro-200': (ThemeMode.light, TextScaler.linear(2)),
      'oscuro-100': (ThemeMode.dark, null),
      'oscuro-200': (ThemeMode.dark, TextScaler.linear(2)),
    };

    for (final size in sizes.entries) {
      for (final variant in variants.entries) {
        final collectionSettings = await _settings(tester);
        await shoot(
          tester,
          'matriz/coleccion-${size.key}-${variant.key}',
          Scaffold(
            body: CollectionPage(
              userId: 'fase1',
              isAnonymous: true,
              repository: _populatedRepository(),
              settings: collectionSettings,
              onStartIdentifying: () {},
            ),
          ),
          size: size.value,
          themeMode: variant.value.$1,
          textScaler: variant.value.$2,
          settleInitial: false,
        );

        final profileSettings = await _settings(tester);
        await shoot(
          tester,
          'matriz/perfil-${size.key}-${variant.key}',
          ProfilePage(
            displayName: 'Michi',
            collection: const UserCollection(counts: {'Vaca': 1}),
            email: null,
            isAnonymous: true,
            authService: _Auth(),
            settings: profileSettings,
            permissionService: _Permissions(),
            adultGateChallenge: const AdultGateChallenge(
              leftFactor: 12,
              rightFactor: 12,
            ),
          ),
          size: size.value,
          themeMode: variant.value.$1,
          textScaler: variant.value.$2,
          settleInitial: false,
        );
      }
    }
  });

  testWidgets(skip: !enabled, 'matriz de acceso y resultado', (tester) async {
    const sizes = <String, Size>{
      '320x568': Size(320, 568),
      '360x640': Size(360, 640),
      '390x844': Size(390, 844),
      '430x932': Size(430, 932),
      '768x1024': Size(768, 1024),
      '1180x820': Size(1180, 820),
    };
    const variants = <String, (ThemeMode, TextScaler?)>{
      'claro-100': (ThemeMode.light, null),
      'claro-200': (ThemeMode.light, TextScaler.linear(2)),
      'oscuro-100': (ThemeMode.dark, null),
      'oscuro-200': (ThemeMode.dark, TextScaler.linear(2)),
    };

    for (final size in sizes.entries) {
      for (final variant in variants.entries) {
        await shoot(
          tester,
          'matriz/acceso-${size.key}-${variant.key}',
          SignInPage(authService: _Auth()),
          size: size.value,
          themeMode: variant.value.$1,
          textScaler: variant.value.$2,
          settleInitial: false,
        );

        final controller = _controller(
          classifier: _ResultClassifier(_reliableResult),
        );
        addTearDown(controller.dispose);
        final settings = await _settings(tester);
        await shoot(
          tester,
          'matriz/resultado-${size.key}-${variant.key}',
          _classifierPage(controller: controller, settings: settings),
          arrange: (_) => controller.selectAndClassifyPhoto(ImageSource.camera),
          size: size.value,
          themeMode: variant.value.$1,
          textScaler: variant.value.$2,
          settleInitial: false,
        );
      }
    }
  });

  testWidgets('semantica y foco de las acciones principales', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = _controller(
      classifier: _ResultClassifier(_reliableResult),
    );
    addTearDown(controller.dispose);
    final settings = await _settings(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: _classifierPage(controller: controller, settings: settings),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('classifier-primary-cta')),
      300,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('classifier-primary-cta'))),
      matchesSemantics(
        label: 'Haz una foto',
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('classifier-gallery-cta')),
      300,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('classifier-gallery-cta'))),
      matchesSemantics(
        label: 'De mis fotos',
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: ProfilePage(
          displayName: 'Michi',
          collection: const UserCollection(counts: {'Vaca': 1}),
          email: null,
          isAnonymous: true,
          authService: _Auth(),
          settings: settings,
          permissionService: _Permissions(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solo para adultos'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _classifierPage({
  required ClassifierController controller,
  required SettingsController settings,
}) => ClassifierPage(
  controller: controller,
  settings: settings,
  collection: const UserCollection(counts: {'Vaca': 2, 'Gato': 1}),
  greetingName: 'Ana',
  onConfirmPrediction: (_) async => const Celebration(animal: 'Vaca'),
);

ClassifierController _controller({
  required ClassifierService classifier,
  PhotoPickerService picker = const _Picker(),
}) => ClassifierController(classifier: classifier, photoPicker: picker);

_Repository _populatedRepository() => _Repository(
  collection: UserCollection(
    counts: const {'Vaca': 2, 'Caballo': 1},
    lastIdentified: {'Vaca': DateTime(2026, 8, 14)},
  ),
  predictions: [
    CollectionPrediction(
      id: 'foto-vaca',
      animal: 'Vaca',
      createdAt: DateTime(2026, 8, 14),
    ),
    CollectionPrediction(
      id: 'foto-caballo',
      animal: 'Caballo',
      createdAt: DateTime(2026, 8, 13),
    ),
  ],
);

final _reliableResult = ClassificationResult(
  primary: Prediction(animal: 'Vaca', confidence: 0.92),
  alternatives: [Prediction(animal: 'Caballo', confidence: 0.04)],
);

final _uncertainResult = ClassificationResult(
  primary: Prediction(animal: 'Vaca', confidence: 0.24),
  alternatives: [Prediction(animal: 'Caballo', confidence: 0.18)],
);

Future<SettingsController> _settings(WidgetTester tester) async {
  final settings = SettingsController(_SettingsRepository());
  addTearDown(settings.dispose);
  await settings.load();
  return settings;
}

Future<void> _loadAppFonts() async {
  const families = {
    'Andika': [
      'assets/fonts/Andika-Regular.ttf',
      'assets/fonts/Andika-Bold.ttf',
    ],
    'Atkinson Hyperlegible': [
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
      'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    ],
  };
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}

class _Picker implements PhotoPickerService {
  const _Picker();

  @override
  Future<PickedPhoto?> pick(ImageSource source) async {
    final image = await rootBundle.load('assets/vaca.jpg');
    return PickedPhoto(
      path: '/tmp/fase1.jpg',
      bytes: image.buffer.asUint8List(image.offsetInBytes, image.lengthInBytes),
    );
  }
}

class _PermissionPicker implements PhotoPickerService {
  const _PermissionPicker(this.message);

  final String message;

  @override
  Future<PickedPhoto?> pick(ImageSource source) =>
      Future<PickedPhoto?>.error(PhotoPermissionDenied(message));
}

class _ResultClassifier implements ClassifierService {
  const _ResultClassifier(this.result);

  final ClassificationResult result;

  @override
  Future<ClassificationResult> classify(String imagePath) async => result;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}
}

class _ThrowingClassifier implements ClassifierService {
  @override
  Future<ClassificationResult> classify(String imagePath) =>
      Future<ClassificationResult>.error(StateError('fallo simulado'));

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}
}

class _PendingClassifier implements ClassifierService {
  final _result = Completer<ClassificationResult>();

  @override
  Future<ClassificationResult> classify(String imagePath) => _result.future;

  void complete(ClassificationResult result) => _result.complete(result);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}
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
  _Repository({this.collection, this.error, this.predictions = const []});

  final UserCollection? collection;
  final Object? error;
  final List<CollectionPrediction> predictions;

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
  Stream<UserCollection> watch(String uid) => error == null
      ? Stream<UserCollection>.value(collection ?? const UserCollection())
      : Stream<UserCollection>.error(error!);

  @override
  Stream<List<CollectionPrediction>> watchPredictions(String uid) =>
      Stream<List<CollectionPrediction>>.value(predictions);
}

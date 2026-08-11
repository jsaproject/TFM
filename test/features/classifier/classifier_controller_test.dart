import 'dart:typed_data';

import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('conserva la cancelación como un estado listo y explicativo', () async {
    final controller = ClassifierController(
      classifier: _FakeClassifier(),
      photoPicker: _FakePhotoPicker(),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.selectPhoto(ImageSource.camera);

    expect(controller.state.status, ClassifierStatus.ready);
    expect(
      controller.state.noticeMessage,
      'No se ha seleccionado ninguna imagen.',
    );
  });

  test('muestra alternativas tras identificar una foto fiable', () async {
    final controller = ClassifierController(
      classifier: _FakeClassifier(),
      photoPicker: _FakePhotoPicker(photo: _photo),
    );
    addTearDown(controller.dispose);

    await controller.load();
    await controller.selectPhoto(ImageSource.gallery);
    expect(controller.state.status, ClassifierStatus.previewing);

    await controller.classifySelectedPhoto();

    expect(controller.state.status, ClassifierStatus.success);
    expect(controller.state.prediction?.animal, 'Vaca');
    expect(controller.state.result?.alternatives.single.animal, 'Caballo');
  });

  test(
    'no presenta una confianza baja como una identificación fiable',
    () async {
      final controller = ClassifierController(
        classifier: _FakeClassifier(
          result: ClassificationResult(
            primary: const Prediction(animal: 'Vaca', confidence: 0.42),
            alternatives: const [],
          ),
        ),
        photoPicker: _FakePhotoPicker(photo: _photo),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectPhoto(ImageSource.camera);
      await controller.classifySelectedPhoto();

      expect(controller.state.status, ClassifierStatus.unrecognized);
    },
  );

  test(
    'expone permiso denegado y permite reintentar un fallo de clasificación',
    () async {
      final classifier = _FakeClassifier(error: StateError('sin conexión'));
      final controller = ClassifierController(
        classifier: classifier,
        photoPicker: _FakePhotoPicker(photo: _photo),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.selectPhoto(ImageSource.gallery);
      await controller.classifySelectedPhoto();

      expect(controller.state.canRetryClassification, isTrue);
      expect(controller.state.image, isNotNull);

      classifier.error = null;
      await controller.classifySelectedPhoto();
      expect(controller.state.status, ClassifierStatus.success);

      final permissionController = ClassifierController(
        classifier: _FakeClassifier(),
        photoPicker: _FakePhotoPicker(
          error: const PhotoPermissionDenied('Activa el permiso de cámara.'),
        ),
      );
      addTearDown(permissionController.dispose);
      await permissionController.load();
      await permissionController.selectPhoto(ImageSource.camera);

      expect(permissionController.state.status, ClassifierStatus.error);
      expect(permissionController.state.permissionDenied, isTrue);
    },
  );

  testWidgets('guía la selección desde el CTA hasta el resultado', (
    tester,
  ) async {
    final controller = ClassifierController(
      classifier: _FakeClassifier(),
      photoPicker: _FakePhotoPicker(photo: _photo),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ClassifierPage(
          controller: controller,
          greetingName: 'Michi',
          isAnonymous: true,
          onConfirmPrediction: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hola, Michi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('classifier-primary-cta')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('classifier-primary-cta')));
    await tester.pumpAndSettle();
    expect(find.text('Usar cámara'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);

    await tester.tap(find.text('Elegir de la galería'));
    await tester.pump();
    expect(find.text('Identificar esta foto'), findsOneWidget);

    await tester.tap(find.text('Identificar esta foto'));
    await tester.pump();
    expect(find.text('Resultado de la identificación'), findsOneWidget);
    expect(find.text('Otras posibilidades'), findsOneWidget);
  });
}

final _photo = PickedPhoto(
  path: '/temporal/animal.jpg',
  bytes: Uint8List.fromList([1, 2, 3]),
);

class _FakePhotoPicker implements PhotoPickerService {
  _FakePhotoPicker({this.photo, this.error});

  final PickedPhoto? photo;
  final Object? error;

  @override
  Future<PickedPhoto?> pick(ImageSource source) async {
    if (error != null) throw error!;
    return photo;
  }
}

class _FakeClassifier implements ClassifierService {
  _FakeClassifier({ClassificationResult? result, this.error})
    : result =
          result ??
          ClassificationResult(
            primary: const Prediction(animal: 'Vaca', confidence: 0.92),
            alternatives: const [
              Prediction(animal: 'Caballo', confidence: 0.05),
            ],
          );

  final ClassificationResult result;
  Object? error;

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}
}

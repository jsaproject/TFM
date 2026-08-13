import 'package:animalspredictor/services/classifier_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(TinyClipClassifierService.channelName);
  var rejected = false;
  var indices = <int>[0, 1, 2];
  var scores = <double>[0.85, 0.10, 0.05];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    rejected = false;
    indices = <int>[0, 1, 2];
    scores = <double>[0.85, 0.10, 0.05];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'load':
            case 'dispose':
              return null;
            case 'classify':
              expect(call.arguments, {'imagePath': '/tmp/animal.jpg'});
              return <String, Object>{
                'rejected': rejected,
                'indices': indices,
                'scores': scores,
                'topSimilarity': 0.41,
                'margin': 0.08,
              };
            default:
              throw MissingPluginException(call.method);
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'traduce y valida las tres predicciones devueltas por Android',
    () async {
      final service = TinyClipClassifierService();
      addTearDown(service.dispose);

      await service.load();
      final result = await service.classify('/tmp/animal.jpg');

      expect(result.primary.animal, 'Vaca');
      expect(result.primary.confidence, 0.85);
      expect(result.alternatives.map((prediction) => prediction.animal), [
        'Caballo',
        'Cerdo',
      ]);
      expect(result.reliable, isTrue);
      expect(result.looksLikeSomethingElse, isFalse);
    },
  );

  test(
    'conserva el rechazo calibrado aunque la clase superior sea clara',
    () async {
      rejected = true;
      final service = TinyClipClassifierService();
      addTearDown(service.dispose);

      await service.load();
      final result = await service.classify('/tmp/animal.jpg');

      expect(result.primary.animal, 'Vaca');
      expect(result.reliable, isFalse);
      expect(result.looksLikeSomethingElse, isTrue);
    },
  );

  test('rechaza índices que no pertenecen al catálogo del modelo', () async {
    indices = <int>[99];
    scores = <double>[1];
    final service = TinyClipClassifierService();
    addTearDown(service.dispose);

    await service.load();

    expect(
      () => service.classify('/tmp/animal.jpg'),
      throwsA(isA<StateError>()),
    );
  });
}

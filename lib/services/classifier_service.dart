import 'package:animalspredictor/models/prediction.dart';
import 'package:flutter/foundation.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

abstract class ClassifierService {
  Future<void> load();
  Future<Prediction> classify(String imagePath);
  Future<void> dispose();
}

class TfliteClassifierService implements ClassifierService {
  @override
  Future<void> load() async {
    if (kIsWeb) {
      throw UnsupportedError('La clasificación no está disponible en web.');
    }
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  @override
  Future<Prediction> classify(String imagePath) async {
    final results = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 3,
      threshold: 0,
      imageMean: 0,
      imageStd: 1,
    );
    final result = results?.isEmpty ?? true ? null : results!.first;
    if (result is! Map<dynamic, dynamic> ||
        result['label'] is! String ||
        result['confidence'] is! num) {
      throw StateError('Resultado del modelo inválido');
    }
    return Prediction(
      animal: result['label'] as String,
      confidence: (result['confidence'] as num).toDouble(),
    );
  }

  @override
  Future<void> dispose() async {
    if (!kIsWeb) await Tflite.close();
  }
}

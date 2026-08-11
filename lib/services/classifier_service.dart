import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:flutter/foundation.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

abstract class ClassifierService {
  Future<void> load();
  Future<ClassificationResult> classify(String imagePath);
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
  Future<ClassificationResult> classify(String imagePath) async {
    final results = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 3,
      threshold: 0,
      imageMean: 0,
      imageStd: 1,
    );
    if (results == null || results.isEmpty) {
      throw StateError('Resultado del modelo inválido');
    }

    final predictions = results.map(_toPrediction).toList()
      ..sort((left, right) => right.confidence.compareTo(left.confidence));
    if (predictions.isEmpty) throw StateError('Resultado del modelo inválido');

    return ClassificationResult(
      primary: predictions.first,
      alternatives: predictions.skip(1).toList(),
    );
  }

  Prediction _toPrediction(Object? result) {
    if (result is! Map ||
        result['label'] is! String ||
        result['confidence'] is! num) {
      throw StateError('Resultado del modelo inválido');
    }
    final confidence = (result['confidence'] as num).toDouble();
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw StateError('Confianza del modelo inválida');
    }
    final animal = (result['label'] as String).trim();
    if (!animalByName.containsKey(animal)) {
      throw StateError('Etiqueta del modelo no admitida');
    }
    return Prediction(animal: animal, confidence: confidence);
  }

  @override
  Future<void> dispose() async {
    if (!kIsWeb) await Tflite.close();
  }
}

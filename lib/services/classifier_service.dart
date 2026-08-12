import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:animalspredictor/services/animal_group_mapping.dart';
import 'package:flutter/foundation.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

abstract class ClassifierService {
  Future<void> load();
  Future<ClassificationResult> classify(String imagePath);
  Future<void> dispose();
}

/// Clasifica con MobileNetV4 sobre ImageNet-1k y agrupa las 1000 clases en los
/// grupos del catálogo.
class TfliteClassifierService implements ClassifierService {
  TfliteClassifierService({AnimalGroupMapping? mapping}) : _mapping = mapping;

  static const modelAsset = 'assets/model_mnv4.tflite';
  static const labelsAsset = 'assets/labels_imagenet.txt';

  /// Normalización medida con `tool/verify_model.py --preprocess auto`.
  ///
  /// El plugin aplica `(pixel - mean) / std` con un único escalar para los tres
  /// canales, así que la normalización exacta de timm (media y desviación por
  /// canal) no es representable. La diferencia medida fue de cero aciertos
  /// sobre 81 imágenes.
  static const imageMean = 127.5;
  static const imageStd = 127.5;

  /// El modelo devuelve logits, casi siempre negativos, y el plugin descarta
  /// las clases con `confidence > threshold`. Con un umbral de cero se perdería
  /// la mayor parte del vector y la normalización saldría mal.
  static const _keepEveryClass = -1e9;

  static const _maxAlternatives = 2;

  AnimalGroupMapping? _mapping;

  @override
  Future<void> load() async {
    if (kIsWeb) {
      throw UnsupportedError('La clasificación no está disponible en web.');
    }
    _mapping ??= await AnimalGroupMapping.load();
    await Tflite.loadModel(model: modelAsset, labels: labelsAsset);
  }

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    final mapping = _mapping;
    if (mapping == null) {
      throw StateError('El modelo todavía no está cargado');
    }

    final results = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: mapping.classCount,
      threshold: _keepEveryClass,
      imageMean: imageMean,
      imageStd: imageStd,
    );
    if (results == null || results.isEmpty) {
      throw StateError('Resultado del modelo inválido');
    }

    final scores = [
      for (final result in results) _toScore(result, mapping.classCount),
    ];
    final aggregated = mapping.aggregate(scores);

    final predictions = [
      for (final group in aggregated.groups)
        if (animalByName.containsKey(group.group))
          Prediction(
            animal: group.group,
            confidence: group.probability.clamp(0.0, 1.0),
          ),
    ];
    if (predictions.isEmpty) {
      throw StateError('El modelo no ha reconocido ningún grupo del catálogo');
    }

    return ClassificationResult(
      primary: predictions.first,
      alternatives: predictions.skip(1).take(_maxAlternatives).toList(),
      notAnimalConfidence: aggregated.nonAnimalProbability,
    );
  }

  /// Valida lo que llega por el canal de plataforma antes de usarlo.
  ClassScore _toScore(Object? result, int classCount) {
    if (result is! Map) {
      throw StateError('Resultado del modelo inválido');
    }
    final index = result['index'];
    if (index is! int || index < 0 || index >= classCount) {
      throw StateError('Índice de clase inválido');
    }
    final score = result['confidence'];
    if (score is! num || !score.toDouble().isFinite) {
      throw StateError('Puntuación del modelo inválida');
    }
    return ClassScore(index: index, score: score.toDouble());
  }

  @override
  Future<void> dispose() async {
    if (!kIsWeb) await Tflite.close();
  }
}

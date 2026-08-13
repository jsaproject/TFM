import 'dart:convert';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class ClassifierService {
  Future<void> load();
  Future<ClassificationResult> classify(String imagePath);
  Future<void> dispose();
}

/// Clasificador TinyCLIP local para Android.
///
/// El canal nativo ejecuta el encoder ONNX; esta frontera valida todos los
/// valores y traduce los índices del modelo al catálogo tipado de la app.
class TinyClipClassifierService implements ClassifierService {
  TinyClipClassifierService({AssetBundle? assets, MethodChannel? channel})
    : _assets = assets ?? rootBundle,
      _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.tfm.animalspredictor/tinyclip';
  static const metadataAsset =
      'assets/models/tinyclip_39m_classifier.metadata.json';
  static const _maxPredictions = 3;

  final AssetBundle _assets;
  final MethodChannel _channel;
  _TinyClipMetadata? _metadata;
  var _loaded = false;

  @override
  Future<void> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'La clasificación TinyCLIP está disponible solo en Android.',
      );
    }
    final raw = await _assets.loadString(metadataAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Metadatos del modelo inválidos');
    }
    final metadata = _TinyClipMetadata.fromJson(decoded);
    await _channel.invokeMethod<void>('load');
    _metadata = metadata;
    _loaded = true;
  }

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    final metadata = _metadata;
    if (!_loaded || metadata == null) {
      throw StateError('El modelo todavía no está cargado');
    }
    if (imagePath.trim().isEmpty) {
      throw ArgumentError.value(imagePath, 'imagePath', 'Ruta de imagen vacía');
    }
    final raw = await _channel.invokeMethod<Object?>('classify', {
      'imagePath': imagePath,
    });
    if (raw is! Map) {
      throw StateError('Resultado del modelo inválido');
    }
    final rejected = raw['rejected'];
    final indices = raw['indices'];
    final scores = raw['scores'];
    final topSimilarity = raw['topSimilarity'];
    final margin = raw['margin'];
    if (rejected is! bool ||
        indices is! List ||
        scores is! List ||
        indices.isEmpty ||
        indices.length != scores.length ||
        indices.length > _maxPredictions ||
        topSimilarity is! num ||
        !topSimilarity.toDouble().isFinite ||
        margin is! num ||
        !margin.toDouble().isFinite ||
        margin.toDouble() < 0) {
      throw StateError('Resultado del modelo inválido');
    }

    final seen = <int>{};
    final predictions = <Prediction>[];
    for (var position = 0; position < indices.length; position++) {
      final index = indices[position];
      final score = scores[position];
      if (index is! int ||
          index < 0 ||
          index >= metadata.displayNames.length ||
          !seen.add(index) ||
          score is! num ||
          !score.toDouble().isFinite ||
          score.toDouble() < 0 ||
          score.toDouble() > 1) {
        throw StateError('Predicción del modelo inválida');
      }
      predictions.add(
        Prediction(
          animal: metadata.displayNames[index],
          confidence: score.toDouble(),
        ),
      );
    }
    if (predictions.isEmpty) {
      throw StateError('El modelo no ha devuelto ninguna predicción');
    }
    return ClassificationResult(
      primary: predictions.first,
      alternatives: predictions.skip(1).toList(growable: false),
      notAnimalConfidence: rejected ? 1 : 0,
      reliable: !rejected,
    );
  }

  @override
  Future<void> dispose() async {
    if (!_loaded) return;
    await _channel.invokeMethod<void>('dispose');
    _loaded = false;
    _metadata = null;
  }
}

@immutable
class _TinyClipMetadata {
  const _TinyClipMetadata({required this.displayNames});

  final List<String> displayNames;

  factory _TinyClipMetadata.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Versión de metadatos no compatible');
    }
    final ids = json['class_ids'];
    final names = json['display_names'];
    if (ids is! List ||
        names is! List ||
        ids.isEmpty ||
        ids.length != names.length ||
        ids.toSet().length != ids.length ||
        names.toSet().length != names.length) {
      throw const FormatException('Clases del modelo inválidas');
    }
    final displayNames = <String>[];
    for (var index = 0; index < ids.length; index++) {
      final id = ids[index];
      final name = names[index];
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          name.isEmpty ||
          !currentAnimalByName.containsKey(name)) {
        throw const FormatException(
          'El modelo y el catálogo de animales no coinciden',
        );
      }
      displayNames.add(name);
    }
    return _TinyClipMetadata(displayNames: List.unmodifiable(displayNames));
  }
}

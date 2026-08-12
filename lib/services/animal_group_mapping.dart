import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Ruta del mapeo que comparten la app y `tool/verify_model.py`.
const animalGroupsAsset = 'assets/imagenet_animal_groups.json';

/// Puntuación cruda que el modelo da a una clase de ImageNet.
class ClassScore {
  const ClassScore({required this.index, required this.score});

  final int index;
  final double score;
}

/// Probabilidad acumulada de un grupo del catálogo.
class GroupScore {
  const GroupScore({required this.group, required this.probability});

  final String group;
  final double probability;
}

/// Resultado de repartir las 1000 clases de ImageNet entre los grupos.
class AggregatedScores {
  AggregatedScores({
    required List<GroupScore> groups,
    required this.nonAnimalProbability,
  }) : groups = List.unmodifiable(groups);

  /// Grupos con probabilidad mayor que cero, de mayor a menor.
  final List<GroupScore> groups;

  /// Probabilidad repartida entre las clases que no son animales.
  ///
  /// Sale gratis: de las 1000 clases de ImageNet solo 396 lo son, así que el
  /// resto funciona como detector de "esto no es un animal".
  final double nonAnimalProbability;
}

/// Traduce las clases de ImageNet a los grupos que muestra la app.
class AnimalGroupMapping {
  AnimalGroupMapping._(this._groupByClass, this.classCount);

  final Map<int, String> _groupByClass;

  /// Clases que produce el modelo, para validar los índices que llegan.
  final int classCount;

  Iterable<String> get groupNames => _groupByClass.values.toSet();

  static Future<AnimalGroupMapping> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(animalGroupsAsset);
    return AnimalGroupMapping.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory AnimalGroupMapping.fromJson(Map<String, dynamic> json) {
    final groups = json['grupos'];
    if (groups is! Map) {
      throw const FormatException('El mapeo de grupos no tiene clave "grupos"');
    }
    final classCount = json['total_clases_modelo'];
    if (classCount is! int || classCount <= 0) {
      throw const FormatException('El mapeo no declara "total_clases_modelo"');
    }

    final byClass = <int, String>{};
    for (final entry in groups.entries) {
      final group = entry.key;
      final indices = entry.value;
      if (group is! String || group.isEmpty || indices is! List) {
        throw const FormatException('Grupo mal formado en el mapeo');
      }
      for (final index in indices) {
        if (index is! int || index < 0 || index >= classCount) {
          throw FormatException('Índice fuera de rango en "$group": $index');
        }
        if (byClass.containsKey(index)) {
          throw FormatException('La clase $index está en dos grupos');
        }
        byClass[index] = group;
      }
    }
    if (byClass.isEmpty) {
      throw const FormatException('El mapeo de grupos está vacío');
    }
    return AnimalGroupMapping._(byClass, classCount);
  }

  /// Reparte las puntuaciones del modelo entre los grupos.
  ///
  /// Acepta tanto logits como probabilidades: MobileNetV4 convertido desde timm
  /// no lleva softmax dentro y devuelve logits, que hay que normalizar antes de
  /// sumarlos. Sumar logits no significa nada.
  AggregatedScores aggregate(List<ClassScore> scores) {
    if (scores.isEmpty) {
      throw ArgumentError.value(
        scores,
        'scores',
        'Sin puntuaciones que agrupar',
      );
    }
    final probabilities = _toProbabilities(scores);

    final byGroup = <String, double>{};
    var animalMass = 0.0;
    for (var i = 0; i < scores.length; i++) {
      final group = _groupByClass[scores[i].index];
      if (group == null) continue;
      byGroup.update(
        group,
        (current) => current + probabilities[i],
        ifAbsent: () => probabilities[i],
      );
      animalMass += probabilities[i];
    }

    final groups =
        byGroup.entries
            .map(
              (entry) => GroupScore(group: entry.key, probability: entry.value),
            )
            .toList()
          ..sort(
            (left, right) => right.probability.compareTo(left.probability),
          );

    return AggregatedScores(
      groups: groups,
      nonAnimalProbability: (1.0 - animalMass).clamp(0.0, 1.0),
    );
  }

  /// Normaliza a probabilidades, detectando si ya lo eran.
  List<double> _toProbabilities(List<ClassScore> scores) {
    var total = 0.0;
    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    for (final score in scores) {
      total += score.score;
      minimum = math.min(minimum, score.score);
      maximum = math.max(maximum, score.score);
    }
    // Una distribución ya normalizada no debe volver a pasar por softmax:
    // lo aplanaría y dejaría todas las clases casi iguales.
    if (minimum >= 0.0 && (total - 1.0).abs() < 0.05) {
      return [for (final score in scores) score.score];
    }

    var sum = 0.0;
    final exponentials = <double>[
      for (final score in scores) math.exp(score.score - maximum),
    ];
    for (final value in exponentials) {
      sum += value;
    }
    if (sum <= 0 || !sum.isFinite) {
      throw StateError('Las puntuaciones del modelo no son normalizables');
    }
    return [for (final value in exponentials) value / sum];
  }
}

import 'dart:convert';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/services/animal_group_mapping.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

AnimalGroupMapping buildMapping() => AnimalGroupMapping.fromJson({
  'total_clases_modelo': 6,
  'grupos': {
    'Perro': [0, 1],
    'Gato': [2],
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suma las clases de cada grupo después de normalizar los logits', () {
    final aggregated = buildMapping().aggregate(const [
      ClassScore(index: 0, score: 2),
      ClassScore(index: 1, score: 2),
      ClassScore(index: 2, score: 1),
      ClassScore(index: 3, score: 0),
      ClassScore(index: 4, score: 0),
      ClassScore(index: 5, score: 0),
    ]);

    // softmax: dos clases a e^2 para Perro, una a e^1 para Gato.
    expect(aggregated.groups.first.group, 'Perro');
    expect(aggregated.groups.first.probability, closeTo(0.721010, 1e-6));
    expect(aggregated.groups.last.group, 'Gato');
    expect(aggregated.groups.last.probability, closeTo(0.132622, 1e-6));
    expect(aggregated.nonAnimalProbability, closeTo(0.146367, 1e-6));
  });

  test('no vuelve a normalizar una salida que ya son probabilidades', () {
    final aggregated = buildMapping().aggregate(const [
      ClassScore(index: 0, score: 0.5),
      ClassScore(index: 1, score: 0.2),
      ClassScore(index: 2, score: 0.1),
      ClassScore(index: 3, score: 0.2),
    ]);

    expect(aggregated.groups.first.probability, closeTo(0.7, 1e-9));
    expect(aggregated.nonAnimalProbability, closeTo(0.2, 1e-9));
  });

  test('reparte toda la masa entre grupos y no animales', () {
    final aggregated = buildMapping().aggregate(const [
      ClassScore(index: 0, score: 3),
      ClassScore(index: 2, score: -1),
      ClassScore(index: 5, score: 0),
    ]);

    final total =
        aggregated.groups.fold<double>(0, (sum, g) => sum + g.probability) +
        aggregated.nonAnimalProbability;
    expect(total, closeTo(1.0, 1e-9));
  });

  test('rechaza un mapeo con una clase repetida en dos grupos', () {
    expect(
      () => AnimalGroupMapping.fromJson({
        'total_clases_modelo': 4,
        'grupos': {
          'Perro': [0, 1],
          'Gato': [1],
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('rechaza un índice fuera del rango del modelo', () {
    expect(
      () => AnimalGroupMapping.fromJson({
        'total_clases_modelo': 2,
        'grupos': {
          'Perro': [5],
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('el mapeo embarcado cuadra con el catálogo', () async {
    final raw = await rootBundle.loadString(animalGroupsAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final mapping = AnimalGroupMapping.fromJson(json);

    expect(mapping.classCount, 1000);
    // Si alguien añade un grupo al JSON y olvida el catálogo, la app dejaría de
    // poder mostrar ese resultado. Esta comprobación lo impide.
    expect(mapping.groupNames.toSet(), animalByName.keys.toSet());
  });
}

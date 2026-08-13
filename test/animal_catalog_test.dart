import 'package:animalspredictor/animal_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ningún animal del catálogo repite icono', () {
    final iconos = <int, String>{};
    for (final animal in animalCatalog) {
      final repetido = iconos[animal.icon.codePoint];
      expect(
        repetido,
        isNull,
        reason: '${animal.name} y $repetido comparten icono',
      );
      iconos[animal.icon.codePoint] = animal.name;
    }
    expect(iconos, hasLength(animalCatalog.length));
  });

  test('cada animal del catálogo tiene un nombre distinto', () {
    expect(currentAnimalByName, hasLength(animalCatalog.length));
  });

  test('cada animal del catálogo vive en un sitio', () {
    for (final animal in animalCatalog) {
      expect(
        animal.habitat,
        isNotNull,
        reason: '${animal.name} no tiene sitio',
      );
    }
    // Y los tres sitios juntos son el catálogo entero: ninguna medalla de
    // sitio se queda con animales fuera.
    final porSitio = AnimalHabitat.values
        .map((habitat) => animalsInHabitat(habitat).length)
        .fold(0, (total, cuantos) => total + cuantos);
    expect(porSitio, animalCatalog.length);
  });
}

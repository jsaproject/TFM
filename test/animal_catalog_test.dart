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
}

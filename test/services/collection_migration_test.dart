import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('traduce los nombres guardados antes de agrupar las clases', () {
    final collection = userCollectionFromFirestore({
      'collection': {'Bovino': 3, 'Ave de corral': 1, 'Perro': 2},
    });

    expect(collection.counts['Vaca'], 3);
    expect(collection.counts['Gallina'], 1);
    expect(collection.counts['Perro'], 2);
    expect(collection.counts.containsKey('Bovino'), isFalse);
  });

  test('suma el nombre antiguo y el nuevo en el mismo grupo', () {
    final collection = userCollectionFromFirestore({
      'collection': {'Araña': 2, 'Araña y escorpión': 1},
    });

    expect(collection.counts['Araña y escorpión'], 3);
    expect(collection.discovered, 0);
  });

  test('se queda con la fecha más reciente al fusionar nombres', () {
    final antigua = DateTime(2021, 6, 9);
    final reciente = DateTime(2026, 8, 12);
    final collection = userCollectionFromFirestore({
      'collection': {'Ardilla': 1, 'Roedor': 1},
      'lastIdentified': {'Ardilla': reciente, 'Roedor': antigua},
    });

    expect(collection.lastIdentified['Roedor'], reciente);
  });

  test('cada nombre antiguo apunta a un grupo que existe en el catálogo', () {
    for (final group in legacyAnimalNames.values) {
      expect(
        animalByName.containsKey(group),
        isTrue,
        reason: '$group no está en el catálogo',
      );
    }
  });

  test('deja intacto un nombre que ya es un grupo actual', () {
    expect(resolveAnimalName('Bovino'), 'Vaca');
    expect(resolveAnimalName('Vaca'), 'Vaca');
  });
}

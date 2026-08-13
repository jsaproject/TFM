import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula especies conocidas y fotos totales', () {
    const collection = UserCollection(
      counts: {'Gato': 2, 'Perro': 1, 'Desconocido': 4},
    );

    expect(collection.discovered, 2);
    expect(collection.totalPhotos, 7);
    expect(collection.isEmpty, isFalse);
  });

  test('cuenta los animales que ya tiene de cada sitio', () {
    const collection = UserCollection(counts: {'Vaca': 1, 'Gato': 3});

    expect(collection.discoveredIn(AnimalHabitat.granja), 1);
    expect(collection.discoveredIn(AnimalHabitat.casa), 1);
    expect(collection.discoveredIn(AnimalHabitat.salvaje), 0);
  });

  test('lee las medallas ya celebradas y descarta lo que no existe', () {
    final collection = userCollectionFromFirestore({
      'collection': {'Vaca': 1},
      'achievements': ['primera_foto', 'medalla_inventada', 7],
    });

    expect(collection.seenAchievements, {'primera_foto'});
  });

  test('sin medallas guardadas la lista llega vacía, no rota', () {
    final sinCampo = userCollectionFromFirestore({
      'collection': {'Vaca': 1},
    });
    final conBasura = userCollectionFromFirestore({
      'collection': {'Vaca': 1},
      'achievements': 'primera_foto',
    });

    expect(sinCampo.seenAchievements, isEmpty);
    expect(conBasura.seenAchievements, isEmpty);
  });

  test('recupera y combina el formato antiguo de la colección', () {
    final oldDate = DateTime(2026, 1, 1);
    final newDate = DateTime(2026, 2, 1);
    final collection = userCollectionFromFirestore({
      'collection': {'Gato': 2},
      'collection.Gato': 1,
      'collection.Perro': 4,
      'lastIdentified': {'Gato': Timestamp.fromDate(oldDate)},
      'lastIdentified.Gato': Timestamp.fromDate(newDate),
    });

    expect(collection.counts, {'Gato': 3, 'Perro': 4});
    expect(collection.lastIdentified['Gato'], newDate);
  });

  test('ignora campos antiguos después de migrarlos', () {
    final collection = userCollectionFromFirestore({
      'collectionSchemaVersion': 2,
      'collection': {'Perro': 4},
      'collection.Perro': 4,
    });

    expect(collection.counts, {'Perro': 4});
  });

  test('expone el último descubrimiento de una especie conocida', () {
    final latest = DateTime(2026, 8, 12);
    final collection = UserCollection(
      lastIdentified: {'Desconocido': DateTime(2026, 8, 13), 'Gato': latest},
    );

    expect(collection.lastDiscoveredAnimal, 'Gato');
    expect(collection.lastDiscoveredAt, latest);
  });
}

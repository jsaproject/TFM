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

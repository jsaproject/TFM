import 'dart:async';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CollectionRepository {
  Stream<UserCollection> watch(String uid);
  Stream<List<CollectionPrediction>> watchPredictions(String uid);
  Future<void> savePrediction(String uid, String animal);
  Future<void> updatePrediction(
    String uid,
    CollectionPrediction prediction,
    String? animal,
  );
}

class CollectionPrediction {
  const CollectionPrediction({
    required this.id,
    required this.animal,
    this.createdAt,
  });

  final String id;
  final String animal;
  final DateTime? createdAt;
}

class FirestoreCollectionRepository implements CollectionRepository {
  FirestoreCollectionRepository(this._firestore);
  final FirebaseFirestore _firestore;
  final Set<String> _legacyMigrations = {};

  @override
  Stream<UserCollection> watch(String uid) =>
      _user(uid).snapshots().map((snapshot) {
        final data = snapshot.data() ?? {};
        if (_needsLegacyMigration(data)) _scheduleLegacyMigration(uid);
        return userCollectionFromFirestore(data);
      });

  @override
  Stream<List<CollectionPrediction>> watchPredictions(String uid) => _user(uid)
      .collection('predictions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(_predictionFromDocument)
            .whereType<CollectionPrediction>()
            .toList(growable: false),
      );

  @override
  Future<void> savePrediction(String uid, String animal) async {
    _validateAnimal(animal);
    final user = _user(uid);
    final batch = _firestore.batch();
    batch.set(user, {
      // set() treats dotted keys as literal field names. Nested maps are
      // required here so watch() can read the collection map afterwards.
      'collection': {animal: FieldValue.increment(1)},
      'lastIdentifiedAt': FieldValue.serverTimestamp(),
      'lastIdentified': {animal: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
    batch.set(user.collection('predictions').doc(), {
      'animal': animal,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> updatePrediction(
    String uid,
    CollectionPrediction prediction,
    String? animal,
  ) async {
    if (animal != null) _validateAnimal(animal);
    final user = _user(uid);
    final reference = user.collection('predictions').doc(prediction.id);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(user);
      final predictionSnapshot = await transaction.get(reference);
      if (!predictionSnapshot.exists) {
        throw StateError('La identificación ya no está disponible.');
      }

      final storedAnimal = predictionSnapshot.data()?['animal'];
      // Se valida el nombre traducido, pero se descuenta del campo original:
      // en Firestore la cuenta sigue guardada bajo la clave antigua.
      if (storedAnimal is! String ||
          !animalByName.containsKey(resolveAnimalName(storedAnimal))) {
        throw StateError('La identificación guardada no es válida.');
      }
      final counts = _readCounts(userSnapshot.data() ?? {});
      final oldCount = counts[storedAnimal] ?? 0;
      if (oldCount <= 0) {
        throw StateError('La colección no contiene esta identificación.');
      }
      if (animal == storedAnimal) return;

      transaction.update(user, {
        'collection.$storedAnimal': oldCount == 1
            ? FieldValue.delete()
            : FieldValue.increment(-1),
      });
      if (animal == null) {
        transaction.delete(reference);
        return;
      }

      transaction.update(user, {
        'collection.$animal': FieldValue.increment(1),
        'lastIdentified.$animal': FieldValue.serverTimestamp(),
      });
      transaction.update(reference, {'animal': animal});
    });
  }

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionPrediction? _predictionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final animal = data['animal'];
    if (animal is! String) return null;
    final resolved = resolveAnimalName(animal);
    if (!animalByName.containsKey(resolved)) return null;
    final createdAt = data['createdAt'];
    return CollectionPrediction(
      id: document.id,
      animal: resolved,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  void _validateAnimal(String animal) {
    if (!animalByName.containsKey(animal)) {
      throw ArgumentError.value(animal, 'animal', 'Animal no compatible');
    }
  }

  void _scheduleLegacyMigration(String uid) {
    if (!_legacyMigrations.add(uid)) return;
    unawaited(() async {
      try {
        await _migrateLegacyFields(uid);
      } catch (_) {
        // The decoded legacy values remain visible; a later snapshot retries.
      } finally {
        _legacyMigrations.remove(uid);
      }
    }());
  }

  Future<void> _migrateLegacyFields(String uid) async {
    final user = _user(uid);
    final legacyKeys = await _firestore.runTransaction<List<String>>((
      transaction,
    ) async {
      final snapshot = await transaction.get(user);
      final data = snapshot.data();
      if (data == null || !_needsLegacyMigration(data)) return const [];

      final keys = _legacyFieldKeys(data).toList();
      transaction.set(user, {
        'collection': _readCounts(data),
        'lastIdentified': _readRawDates(data),
        'collectionSchemaVersion': 2,
      }, SetOptions(merge: true));
      return keys;
    });

    if (legacyKeys.isNotEmpty) {
      await user.update(<Object, Object?>{
        for (final key in legacyKeys) FieldPath([key]): FieldValue.delete(),
      });
    }
  }
}

/// Decodes both the current nested maps and fields written by versions that
/// accidentally stored names such as `collection.Perro` as literal keys.
UserCollection userCollectionFromFirestore(Map<String, dynamic> data) {
  final includeLegacy = data['collectionSchemaVersion'] != 2;
  final dates = <String, DateTime>{};
  for (final entry in _readRawDates(
    data,
    includeLegacy: includeLegacy,
  ).entries) {
    final animal = resolveAnimalName(entry.key);
    final date = _asDateTime(entry.value);
    final current = dates[animal];
    if (current == null || date.isAfter(current)) dates[animal] = date;
  }

  // Los nombres se traducen al leer, no en Firestore: el documento del usuario
  // se queda como está y su colección de 2021 sigue contando.
  final counts = <String, int>{};
  for (final entry in _readCounts(data, includeLegacy: includeLegacy).entries) {
    counts.update(
      resolveAnimalName(entry.key),
      (current) => current + entry.value,
      ifAbsent: () => entry.value,
    );
  }

  return UserCollection(counts: counts, lastIdentified: dates);
}

Map<String, int> _readCounts(
  Map<String, dynamic> data, {
  bool includeLegacy = true,
}) {
  final counts = <String, int>{};
  final nested = data['collection'];
  if (nested is Map) {
    for (final entry in nested.entries) {
      if (entry.key is String && entry.value is num) {
        counts[entry.key as String] = (entry.value as num).toInt();
      }
    }
  }
  if (includeLegacy) {
    for (final entry in data.entries) {
      const prefix = 'collection.';
      if (entry.key.startsWith(prefix) && entry.value is num) {
        final animal = entry.key.substring(prefix.length);
        counts.update(
          animal,
          (currentCount) => currentCount + (entry.value as num).toInt(),
          ifAbsent: () => (entry.value as num).toInt(),
        );
      }
    }
  }
  return counts;
}

Map<String, dynamic> _readRawDates(
  Map<String, dynamic> data, {
  bool includeLegacy = true,
}) {
  final dates = <String, dynamic>{};
  final nested = data['lastIdentified'];
  if (nested is Map) {
    for (final entry in nested.entries) {
      if (entry.key is String) dates[entry.key as String] = entry.value;
    }
  }
  if (includeLegacy) {
    for (final entry in data.entries) {
      const prefix = 'lastIdentified.';
      if (entry.key.startsWith(prefix)) {
        final animal = entry.key.substring(prefix.length);
        final current = dates[animal];
        if (current == null ||
            _milliseconds(entry.value) > _milliseconds(current)) {
          dates[animal] = entry.value;
        }
      }
    }
  }
  return dates;
}

DateTime _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

int _milliseconds(dynamic value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  return 0;
}

bool _needsLegacyMigration(Map<String, dynamic> data) =>
    data['collectionSchemaVersion'] != 2 && _legacyFieldKeys(data).isNotEmpty;

Iterable<String> _legacyFieldKeys(Map<String, dynamic> data) => data.keys.where(
  (key) => key.startsWith('collection.') || key.startsWith('lastIdentified.'),
);

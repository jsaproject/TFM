import 'dart:async';

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
  const CollectionPrediction({required this.id, required this.animal});
  final String id;
  final String animal;
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
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => CollectionPrediction(
                id: doc.id,
                animal: doc.data()['animal'] as String? ?? 'Animal',
              ),
            )
            .toList(),
      );

  @override
  Future<void> savePrediction(String uid, String animal) async {
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
    final user = _user(uid);
    final data = (await user.get()).data();
    final counts = data?['collection'] as Map<String, dynamic>?;
    final oldCount = counts?[prediction.animal] is num
        ? (counts![prediction.animal] as num).toInt()
        : 0;
    final batch = _firestore.batch();
    batch.update(user, {
      'collection.${prediction.animal}': oldCount <= 1
          ? FieldValue.delete()
          : FieldValue.increment(-1),
    });
    final reference = user.collection('predictions').doc(prediction.id);
    if (animal == null) {
      batch.delete(reference);
    } else {
      batch.update(user, {
        'collection.$animal': FieldValue.increment(1),
        'lastIdentified.$animal': FieldValue.serverTimestamp(),
      });
      batch.update(reference, {'animal': animal});
    }
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

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
  final dates = _readRawDates(
    data,
    includeLegacy: includeLegacy,
  ).map((animal, value) => MapEntry(animal, _asDateTime(value)));
  return UserCollection(
    counts: _readCounts(data, includeLegacy: includeLegacy),
    lastIdentified: dates,
  );
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

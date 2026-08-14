import 'dart:async';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/features/collection/data/local_collection_export.dart';
import 'package:animalspredictor/features/collection/data/local_collection_models.dart';
import 'package:animalspredictor/features/collection/data/guest_collection_sync_service.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:realm/realm.dart';

/// Colección privada del modo invitado. Es local al dispositivo y no inicia
/// ninguna conexión con Firebase.
class LocalCollectionRepository
    implements
        CollectionRepository,
        DisposableCollectionRepository,
        GuestCollectionStore {
  LocalCollectionRepository._(this._realm);

  static const _metadataId = 'guest';
  final Realm _realm;
  final _changes = StreamController<void>.broadcast();

  factory LocalCollectionRepository.open() => LocalCollectionRepository._(
    Realm(
      Configuration.local(
        [LocalPrediction.schema, LocalCollectionMetadata.schema],
        path:
            '${Configuration.defaultStoragePath}/michi_guest_collection.realm',
      ),
    ),
  );

  @override
  Stream<UserCollection> watch(String ownerId) {
    return Stream.multi((controller) {
      controller.add(_currentCollection());
      final subscription = _changes.stream.listen((_) {
        controller.add(_currentCollection());
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<List<CollectionPrediction>> watchPredictions(String ownerId) {
    return Stream.multi((controller) {
      controller.add(_currentPredictions());
      final subscription = _changes.stream.listen((_) {
        controller.add(_currentPredictions());
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> savePrediction(String ownerId, String animal) async {
    _validateAnimal(animal);
    _realm.write(() {
      _realm.add(LocalPrediction(Uuid.v4().toString(), animal, DateTime.now()));
    });
    _changes.add(null);
  }

  @override
  Future<void> updatePrediction(
    String ownerId,
    CollectionPrediction prediction,
    String? animal,
  ) async {
    if (animal != null) _validateAnimal(animal);
    final stored = _realm.find<LocalPrediction>(prediction.id);
    if (stored == null) {
      throw StateError('La identificación ya no está disponible.');
    }
    _realm.write(() {
      if (animal == null) {
        _realm.delete(stored);
      } else {
        stored.animal = animal;
      }
    });
    _changes.add(null);
  }

  @override
  Future<void> markAchievementsSeen(
    String ownerId,
    Iterable<String> ids,
  ) async {
    final known = ids.where((id) => _knownAchievementIds.contains(id)).toSet();
    if (known.isEmpty) return;
    _realm.write(() {
      final metadata = _metadata();
      metadata.seenAchievements.addAll(
        known.where((id) => !metadata.seenAchievements.contains(id)),
      );
    });
    _changes.add(null);
  }

  /// Devuelve una instantánea inmutable para transferirla al crear o acceder a
  /// una cuenta. Los ids se reutilizan como ids de documento de Firestore.
  @override
  Future<LocalCollectionExport> exportForSync() async => LocalCollectionExport(
    predictions: _currentPredictions(),
    seenAchievementIds: _metadata().seenAchievements.toSet(),
  );

  /// Se llama solo después de que Firestore haya confirmado la importación
  /// completa. Así un error o un cierre de la app nunca pierde datos locales.
  @override
  Future<void> clearAfterSync() async {
    _realm.write(() {
      _realm.deleteMany(_realm.all<LocalPrediction>());
      final metadata = _realm.find<LocalCollectionMetadata>(_metadataId);
      if (metadata != null) _realm.delete(metadata);
    });
    _changes.add(null);
  }

  @override
  Future<void> dispose() async {
    await _changes.close();
    _realm.close();
  }

  List<CollectionPrediction> _currentPredictions() =>
      _realm
          .all<LocalPrediction>()
          .toList(growable: false)
          .map(
            (prediction) => CollectionPrediction(
              id: prediction.id,
              animal: prediction.animal,
              createdAt: prediction.createdAt,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => right.createdAt!.compareTo(left.createdAt!));

  UserCollection _currentCollection() {
    var collection = const UserCollection();
    for (final prediction in _currentPredictions()) {
      collection = collection.withPhotoOf(
        prediction.animal,
        at: prediction.createdAt,
      );
    }
    return UserCollection(
      counts: collection.counts,
      lastIdentified: collection.lastIdentified,
      seenAchievements: _metadata().seenAchievements.toSet(),
    );
  }

  LocalCollectionMetadata _metadata() {
    final existing = _realm.find<LocalCollectionMetadata>(_metadataId);
    if (existing != null) return existing;
    late LocalCollectionMetadata created;
    _realm.write(() {
      created = _realm.add(LocalCollectionMetadata(_metadataId));
    });
    return created;
  }

  void _validateAnimal(String animal) {
    if (!currentAnimalByName.containsKey(animal)) {
      throw ArgumentError.value(animal, 'animal', 'Animal no compatible');
    }
  }
}

final _knownAchievementIds = {
  for (final achievement in achievementCatalog) achievement.id,
};

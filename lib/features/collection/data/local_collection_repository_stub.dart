import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/data/guest_collection_sync_service.dart';
import 'package:animalspredictor/features/collection/data/local_collection_export.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';

/// Realm no tiene soporte para web. La app se centra en móvil y escritorio;
/// esta implementación permite que la versión web siga compilando sin guardar
/// nada en Firebase para el modo invitado.
class LocalCollectionRepository
    implements
        CollectionRepository,
        DisposableCollectionRepository,
        GuestCollectionStore {
  LocalCollectionRepository.open();

  final _predictions = <CollectionPrediction>[];
  final _seenAchievements = <String>{};

  @override
  Stream<UserCollection> watch(String ownerId) => Stream.value(_collection());

  @override
  Stream<List<CollectionPrediction>> watchPredictions(String ownerId) =>
      Stream.value(List.unmodifiable(_predictions));

  @override
  Future<void> savePrediction(String ownerId, String animal) async {
    if (!currentAnimalByName.containsKey(animal)) {
      throw ArgumentError.value(animal, 'animal', 'Animal no compatible');
    }
    _predictions.insert(
      0,
      CollectionPrediction(
        id: 'web-${DateTime.now().microsecondsSinceEpoch}',
        animal: animal,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updatePrediction(
    String ownerId,
    CollectionPrediction prediction,
    String? animal,
  ) async {
    final index = _predictions.indexWhere((item) => item.id == prediction.id);
    if (index < 0) throw StateError('La identificación ya no está disponible.');
    if (animal != null && !currentAnimalByName.containsKey(animal)) {
      throw ArgumentError.value(animal, 'animal', 'Animal no compatible');
    }
    if (animal == null) {
      _predictions.removeAt(index);
    } else {
      _predictions[index] = CollectionPrediction(
        id: prediction.id,
        animal: animal,
        createdAt: prediction.createdAt,
      );
    }
  }

  @override
  Future<void> markAchievementsSeen(
    String ownerId,
    Iterable<String> ids,
  ) async {
    _seenAchievements.addAll(
      ids.where((id) => achievementCatalog.any((item) => item.id == id)),
    );
  }

  @override
  Future<LocalCollectionExport> exportForSync() async => LocalCollectionExport(
    predictions: List.unmodifiable(_predictions),
    seenAchievementIds: Set.unmodifiable(_seenAchievements),
  );

  @override
  Future<void> clearAfterSync() async {
    _predictions.clear();
    _seenAchievements.clear();
  }

  @override
  Future<void> dispose() async {}

  UserCollection _collection() {
    var collection = const UserCollection();
    for (final prediction in _predictions) {
      collection = collection.withPhotoOf(
        prediction.animal,
        at: prediction.createdAt,
      );
    }
    return UserCollection(
      counts: collection.counts,
      lastIdentified: collection.lastIdentified,
      seenAchievements: _seenAchievements,
    );
  }
}

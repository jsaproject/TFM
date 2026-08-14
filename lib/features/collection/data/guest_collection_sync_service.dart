import 'package:animalspredictor/features/collection/data/local_collection_export.dart';
import 'package:animalspredictor/services/collection_repository.dart';

abstract class GuestCollectionStore {
  Future<LocalCollectionExport> exportForSync();
  Future<void> clearAfterSync();
  Future<void> dispose();
}

/// Transfiere una colección invitada una sola vez a una cuenta registrada.
///
/// Si Firebase falla, no se borra nada de Realm. La siguiente ejecución usa
/// los mismos ids de historial, por lo que Firestore no duplica las fotos.
class GuestCollectionSyncService {
  GuestCollectionSyncService(this._store, this._remote);

  final GuestCollectionStore _store;
  final CollectionSyncRepository _remote;

  Future<void> syncTo(String uid) async {
    final local = await _store.exportForSync();
    if (local.isEmpty) return;
    await _remote.importLocalCollection(
      uid,
      predictions: local.predictions,
      seenAchievementIds: local.seenAchievementIds,
    );
    await _store.clearAfterSync();
  }

  Future<void> dispose() => _store.dispose();
}

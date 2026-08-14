import 'package:animalspredictor/features/collection/data/guest_collection_sync_service.dart';
import 'package:animalspredictor/features/collection/data/local_collection_export.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo borra la colección local después de sincronizarla', () async {
    final store = _Store(
      LocalCollectionExport(
        predictions: [
          CollectionPrediction(
            id: 'local-1',
            animal: 'Vaca',
            createdAt: DateTime(2026, 8, 14),
          ),
        ],
        seenAchievementIds: {'primera_foto'},
      ),
    );
    final remote = _Remote();
    final service = GuestCollectionSyncService(store, remote);

    await service.syncTo('cuenta-1');

    expect(remote.uid, 'cuenta-1');
    expect(remote.predictions.single.id, 'local-1');
    expect(remote.achievements, {'primera_foto'});
    expect(store.cleared, isTrue);
  });

  test('conserva la colección local si Firestore falla', () async {
    final store = _Store(
      const LocalCollectionExport(
        predictions: [CollectionPrediction(id: 'local-1', animal: 'Vaca')],
        seenAchievementIds: {},
      ),
    );
    final service = GuestCollectionSyncService(store, _Remote(fails: true));

    await expectLater(service.syncTo('cuenta-1'), throwsStateError);

    expect(store.cleared, isFalse);
  });
}

class _Store implements GuestCollectionStore {
  _Store(this.value);

  final LocalCollectionExport value;
  var cleared = false;

  @override
  Future<void> clearAfterSync() async => cleared = true;

  @override
  Future<void> dispose() async {}

  @override
  Future<LocalCollectionExport> exportForSync() async => value;
}

class _Remote implements CollectionSyncRepository {
  _Remote({this.fails = false});

  final bool fails;
  String? uid;
  List<CollectionPrediction> predictions = const [];
  Set<String> achievements = const {};

  @override
  Future<void> importLocalCollection(
    String uid, {
    required List<CollectionPrediction> predictions,
    required Iterable<String> seenAchievementIds,
  }) async {
    if (fails) throw StateError('sin conexión');
    this.uid = uid;
    this.predictions = predictions;
    achievements = seenAchievementIds.toSet();
  }
}

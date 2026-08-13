import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildPage(_CollectionRepositoryStub repository) => MaterialApp(
    home: Scaffold(
      body: CollectionPage(
        userId: 'user-1',
        isAnonymous: false,
        repository: repository,
        onStartIdentifying: () {},
      ),
    ),
  );

  testWidgets('muestra una cuadrícula y permite filtrar especies pendientes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        _CollectionRepositoryStub(
          collection: UserCollection(
            counts: const {'Vaca': 2, 'Caballo': 1},
            lastIdentified: {'Vaca': DateTime(2026, 8, 12)},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('2 de ${animalCatalog.length} especies descubiertas'),
      findsOneWidget,
    );
    expect(find.text('Vaca'), findsOneWidget);
    expect(find.text('Cerdo'), findsOneWidget);

    await tester.tap(find.text('Pendientes'));
    await tester.pumpAndSettle();

    expect(find.text('Vaca'), findsNothing);
    expect(find.text('Cerdo'), findsOneWidget);
  });

  testWidgets('muestra una acción de reintento ante un error de carga', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(_CollectionRepositoryStub(collectionError: true)),
    );
    await tester.pump();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('Comprueba tu conexión'), findsOneWidget);
  });

  testWidgets('abre el historial general fuera de la cuadrícula', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        _CollectionRepositoryStub(
          collection: const UserCollection(counts: {'Gato': 1}),
          predictions: const [
            CollectionPrediction(id: 'prediction-1', animal: 'Gato'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver historial'));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Gato'), findsOneWidget);
  });

  testWidgets('abre el detalle de una especie con sus estadísticas', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        _CollectionRepositoryStub(
          collection: UserCollection(
            counts: const {'Vaca': 2},
            lastIdentified: {'Vaca': DateTime(2026, 8, 12)},
          ),
          predictions: const [
            CollectionPrediction(id: 'prediction-1', animal: 'Vaca'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vaca'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tranquila, curiosa y experta en pastar.'),
      findsOneWidget,
    );
    expect(find.text('Historial de Vaca'), findsOneWidget);
  });

  testWidgets('anuncia cada especie como una unica accion con su contador', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildPage(
        _CollectionRepositoryStub(
          collection: const UserCollection(counts: {'Vaca': 1}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Vaca, 1 foto'), findsOneWidget);
    semantics.dispose();
  });
}

class _CollectionRepositoryStub implements CollectionRepository {
  _CollectionRepositoryStub({
    this.collection = const UserCollection(),
    this.predictions = const [],
    this.collectionError = false,
  });

  final UserCollection collection;
  final List<CollectionPrediction> predictions;
  final bool collectionError;

  @override
  Future<void> savePrediction(String uid, String animal) async {}

  @override
  Future<void> updatePrediction(
    String uid,
    CollectionPrediction prediction,
    String? animal,
  ) async {}

  @override
  Stream<UserCollection> watch(String uid) => collectionError
      ? Stream<UserCollection>.error(StateError('sin conexión'))
      : Stream<UserCollection>.value(collection);

  @override
  Stream<List<CollectionPrediction>> watchPredictions(String uid) =>
      Stream<List<CollectionPrediction>>.value(predictions);
}

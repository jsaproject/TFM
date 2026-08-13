import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/animal_selector.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSelector({
    String? selected,
    List<String> suggestions = const <String>[],
    required ValueChanged<String> onSelected,
  }) => MaterialApp(
    theme: MichiTheme.light(),
    home: Scaffold(
      body: AnimalSelector(
        selected: selected,
        suggestions: suggestions,
        onSelected: onSelected,
      ),
    ),
  );

  testWidgets('ofrece las sugerencias antes que el resto del catálogo', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSelector(
        selected: 'Vaca',
        suggestions: const ['Vaca', 'Caballo'],
        onSelected: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(TextosNino.tambienPuedeSer), findsOneWidget);
    expect(find.text(TextosNino.todosLosAnimales), findsOneWidget);

    final sugerencias = tester
        .widgetList<AnimalChoiceCard>(find.byType(AnimalChoiceCard))
        .take(2)
        .toList();
    expect(sugerencias.map((ficha) => ficha.animal.name), ['Vaca', 'Caballo']);
    expect(sugerencias.first.selected, isTrue);
    expect(
      tester.getTopLeft(find.text(TextosNino.tambienPuedeSer)).dy,
      lessThan(tester.getTopLeft(find.text(TextosNino.todosLosAnimales)).dy),
    );
  });

  testWidgets('devuelve el animal que se toca', (tester) async {
    final elegidos = <String>[];
    await tester.pumpWidget(buildSelector(onSelected: elegidos.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vaca'));
    await tester.pumpAndSettle();

    expect(elegidos, ['Vaca']);
  });

  testWidgets('ninguna ficha baja de la diana táctil mínima', (tester) async {
    await tester.pumpWidget(buildSelector(onSelected: (_) {}));
    await tester.pumpAndSettle();

    for (final ficha in find.byType(AnimalChoiceCard).evaluate()) {
      final size = tester.getSize(find.byWidget(ficha.widget));
      expect(size.height, greaterThanOrEqualTo(MichiTokens.touchTargetMin));
      expect(
        size.width,
        greaterThanOrEqualTo(MichiTokens.animalChoiceMinWidth),
      );
    }
  });

  testWidgets('anuncia el animal elegido a un lector de pantalla', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildSelector(selected: 'Vaca', onSelected: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(TextosNino.elegido('Vaca')), findsOneWidget);
    expect(find.bySemanticsLabel('Caballo'), findsOneWidget);
    semantics.dispose();
  });

  test('traduce nombres antiguos y descarta los que ya no existen', () {
    expect(
      animalsByName(['Bovino', 'Vaca', 'Dragón']).map((animal) => animal.name),
      ['Vaca', 'Vaca'],
    );
    expect(animalsByName(const []), isEmpty);
    expect(
      animalsByName(animalCatalog.map((animal) => animal.name)).length,
      28,
    );
  });
}

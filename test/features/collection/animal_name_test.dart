import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/animal_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Ancho de la ficha de un animal en un móvil estrecho: es donde
  /// "Hipopótamo" y "Rinoceronte" se partían a mitad de palabra.
  const anchoFicha = 140.0;

  Future<void> pumpName(
    WidgetTester tester,
    String name, {
    double textScale = 1,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: MichiTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: anchoFicha,
              child: AnimalName(
                name: name,
                style: MichiTheme.light().textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('escribe el nombre entero y en una sola línea', (tester) async {
    for (final animal in animalCatalog) {
      await pumpName(tester, animal.name);

      // Una línea y sin partir palabras: lo que se pinta es el nombre
      // completo, encogido si hace falta, nunca "Hipopótam / o".
      final texto = tester.widget<Text>(find.text(animal.name));
      expect(texto.maxLines, 1, reason: animal.name);
      expect(texto.softWrap, isFalse, reason: animal.name);
      expect(
        tester.getSize(find.byType(AnimalName)).width,
        lessThanOrEqualTo(anchoFicha),
        reason: '${animal.name} no cabe en la ficha',
      );
      expect(tester.takeException(), isNull, reason: animal.name);
    }
  });

  testWidgets('sigue cabiendo con la letra al doble', (tester) async {
    await pumpName(tester, 'Hipopótamo', textScale: 2);

    expect(
      tester.getSize(find.byType(AnimalName)).width,
      lessThanOrEqualTo(anchoFicha),
    );
    expect(tester.takeException(), isNull);
  });
}

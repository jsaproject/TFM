import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprueba las reglas de la FASE 2 del plan UX sobre todos los textos que
/// lee el niño. Es la red que evita que la próxima frase de adulto se cuele.
void main() {
  final revisables = TextosNino.revisables;

  test('ninguna frase del niño pasa de ocho palabras', () {
    for (final texto in revisables) {
      final palabras = texto
          .split(RegExp(r'\s+'))
          .where((palabra) => palabra.isNotEmpty);
      expect(
        palabras.length,
        lessThanOrEqualTo(8),
        reason: 'Demasiado larga: "$texto"',
      );
    }
  });

  test('ninguna frase del niño usa una palabra de adulto', () {
    for (final texto in revisables) {
      final palabras = texto
          .toLowerCase()
          .split(RegExp(r'[^a-záéíóúüñ]+'))
          .where((palabra) => palabra.isNotEmpty)
          .toSet();
      for (final prohibida in TextosNino.palabrasProhibidas) {
        expect(
          palabras,
          isNot(contains(prohibida)),
          reason: 'La palabra "$prohibida" aparece en "$texto"',
        );
      }
    }
  });

  test('ningún número del niño lleva porcentaje ni decimales', () {
    for (final texto in revisables) {
      expect(texto, isNot(contains('%')), reason: texto);
      expect(
        RegExp(r'\d+[.,]\d').hasMatch(texto),
        isFalse,
        reason: 'Decimales en "$texto"',
      );
    }
  });

  test('los contadores concuerdan en singular y plural', () {
    expect(TextosNino.fotos(1), '1 foto');
    expect(TextosNino.fotos(3), '3 fotos');
    expect(TextosNino.animalConFotos('Vaca', 1), 'Vaca, 1 foto');
  });

  test('la fecha de una foto se escribe con dos cifras', () {
    expect(TextosNino.fechaDeLaFoto(DateTime(2026, 8, 5)), 'El 05/08/2026');
  });

  test('la lista de textos revisables no se queda vacía ni con huecos', () {
    expect(revisables, isNotEmpty);
    for (final texto in revisables) {
      expect(texto.trim(), isNotEmpty);
    }
  });
}

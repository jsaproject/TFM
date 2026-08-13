import 'dart:math' as math;

import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aplica Andika a los temas claro y oscuro', () {
    for (final theme in [MichiTheme.light(), MichiTheme.dark()]) {
      for (final style in [
        theme.textTheme.displaySmall,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.labelLarge,
      ]) {
        expect(style?.fontFamily, MichiTokens.fontFamily);
      }
    }
  });

  test('mantiene contraste suficiente en la paleta clara y oscura', () {
    final themes = [
      (
        theme: MichiTheme.light(),
        primary: MichiTokens.naranja,
        secondary: MichiTokens.verde,
        tertiary: MichiTokens.amarillo,
        error: MichiTokens.rojo,
        surface: MichiTokens.crema,
      ),
      (
        theme: MichiTheme.dark(),
        primary: MichiTokens.naranjaClaro,
        secondary: MichiTokens.verdeClaro,
        tertiary: MichiTokens.amarilloClaro,
        error: MichiTokens.rojoClaro,
        surface: MichiTokens.fondoOscuro,
      ),
    ];

    for (final entry in themes) {
      final scheme = entry.theme.colorScheme;
      expect(scheme.primary, entry.primary);
      expect(scheme.secondary, entry.secondary);
      expect(scheme.tertiary, entry.tertiary);
      expect(scheme.error, entry.error);
      expect(scheme.surface, entry.surface);
      for (final pair in [
        (background: scheme.primary, foreground: scheme.onPrimary),
        (background: scheme.secondary, foreground: scheme.onSecondary),
        (background: scheme.tertiary, foreground: scheme.onTertiary),
        (background: scheme.error, foreground: scheme.onError),
        (background: scheme.surface, foreground: scheme.onSurface),
      ]) {
        expect(
          _contrastRatio(pair.background, pair.foreground),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  testWidgets('aplica dianas táctiles de al menos 64 dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('filled-button'),
                onPressed: () {},
                child: const Text('Acción'),
              ),
              OutlinedButton(
                key: const Key('outlined-button'),
                onPressed: () {},
                child: const Text('Acción'),
              ),
              IconButton(
                key: const Key('icon-button'),
                onPressed: () {},
                icon: const Icon(Icons.pets),
              ),
              FilterChip(
                key: const Key('filter-chip'),
                label: const Text('Filtro'),
                selected: false,
                onSelected: (_) {},
              ),
              const ListTile(key: Key('list-tile'), title: Text('Ajuste')),
            ],
          ),
        ),
      ),
    );

    for (final key in [
      'filled-button',
      'outlined-button',
      'icon-button',
      'filter-chip',
      'list-tile',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(MichiTokens.touchTargetMin),
      );
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = _relativeLuminance(first);
  final secondLuminance = _relativeLuminance(second);
  return (math.max(firstLuminance, secondLuminance) + 0.05) /
      (math.min(firstLuminance, secondLuminance) + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

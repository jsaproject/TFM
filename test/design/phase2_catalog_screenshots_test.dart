@Tags(['design'])
library;

import 'dart:io';

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catálogo visual solo para pruebas. No se registra como ruta de la app.
///
/// Generar las 16 capturas con:
/// `MICHI_DESIGN=1 flutter test test/design/phase2_catalog_screenshots_test.dart --update-goldens`
void main() {
  final enabled = Platform.environment['MICHI_DESIGN'] == '1';
  const widths = [320.0, 390.0, 768.0, 1180.0];

  setUpAll(_loadAppFonts);

  for (final brightness in Brightness.values) {
    for (final textScale in [1.0, 2.0]) {
      for (final width in widths) {
        final name =
            'fase2-${width.toInt()}-${brightness.name}-${textScale.toInt()}00';
        testWidgets(skip: !enabled, name, (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _catalog(
              theme: brightness == Brightness.light
                  ? MichiTheme.light()
                  : MichiTheme.dark(),
              textScaler: TextScaler.linear(textScale),
            ),
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}

Future<void> _loadAppFonts() async {
  const families = {
    'Andika': [
      'assets/fonts/Andika-Regular.ttf',
      'assets/fonts/Andika-Bold.ttf',
    ],
    'Atkinson Hyperlegible': [
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
      'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    ],
  };
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final asset in family.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

Widget _catalog({required ThemeData theme, required TextScaler textScaler}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MichiTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EditorialHeader(
                    kicker: 'Cuaderno de campo',
                    title: 'El sistema de diseño de Michi',
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  HeroSection(
                    title: 'Una foto cada vez',
                    description:
                        'Los títulos crecen sin depender de alturas fijas.',
                    action: MichiPrimaryButton(
                      label: 'Guardar descubrimiento',
                      icon: Icons.bookmark_add_outlined,
                      onPressed: () {},
                    ),
                    child: PhotoFrame(
                      semanticLabel: 'Marco de ejemplo para una foto de animal',
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  const CompactProgress(
                    value: 0.4,
                    label: '12 de 28 animales encontrados',
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  MichiFilterChip(
                    label: 'Animales vistos',
                    selected: true,
                    onSelected: (_) {},
                  ),
                  const SizedBox(height: MichiTokens.space12),
                  const MichiStatusBadge(
                    label: 'Descubrimiento nuevo',
                    icon: Icons.auto_awesome_outlined,
                    tone: MichiStatusTone.discovery,
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  StatePanel(
                    icon: Icons.wifi_off_outlined,
                    title: 'Ahora no hay conexión',
                    description: 'Comprueba internet y vuelve a intentarlo.',
                    semanticLabel: 'No hay conexión',
                    action: MichiSecondaryButton(
                      label: 'Reintentar',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  AdultSection(
                    title: 'Opciones de adultos',
                    description:
                        'Una sección sobria, separada de la exploración.',
                    child: MichiDestructiveButton(
                      label: 'Eliminar datos',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

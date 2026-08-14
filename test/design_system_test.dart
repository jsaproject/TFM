import 'dart:math' as math;

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los roles semánticos conservan contraste AA en ambos temas', () {
    for (final theme in [MichiTheme.light(), MichiTheme.dark()]) {
      final colors = theme.extension<MichiColors>()!;
      final scheme = theme.colorScheme;
      for (final pair in [
        (background: colors.paper, foreground: colors.ink),
        (background: colors.actionPrimary, foreground: colors.onActionPrimary),
        (
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
        (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
        (
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
      ]) {
        expect(
          _contrastRatio(pair.background, pair.foreground),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  test('el tema expresa los estados de botón y foco', () {
    for (final theme in [MichiTheme.light(), MichiTheme.dark()]) {
      final style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor?.resolve({}), isNotNull);
      expect(style.backgroundColor?.resolve({WidgetState.disabled}), isNotNull);
      expect(style.overlayColor?.resolve({WidgetState.pressed}), isNotNull);
      expect(style.overlayColor?.resolve({WidgetState.hovered}), isNotNull);
      expect(style.overlayColor?.resolve({WidgetState.focused}), isNotNull);
      expect(theme.focusColor, theme.extension<MichiColors>()!.focus);
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .width,
        MichiTokens.focusBorderWidth,
      );
    }
  });

  testWidgets('reduce a cero el movimiento decorativo si el sistema lo pide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => MichiAnimatedReveal(
              visible: true,
              child: const Text('Contenido visible'),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      Duration.zero,
    );
  });

  testWidgets('el catálogo es semántico, recibe foco y mantiene dianas', (
    tester,
  ) async {
    await tester.pumpWidget(_catalog(theme: MichiTheme.light()));

    expect(find.bySemanticsLabel('Guardar descubrimiento'), findsOneWidget);
    expect(find.text('Colección completa'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('No se ha podido abrir la foto')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('primary'))).height,
      greaterThanOrEqualTo(MichiTokens.touchTargetMin),
    );
    expect(
      tester.getSize(find.byKey(const Key('filter'))).height,
      greaterThanOrEqualTo(MichiTokens.touchTargetMin),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });

  testWidgets('a 320 px y texto al 200 % no hay overflow en el catálogo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _catalog(theme: MichiTheme.dark(), textScaler: TextScaler.linear(2)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Explora despacio y descubre algo nuevo'), findsOneWidget);
    expect(find.text('Guardar descubrimiento'), findsOneWidget);
  });
}

Widget _catalog({
  required ThemeData theme,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
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
                title: 'Explora despacio y descubre algo nuevo',
              ),
              const SizedBox(height: MichiTokens.space16),
              HeroSection(
                title: 'Una foto cada vez',
                description:
                    'Mira el animal antes de guardar tu descubrimiento.',
                action: SizedBox(
                  width: double.infinity,
                  child: MichiPrimaryButton(
                    key: const Key('primary'),
                    label: 'Guardar descubrimiento',
                    icon: Icons.bookmark_add_outlined,
                    onPressed: () {},
                  ),
                ),
                child: PhotoFrame(
                  semanticLabel: 'Marco para la foto del animal',
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: MichiTokens.space16),
              MichiFilterChip(
                key: const Key('filter'),
                label: 'Animales vistos',
                selected: true,
                onSelected: (_) {},
              ),
              const SizedBox(height: MichiTokens.space12),
              const MichiStatusBadge(
                label: 'Colección completa',
                icon: Icons.check_circle_outline,
                tone: MichiStatusTone.progress,
              ),
              const SizedBox(height: MichiTokens.space16),
              StatePanel(
                icon: Icons.photo_camera_back_outlined,
                title: 'No hemos podido abrir la foto',
                description: 'Elige otra foto o vuelve a intentarlo.',
                semanticLabel: 'No se ha podido abrir la foto',
                action: MichiSecondaryButton(
                  label: 'Reintentar',
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: MichiTokens.space16),
              AdultSection(
                title: 'Ajustes de adultos',
                description: 'Gestiona opciones de la aplicación.',
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

double _contrastRatio(Color first, Color second) {
  final firstLuminance = _relativeLuminance(first);
  final secondLuminance = _relativeLuminance(second);
  return (math.max(firstLuminance, secondLuminance) + 0.05) /
      (math.min(firstLuminance, secondLuminance) + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

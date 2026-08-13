import 'dart:math' as math;

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Lámina de color con el dibujo de un animal.
///
/// Es lo que se ve en las fichas y en las listas. Antes salía un icono de
/// Material (una colmena por el oso, un triángulo por el rinoceronte) que no
/// le decía nada a un niño que aún no lee. La lámina es la misma para los 28
/// animales: solo una docena tiene ilustración propia, y mezclarlas dejaba una
/// cuadrícula a medias.
class AnimalPortrait extends StatelessWidget {
  const AnimalPortrait({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = _AnimalTone.of(colors, animal.name);
    return Semantics(
      label: animal.name,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: tone.gradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            final portrait = side.isFinite
                ? side * MichiTokens.animalPortraitRatio
                : MichiTokens.iconSizeLarge;
            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Un halo detrás del dibujo: da profundidad y despega al
                  // animal del fondo sin necesitar una ilustración.
                  Container(
                    width: portrait * 1.5,
                    height: portrait * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.halo,
                    ),
                  ),
                  _Emoji(emoji: animal.emoji, size: portrait),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// La ilustración del animal, cuando la hay, y su lámina cuando no.
///
/// Se reserva para la ficha del animal, que es donde una imagen grande aporta
/// algo; en las cuadrículas manda [AnimalPortrait].
class AnimalImage extends StatelessWidget {
  const AnimalImage({super.key, required this.animal, this.fit = BoxFit.cover});

  final Animal animal;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = animal.imageAsset;
    if (asset == null) return AnimalPortrait(animal: animal);
    return Image.asset(
      asset,
      fit: fit,
      semanticLabel: animal.name,
      errorBuilder: (_, _, _) => AnimalPortrait(animal: animal),
    );
  }
}

/// El mismo retrato, en pequeño y redondo, para listas y fichas.
class AnimalAvatar extends StatelessWidget {
  const AnimalAvatar({
    super.key,
    required this.animal,
    this.size = MichiTokens.animalAvatarSize,
  });

  final Animal? animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final animal = this.animal;
    return Semantics(
      label: animal?.name,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _AnimalTone.of(colors, animal?.name ?? '').gradient,
          ),
          alignment: Alignment.center,
          child: animal == null
              ? Icon(
                  Icons.pets,
                  size: size * MichiTokens.animalAvatarRatio,
                  color: colors.onSurfaceVariant,
                )
              : _Emoji(
                  emoji: animal.emoji,
                  size: size * MichiTokens.animalAvatarRatio,
                ),
        ),
      ),
    );
  }
}

/// El dibujo del animal. No sigue al tamaño de letra del sistema porque es
/// ilustración, no texto: crecer con él descuadraría la lámina.
class _Emoji extends StatelessWidget {
  const _Emoji({required this.emoji, required this.size});

  /// Tipografías de emoji de cada plataforma. Móvil las encuentra solo, pero
  /// nombrarlas asegura el dibujo en escritorio, web y en las pruebas.
  static const _emojiFonts = <String>[
    'Noto Color Emoji',
    'Apple Color Emoji',
    'Segoe UI Emoji',
  ];

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    emoji,
    textScaler: TextScaler.noScaling,
    style: TextStyle(
      fontSize: size,
      height: 1.1,
      fontFamilyFallback: _emojiFonts,
    ),
  );
}

/// Color de la lámina de un animal.
///
/// Es estable: el mismo animal sale siempre del mismo color, y el color sale
/// del tema, no de un valor suelto.
class _AnimalTone {
  const _AnimalTone(this.gradient, this.halo);

  final Gradient gradient;
  final Color halo;

  static _AnimalTone of(ColorScheme colors, String name) {
    final bases = <Color>[
      colors.primaryContainer,
      colors.secondaryContainer,
      colors.tertiaryContainer,
      colors.surfaceContainerHigh,
    ];
    final total = name.codeUnits.fold(0, (sum, unit) => sum + unit);
    final base = bases[total % bases.length];
    return _AnimalTone(
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, colors.surface, 0.25)!,
          Color.lerp(base, colors.surfaceContainerHighest, 0.55)!,
        ],
      ),
      colors.surfaceContainerLowest.withValues(alpha: 0.45),
    );
  }
}

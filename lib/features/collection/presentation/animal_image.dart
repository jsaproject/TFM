import 'dart:math' as math;

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Ilustración de un animal del catálogo.
///
/// Mientras la mayoría de los animales no tenga dibujo propio, este widget
/// pinta el icono del animal a tamaño grande sobre uno de los colores del
/// tema. El icono nunca se repite dentro del catálogo actual y el color rota,
/// así que dos fichas seguidas no se confunden aunque no haya dibujos.
class AnimalImage extends StatelessWidget {
  const AnimalImage({super.key, required this.animal, this.fit = BoxFit.cover});

  final Animal animal;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = animal.imageAsset;
    if (asset == null) return _Fallback(animal: animal);
    return Image.asset(
      asset,
      fit: fit,
      semanticLabel: animal.name,
      errorBuilder: (_, _, _) => _Fallback(animal: animal),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = _tone(colors, animal.name);
    return Semantics(
      label: animal.name,
      image: true,
      child: ColoredBox(
        color: background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            return Center(
              child: Icon(
                animal.icon,
                size: side.isFinite
                    ? side * MichiTokens.animalIconRatio
                    : MichiTokens.iconSizeLarge,
                color: foreground,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Reparte los animales entre cuatro parejas del esquema de color. Es
  /// estable: el mismo animal sale siempre del mismo color, y el color sale
  /// del tema, no de un valor suelto.
  static (Color, Color) _tone(ColorScheme colors, String name) {
    final tones = <(Color, Color)>[
      (colors.primaryContainer, colors.onPrimaryContainer),
      (colors.secondaryContainer, colors.onSecondaryContainer),
      (colors.tertiaryContainer, colors.onTertiaryContainer),
      (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    ];
    final total = name.codeUnits.fold(0, (sum, unit) => sum + unit);
    return tones[total % tones.length];
  }
}

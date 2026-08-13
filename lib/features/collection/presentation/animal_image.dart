import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Ilustración de un grupo del catálogo.
///
/// Al pasar de diez animales a cuarenta y dos grupos, la mayoría se quedó sin
/// ilustración propia. Este widget muestra el icono del grupo en su lugar, y
/// también cuando el asset existe pero no se puede decodificar.
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
    return Semantics(
      label: animal.name,
      image: true,
      child: ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(
            animal.icon,
            size: MichiTokens.iconSizeProminent,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

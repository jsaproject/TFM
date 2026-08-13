import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Nombre de un animal dentro de una ficha estrecha.
///
/// "Hipopótamo" y "Rinoceronte" no caben a lo ancho de una ficha, y una sola
/// palabra no tiene por dónde partirse: Flutter la cortaba a mitad de letra
/// ("Hipopótam / o"). Aquí el nombre se encoge lo justo para caber entero en
/// una línea, así que también aguanta el texto grande del sistema.
class AnimalName extends StatelessWidget {
  const AnimalName({
    super.key,
    required this.name,
    this.style,
    this.textAlign = TextAlign.center,
    this.color,
  });

  final String name;
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.titleMedium;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.start
          ? Alignment.centerLeft
          : Alignment.center,
      child: Text(
        name,
        maxLines: 1,
        softWrap: false,
        textAlign: textAlign,
        style: color == null ? baseStyle : baseStyle?.copyWith(color: color),
      ),
    );
  }
}

/// Cuántas fotos tiene el niño de un animal, en una pastilla pequeña.
class AnimalCountBadge extends StatelessWidget {
  const AnimalCountBadge({super.key, required this.label, required this.owned});

  final String label;

  /// Los que ya están en la colección se marcan en verde; los que faltan se
  /// quedan en gris para que la diferencia se vea sin leer.
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: owned ? colors.secondaryContainer : colors.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MichiTokens.space12,
          vertical: MichiTokens.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              owned ? Icons.check_circle : Icons.photo_camera_outlined,
              size: MichiTokens.iconSizeSmall,
              color: owned
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: MichiTokens.space4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: owned
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

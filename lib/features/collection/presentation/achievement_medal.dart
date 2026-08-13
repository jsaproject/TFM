import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';

/// Medalla dibujada: un círculo con el icono del logro y el nombre debajo.
///
/// Las que faltan se ven apagadas y con candado, para que el niño sepa que
/// existen y que aún puede ganarlas.
class AchievementMedal extends StatelessWidget {
  const AchievementMedal({
    super.key,
    required this.achievement,
    required this.earned,
    this.large = false,
  });

  final Achievement achievement;
  final bool earned;

  /// Tamaño de fiesta, el de la celebración. El normal es el de la colección.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = large ? MichiTokens.medalSizeLarge : MichiTokens.medalSize;
    final background = earned
        ? colors.tertiary
        : colors.surfaceContainerHighest;
    final foreground = earned ? colors.onTertiary : colors.onSurfaceVariant;
    return Semantics(
      label: earned
          ? TextosNino.medallaGanada(achievement.label)
          : TextosNino.medallaPorGanar(achievement.label),
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: earned ? colors.onTertiaryContainer : colors.outline,
                    width: MichiTokens.medalBorderWidth,
                  ),
                ),
                child: Icon(
                  earned ? achievement.icon : Icons.lock_outline,
                  size: large
                      ? MichiTokens.iconSizeHero
                      : MichiTokens.iconSizeProminent,
                  color: foreground,
                ),
              ),
              const SizedBox(height: MichiTokens.space8),
              // Flexible y a dos líneas: en la fila de la colección el alto
              // está acotado y el nombre no puede desbordarlo.
              Flexible(
                child: Text(
                  achievement.label,
                  textAlign: TextAlign.center,
                  maxLines: MichiTokens.medalLabelLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: earned ? colors.onSurface : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

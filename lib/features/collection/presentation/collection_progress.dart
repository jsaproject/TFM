import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/presentation/achievement_medal.dart';
import 'package:animalspredictor/features/collection/presentation/animal_image.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:flutter/material.dart';

/// Cuántos animales lleva el niño y cuántos le faltan.
///
/// Vive en dos sitios: la pantalla de la foto, donde es la única pista del
/// progreso mientras hace fotos, y la cabecera de la colección, donde además
/// enseña el último animal y las medallas.
class CollectionProgress extends StatelessWidget {
  const CollectionProgress({
    super.key,
    required this.collection,
    this.detailed = false,
  });

  final UserCollection collection;

  /// Añade el último animal guardado y la fila de medallas.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = animalCatalog.length;
    final discovered = collection.discovered;
    final missing = total - discovered;
    final latest = collection.lastDiscoveredAnimal;
    return Container(
      decoration: ShapeDecoration(
        shape: MichiTokens.animalCardShape.copyWith(
          side: BorderSide(
            color: colors.outlineVariant,
            width: MichiTokens.cardBorderWidth,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secondaryContainer,
            Color.lerp(colors.secondaryContainer, colors.surface, 0.55)!,
          ],
        ),
      ),
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // El conteo, grande y delante: es el dato que el niño mira.
              Text(
                '$discovered',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: MichiTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextosNino.tienesAnimales(discovered, total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      missing <= 0
                          ? TextosNino.yaEstanTodos
                          : TextosNino.teFaltan(missing),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MichiTokens.space12),
          LinearProgressIndicator(
            value: discovered / total,
            semanticsLabel: TextosNino.tuProgreso,
            color: colors.secondary,
            backgroundColor: colors.surfaceContainerLowest.withValues(
              alpha: 0.6,
            ),
          ),
          if (detailed && latest != null) ...[
            const SizedBox(height: MichiTokens.space12),
            _LatestAnimal(name: latest),
          ],
        ],
      ),
    );
  }
}

/// La fila de medallas de la colección, con su título.
///
/// Fuera de la tarjeta de progreso: dentro empujaba la cuadrícula de animales
/// por debajo de la pantalla, y lo que el niño viene a ver son sus animales.
class CollectionMedals extends StatelessWidget {
  const CollectionMedals({super.key, required this.collection});

  final UserCollection collection;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        TextosNino.misMedallas,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: MichiTokens.space12),
      _Medals(collection: collection),
    ],
  );
}

/// El último animal guardado, con su retrato: es el recuerdo más fresco.
class _LatestAnimal extends StatelessWidget {
  const _LatestAnimal({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: TextosNino.elUltimo(name),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surfaceContainerLowest.withValues(alpha: 0.7),
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MichiTokens.space8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimalAvatar(
                  animal: animalByName[name],
                  size: MichiTokens.iconSizeProminent,
                ),
                const SizedBox(width: MichiTokens.space12),
                Flexible(
                  child: Text(
                    TextosNino.elUltimo(name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: MichiTokens.space8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Medals extends StatelessWidget {
  const _Medals({required this.collection});
  final UserCollection collection;

  @override
  Widget build(BuildContext context) {
    final earned = earnedAchievements(
      collection,
    ).map((achievement) => achievement.id).toSet();
    // En fila y a lo ancho: así las ocho medallas caben sin empujar la
    // cuadrícula de animales fuera de la pantalla. El alto del nombre sigue al
    // tamaño de letra del sistema para que no se corte al ampliarlo.
    return SizedBox(
      height:
          MichiTokens.medalSize +
          MichiTokens.space8 +
          MediaQuery.textScalerOf(context).scale(
            MichiTokens.medalLabelLineHeight * MichiTokens.medalLabelLines,
          ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: achievementCatalog.length,
        separatorBuilder: (_, _) => const SizedBox(width: MichiTokens.space16),
        itemBuilder: (context, index) {
          final achievement = achievementCatalog[index];
          return AchievementMedal(
            achievement: achievement,
            earned: earned.contains(achievement.id),
          );
        },
      ),
    );
  }
}

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/presentation/achievement_medal.dart';
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
    final total = animalCatalog.length;
    final discovered = collection.discovered;
    final missing = total - discovered;
    final latest = collection.lastDiscoveredAnimal;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TextosNino.tuProgreso,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MichiTokens.space8),
            Text(TextosNino.tienesAnimales(discovered, total)),
            const SizedBox(height: MichiTokens.space8),
            LinearProgressIndicator(
              value: discovered / total,
              semanticsLabel: TextosNino.tuProgreso,
            ),
            const SizedBox(height: MichiTokens.space8),
            Text(
              missing <= 0
                  ? TextosNino.yaEstanTodos
                  : TextosNino.teFaltan(missing),
            ),
            if (detailed) ...[
              if (latest != null) ...[
                const SizedBox(height: MichiTokens.space12),
                Text(TextosNino.elUltimo(latest)),
              ],
              const SizedBox(height: MichiTokens.space16),
              Text(
                TextosNino.misMedallas,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space12),
              _Medals(collection: collection),
            ],
          ],
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

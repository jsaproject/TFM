import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:flutter/foundation.dart';

/// Lo que hay que celebrar después de guardar una foto.
///
/// Lo calcula quien guarda (el `AppShell`) y lo pinta la celebración, para que
/// la pantalla no tenga que preguntarle nada a la colección.
@immutable
class Celebration {
  const Celebration({
    required this.animal,
    this.savedToCollection = true,
    this.isNewAnimal = false,
    this.newAchievements = const [],
  });

  final String animal;

  /// Un invitado no tiene colección: se le celebra la foto, pero no se le
  /// dice que ya tiene el animal.
  final bool savedToCollection;

  /// Primera vez que este animal entra en la colección.
  final bool isNewAnimal;

  /// Medallas que se ganan con esta foto y que aún no se han celebrado.
  final List<Achievement> newAchievements;

  /// Un animal nuevo o una medalla merecen fiesta; una foto repetida se
  /// resuelve en menos de un segundo para no cansar.
  bool get isBig => isNewAnimal || newAchievements.isNotEmpty;

  Duration get duration => isBig
      ? MichiTokens.durationCelebration
      : MichiTokens.durationCelebrationShort;
}

/// Qué se celebra al añadir una foto de [animal] a [collection].
///
/// [collection] es la colección de antes de guardar: de ahí sale si el animal
/// es nuevo y qué medallas aparecen que antes no estaban.
Celebration celebrationFor(UserCollection collection, String animal) =>
    Celebration(
      animal: animal,
      isNewAnimal: (collection.counts[animal] ?? 0) == 0,
      newAchievements: unseenAchievements(collection.withPhotoOf(animal)),
    );

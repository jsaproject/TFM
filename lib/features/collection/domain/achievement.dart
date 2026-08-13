import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:flutter/material.dart';

/// Lo que hay que juntar para ganar una medalla.
///
/// Cada meta sabe contar por dónde va el niño y cuánto le falta; la pantalla
/// solo pinta esos dos números.
@immutable
sealed class AchievementGoal {
  const AchievementGoal();

  /// Cuánto lleva conseguido de esta meta.
  int progressIn(UserCollection collection);

  /// Cuánto hace falta para ganarla.
  int get target;
}

/// Contar fotos guardadas, se repita el animal o no.
class PhotoGoal extends AchievementGoal {
  const PhotoGoal(this.target);

  @override
  final int target;

  @override
  int progressIn(UserCollection collection) => collection.totalPhotos;
}

/// Contar animales distintos del catálogo actual.
class AnimalGoal extends AchievementGoal {
  const AnimalGoal(this.target);

  @override
  final int target;

  @override
  int progressIn(UserCollection collection) => collection.discovered;
}

/// Completar todos los animales de un sitio: la granja, la casa o el zoo.
class HabitatGoal extends AchievementGoal {
  const HabitatGoal(this.habitat);

  final AnimalHabitat habitat;

  @override
  int get target => animalsInHabitat(habitat).length;

  @override
  int progressIn(UserCollection collection) => collection.discoveredIn(habitat);
}

@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.label,
    required this.icon,
    required this.goal,
  });

  /// Clave con la que se guarda en Firestore que ya se ha celebrado. No se
  /// puede cambiar sin dejar huérfanas las medallas ya vistas.
  final String id;

  final String label;
  final IconData icon;
  final AchievementGoal goal;

  int progressIn(UserCollection collection) => goal.progressIn(collection);
  int get target => goal.target;

  bool isEarnedBy(UserCollection collection) =>
      progressIn(collection) >= target;
}

/// Las ocho medallas, de la más fácil a la más difícil.
///
/// No es `const` porque las metas de sitio sacan su objetivo del catálogo: si
/// mañana la granja tiene un animal más, la medalla se ajusta sola.
final achievementCatalog = List<Achievement>.unmodifiable(<Achievement>[
  const Achievement(
    id: 'primera_foto',
    label: TextosNino.logroPrimeraFoto,
    icon: Icons.photo_camera,
    goal: PhotoGoal(1),
  ),
  const Achievement(
    id: 'cinco_animales',
    label: TextosNino.logroCincoAnimales,
    icon: Icons.star,
    goal: AnimalGoal(5),
  ),
  const Achievement(
    id: 'diez_animales',
    label: TextosNino.logroDiezAnimales,
    icon: Icons.auto_awesome,
    goal: AnimalGoal(10),
  ),
  const Achievement(
    id: 'veinte_animales',
    label: TextosNino.logroVeinteAnimales,
    icon: Icons.workspace_premium,
    goal: AnimalGoal(20),
  ),
  const Achievement(
    id: 'granja',
    label: TextosNino.logroGranja,
    icon: Icons.agriculture,
    goal: HabitatGoal(AnimalHabitat.granja),
  ),
  const Achievement(
    id: 'casa',
    label: TextosNino.logroCasa,
    icon: Icons.home,
    goal: HabitatGoal(AnimalHabitat.casa),
  ),
  const Achievement(
    id: 'zoo',
    label: TextosNino.logroZoo,
    icon: Icons.forest,
    goal: HabitatGoal(AnimalHabitat.salvaje),
  ),
  Achievement(
    id: 'todos',
    label: TextosNino.logroTodos,
    icon: Icons.emoji_events,
    goal: AnimalGoal(animalCatalog.length),
  ),
]);

/// Medallas ya ganadas.
List<Achievement> earnedAchievements(UserCollection collection) => [
  for (final achievement in achievementCatalog)
    if (achievement.isEarnedBy(collection)) achievement,
];

/// Medallas ganadas que el niño todavía no ha visto celebrar.
///
/// Se calcula sobre la colección resultante de guardar la foto
/// ([UserCollection.withPhotoOf]); lo que ya se celebró vive en
/// [UserCollection.seenAchievements].
List<Achievement> unseenAchievements(UserCollection collection) => [
  for (final achievement in earnedAchievements(collection))
    if (!collection.seenAchievements.contains(achievement.id)) achievement,
];

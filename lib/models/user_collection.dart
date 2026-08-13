import 'package:animalspredictor/animal_catalog.dart';

class UserCollection {
  const UserCollection({
    this.counts = const {},
    this.lastIdentified = const {},
    this.seenAchievements = const {},
  });

  final Map<String, int> counts;
  final Map<String, DateTime> lastIdentified;

  /// Identificadores de las medallas que el niño ya ha visto celebrar. Sin
  /// esto, cada foto volvería a anunciar las mismas medallas.
  final Set<String> seenAchievements;

  int get discovered =>
      counts.keys.where(currentAnimalByName.containsKey).length;
  int get totalPhotos => counts.values.fold(0, (total, count) => total + count);
  bool get isEmpty => counts.isEmpty;

  /// Cuántos animales del catálogo actual tiene ya de un sitio concreto.
  int discoveredIn(AnimalHabitat habitat) => animalsInHabitat(
    habitat,
  ).where((animal) => (counts[animal.name] ?? 0) > 0).length;

  /// Cómo queda la colección en cuanto se guarda una foto de [animal].
  ///
  /// La celebración necesita saber si el animal es nuevo y qué medallas se
  /// ganan sin esperar a que Firestore devuelva el documento actualizado.
  UserCollection withPhotoOf(String animal, {DateTime? at}) => UserCollection(
    counts: {...counts, animal: (counts[animal] ?? 0) + 1},
    lastIdentified: {...lastIdentified, animal: at ?? DateTime.now()},
    seenAchievements: seenAchievements,
  );

  String? get lastDiscoveredAnimal {
    String? latestAnimal;
    var latestDate = DateTime.fromMillisecondsSinceEpoch(0);
    for (final entry in lastIdentified.entries) {
      if (animalByName.containsKey(entry.key) &&
          entry.value.isAfter(latestDate)) {
        latestAnimal = entry.key;
        latestDate = entry.value;
      }
    }
    return latestAnimal;
  }

  DateTime? get lastDiscoveredAt {
    final animal = lastDiscoveredAnimal;
    return animal == null ? null : lastIdentified[animal];
  }
}

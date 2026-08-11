import 'package:animalspredictor/animal_catalog.dart';

class UserCollection {
  const UserCollection({
    this.counts = const {},
    this.lastIdentified = const {},
  });

  final Map<String, int> counts;
  final Map<String, DateTime> lastIdentified;

  int get discovered => counts.keys.where(animalByName.containsKey).length;
  int get totalPhotos => counts.values.fold(0, (total, count) => total + count);
  bool get isEmpty => counts.isEmpty;

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

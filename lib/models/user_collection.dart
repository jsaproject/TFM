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
}

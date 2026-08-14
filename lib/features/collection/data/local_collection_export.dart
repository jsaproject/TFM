import 'package:animalspredictor/services/collection_repository.dart';

class LocalCollectionExport {
  const LocalCollectionExport({
    required this.predictions,
    required this.seenAchievementIds,
  });

  final List<CollectionPrediction> predictions;
  final Set<String> seenAchievementIds;

  bool get isEmpty => predictions.isEmpty && seenAchievementIds.isEmpty;
}

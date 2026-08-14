import 'package:realm/realm.dart';

part 'local_collection_models.realm.dart';

@RealmModel()
class _LocalPrediction {
  @PrimaryKey()
  late String id;
  late String animal;
  late DateTime createdAt;
}

@RealmModel()
class _LocalCollectionMetadata {
  @PrimaryKey()
  late String id;
  late List<String> seenAchievements;
}

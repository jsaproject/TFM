// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_collection_models.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class LocalPrediction extends _LocalPrediction
    with RealmEntity, RealmObjectBase, RealmObject {
  LocalPrediction(String id, String animal, DateTime createdAt) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'animal', animal);
    RealmObjectBase.set(this, 'createdAt', createdAt);
  }

  LocalPrediction._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get animal => RealmObjectBase.get<String>(this, 'animal') as String;
  @override
  set animal(String value) => RealmObjectBase.set(this, 'animal', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  Stream<RealmObjectChanges<LocalPrediction>> get changes =>
      RealmObjectBase.getChanges<LocalPrediction>(this);

  @override
  Stream<RealmObjectChanges<LocalPrediction>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<LocalPrediction>(this, keyPaths);

  @override
  LocalPrediction freeze() =>
      RealmObjectBase.freezeObject<LocalPrediction>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'animal': animal.toEJson(),
      'createdAt': createdAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(LocalPrediction value) => value.toEJson();
  static LocalPrediction _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'animal': EJsonValue animal,
        'createdAt': EJsonValue createdAt,
      } =>
        LocalPrediction(fromEJson(id), fromEJson(animal), fromEJson(createdAt)),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(LocalPrediction._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      LocalPrediction,
      'LocalPrediction',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('animal', RealmPropertyType.string),
        SchemaProperty('createdAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class LocalCollectionMetadata extends _LocalCollectionMetadata
    with RealmEntity, RealmObjectBase, RealmObject {
  LocalCollectionMetadata(
    String id, {
    Iterable<String> seenAchievements = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set<RealmList<String>>(
      this,
      'seenAchievements',
      RealmList<String>(seenAchievements),
    );
  }

  LocalCollectionMetadata._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  RealmList<String> get seenAchievements =>
      RealmObjectBase.get<String>(this, 'seenAchievements')
          as RealmList<String>;
  @override
  set seenAchievements(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<LocalCollectionMetadata>> get changes =>
      RealmObjectBase.getChanges<LocalCollectionMetadata>(this);

  @override
  Stream<RealmObjectChanges<LocalCollectionMetadata>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<LocalCollectionMetadata>(this, keyPaths);

  @override
  LocalCollectionMetadata freeze() =>
      RealmObjectBase.freezeObject<LocalCollectionMetadata>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'seenAchievements': seenAchievements.toEJson(),
    };
  }

  static EJsonValue _toEJson(LocalCollectionMetadata value) => value.toEJson();
  static LocalCollectionMetadata _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id} => LocalCollectionMetadata(
        fromEJson(id),
        seenAchievements: fromEJson(ejson['seenAchievements']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(LocalCollectionMetadata._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      LocalCollectionMetadata,
      'LocalCollectionMetadata',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty(
          'seenAchievements',
          RealmPropertyType.string,
          collectionType: RealmCollectionType.list,
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

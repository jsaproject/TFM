import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:flutter_test/flutter_test.dart';

Achievement _achievement(String id) =>
    achievementCatalog.firstWhere((achievement) => achievement.id == id);

UserCollection _withAll(
  Iterable<Animal> animals, {
  Set<String> seen = const {},
}) => UserCollection(
  counts: {for (final animal in animals) animal.name: 1},
  seenAchievements: seen,
);

void main() {
  test('cada medalla de sitio pide todos los animales de ese sitio', () {
    for (final habitat in AnimalHabitat.values) {
      final animals = animalsInHabitat(habitat);
      expect(animals, isNotEmpty, reason: 'sitio vacío: $habitat');
      expect(HabitatGoal(habitat).target, animals.length);
    }
    expect(_achievement('todos').target, animalCatalog.length);
  });

  test('los identificadores de las medallas no se repiten', () {
    final ids = achievementCatalog.map((achievement) => achievement.id);
    expect(ids.toSet(), hasLength(achievementCatalog.length));
  });

  test('una medalla de sitio se gana al completar ese sitio', () {
    final granja = _achievement('granja');
    final animals = animalsInHabitat(AnimalHabitat.granja);

    final casiEntera = _withAll(animals.take(animals.length - 1));
    expect(granja.isEarnedBy(casiEntera), isFalse);
    expect(granja.progressIn(casiEntera), animals.length - 1);

    expect(granja.isEarnedBy(_withAll(animals)), isTrue);
  });

  test('las fotos repetidas cuentan para la medalla de fotos', () {
    const collection = UserCollection(counts: {'Vaca': 3});
    expect(_achievement('primera_foto').isEarnedBy(collection), isTrue);
    expect(_achievement('cinco_animales').isEarnedBy(collection), isFalse);
  });

  test('guardar una foto no altera la colección anterior', () {
    const before = UserCollection(counts: {'Vaca': 1});
    final after = before.withPhotoOf('Vaca', at: DateTime(2026, 8, 13));

    expect(before.counts['Vaca'], 1);
    expect(after.counts['Vaca'], 2);
    expect(after.lastIdentified['Vaca'], DateTime(2026, 8, 13));
  });

  test('una medalla ya celebrada no vuelve a salir', () {
    const conFoto = UserCollection(counts: {'Vaca': 1});
    expect(unseenAchievements(conFoto).map((achievement) => achievement.id), [
      'primera_foto',
    ]);

    const yaVista = UserCollection(
      counts: {'Vaca': 1},
      seenAchievements: {'primera_foto'},
    );
    expect(unseenAchievements(yaVista), isEmpty);
  });

  test('el animal repetido no se celebra como nuevo', () {
    const before = UserCollection(
      counts: {'Vaca': 1},
      seenAchievements: {'primera_foto'},
    );

    final repetido = celebrationFor(before, 'Vaca');
    expect(repetido.isNewAnimal, isFalse);
    expect(repetido.newAchievements, isEmpty);

    final nuevo = celebrationFor(before, 'Gato');
    expect(nuevo.isNewAnimal, isTrue);
  });

  test('la quinta especie estrena medalla y celebración larga', () {
    final before = _withAll(animalCatalog.take(4), seen: {'primera_foto'});

    final celebration = celebrationFor(before, animalCatalog[4].name);

    expect(celebration.isNewAnimal, isTrue);
    expect(celebration.newAchievements.map((achievement) => achievement.id), [
      'cinco_animales',
    ]);
    expect(celebration.duration, MichiTokens.durationCelebration);
  });

  test('una foto repetida sin medalla se celebra en corto', () {
    const repetida = Celebration(animal: 'Vaca');
    expect(repetida.duration, MichiTokens.durationCelebrationShort);
    expect(
      MichiTokens.durationCelebrationShort,
      lessThan(MichiTokens.durationCelebration),
    );
  });
}

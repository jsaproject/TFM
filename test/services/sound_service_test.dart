import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asocia cada grabación real con su animal', () {
    expect(AppSound.forAnimal('Vaca'), AppSound.cow);
    expect(AppSound.forAnimal('Caballo'), AppSound.horse);
    expect(AppSound.forAnimal('Cerdo'), AppSound.pig);
    expect(AppSound.forAnimal('Oveja'), AppSound.sheep);
    expect(AppSound.forAnimal('Cabra'), AppSound.goat);
    expect(AppSound.forAnimal('Burro'), AppSound.donkey);
    expect(AppSound.forAnimal('Gallina'), AppSound.chicken);
    expect(AppSound.forAnimal('Pato'), AppSound.duck);
    expect(AppSound.forAnimal('Perro'), AppSound.dog);
    expect(AppSound.forAnimal('Gato'), AppSound.cat);
    expect(AppSound.forAnimal('Conejo'), AppSound.rabbit);
    expect(AppSound.forAnimal('Loro'), AppSound.parrot);
    expect(AppSound.forAnimal('León'), AppSound.lion);
    expect(AppSound.forAnimal('Elefante'), AppSound.elephant);
    expect(AppSound.forAnimal('Jirafa'), AppSound.giraffe);
    expect(AppSound.forAnimal('Cebra'), AppSound.zebra);
    expect(AppSound.forAnimal('Mono'), AppSound.monkey);
    expect(AppSound.forAnimal('Panda'), AppSound.panda);
    expect(AppSound.forAnimal('Oso'), AppSound.bear);
    expect(AppSound.forAnimal('Pingüino'), AppSound.penguin);
  });

  test('no inventa una grabación para una especie sin fuente', () {
    expect(AppSound.forAnimal('Pez'), isNull);
    expect(AppSound.forAnimal('Tortuga'), isNull);
    expect(AppSound.forAnimal('Hipopótamo'), isNull);
  });

  test('todos los audios declarados están empaquetados', () async {
    final animalSounds = AppSound.values.where(
      (sound) => sound.asset.startsWith('sonidos/animales/'),
    );

    for (final sound in animalSounds) {
      final bytes = await rootBundle.load('assets/${sound.asset}');
      expect(bytes.lengthInBytes, greaterThan(0), reason: sound.asset);
    }
  });
}

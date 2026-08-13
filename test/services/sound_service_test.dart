import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/foundation.dart';
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

  test('vuelve a sonar el mismo animal dos veces seguidas', () async {
    final player = _RecordingSoundPlayer();
    final service = AudioPlayersSoundService(player: player);

    await service.play(AppSound.horse);
    await service.play(AppSound.horse);

    // El «stop» delante de cada «play» es lo que rebobina el sonido: sin él
    // la segunda vez se quedaba mudo.
    expect(player.calls, [
      'stop',
      'play:${AppSound.horse.asset}',
      'stop',
      'play:${AppSound.horse.asset}',
    ]);
    await service.dispose();
  });

  test('no solapa dos sonidos pedidos a la vez', () async {
    final player = _RecordingSoundPlayer();
    final service = AudioPlayersSoundService(player: player);

    await Future.wait([service.play(AppSound.cow), service.play(AppSound.cat)]);

    expect(player.calls, [
      'stop',
      'play:${AppSound.cow.asset}',
      'stop',
      'play:${AppSound.cat.asset}',
    ]);
    await service.dispose();
  });

  test('un fallo del reproductor no interrumpe al siguiente sonido', () async {
    final player = _RecordingSoundPlayer(failOn: AppSound.cow.asset);
    final service = AudioPlayersSoundService(player: player);
    final reported = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await service.play(AppSound.cow);
    await service.play(AppSound.cat);

    expect(player.calls.last, 'play:${AppSound.cat.asset}');
    expect(reported, hasLength(1));
    await service.dispose();
  });

  test('deja de sonar cuando el servicio se cierra', () async {
    final player = _RecordingSoundPlayer();
    final service = AudioPlayersSoundService(player: player);

    await service.dispose();
    await service.play(AppSound.dog);

    expect(player.calls, ['dispose']);
  });
}

class _RecordingSoundPlayer implements SoundPlayer {
  _RecordingSoundPlayer({this.failOn});

  final String? failOn;
  final calls = <String>[];

  @override
  Future<void> play(String asset) async {
    calls.add('play:$asset');
    if (asset == failOn) throw StateError('sin altavoz');
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

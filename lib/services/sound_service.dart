import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Los tres sonidos de la app, uno por momento que un niño celebra.
enum AppSound {
  /// La foto se ha reconocido.
  success('sonidos/acierto.wav'),

  /// El animal ha entrado en la colección.
  saved('sonidos/guardado.wav'),

  /// Se ha ganado una medalla.
  achievement('sonidos/logro.wav');

  const AppSound(this.asset);

  /// Ruta dentro de `assets/`, que es el prefijo que añade `AssetSource`.
  final String asset;
}

/// Reproduce los sonidos de la app.
///
/// La interfaz nunca habla con el reproductor: pide un [AppSound] y este
/// servicio decide cómo suena. Así los tests usan [SilentSoundService] y no
/// necesitan el plugin nativo.
abstract class SoundService {
  Future<void> play(AppSound sound);
  Future<void> dispose();
}

/// No suena nada. Es lo que se usa en los tests y en las plataformas donde no
/// hay reproductor.
class SilentSoundService implements SoundService {
  const SilentSoundService();

  @override
  Future<void> play(AppSound sound) async {}

  @override
  Future<void> dispose() async {}
}

class AudioPlayersSoundService implements SoundService {
  AudioPlayersSoundService({AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? AudioPlayer.new;

  /// El reproductor se crea con el primer sonido, no al arrancar: así el
  /// plugin nativo solo entra en juego si de verdad va a sonar algo.
  final AudioPlayer Function() _createPlayer;
  AudioPlayer? _player;
  bool _disposed = false;

  @override
  Future<void> play(AppSound sound) async {
    if (_disposed) return;
    try {
      final player = await _ready();
      if (_disposed) return;
      await player.play(AssetSource(sound.asset));
    } catch (error, stackTrace) {
      // Que no suene una campanita no puede tumbar la pantalla ni merece un
      // aviso al niño: se deja rastro para el desarrollador y se sigue.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sound_service',
          context: ErrorDescription('al reproducir ${sound.name}'),
        ),
      );
    }
  }

  Future<AudioPlayer> _ready() async {
    final existing = _player;
    if (existing != null) return existing;
    // `respectSilence` es lo que hace que el móvil en silencio siga en
    // silencio. En modo baja latencia el sonido sale al instante del toque.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    final player = _createPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    return _player = player;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player?.dispose();
  }
}

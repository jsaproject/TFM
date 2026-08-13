import 'dart:async';

import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aplica un ajuste únicamente cuando termina de guardarse', () async {
    final repository = _SettingsRepositoryStub();
    final controller = SettingsController(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final pendingSave = controller.setTheme(AppThemePreference.dark);

    expect(controller.isLoading, isTrue);
    expect(controller.theme, AppThemePreference.system);
    repository.themeSave.complete();
    expect(await pendingSave, isTrue);
    expect(controller.theme, AppThemePreference.dark);
    expect(controller.isLoading, isFalse);
  });

  test('mantiene el valor anterior y explica un fallo de guardado', () async {
    final repository = _SettingsRepositoryStub(failHaptics: true);
    final controller = SettingsController(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final saved = await controller.setHapticsEnabled(false);

    expect(saved, isFalse);
    expect(controller.hapticsEnabled, isTrue);
    expect(controller.errorMessage, contains('Inténtalo de nuevo'));
  });

  test('el interruptor de sonido decide si se reproduce algo', () async {
    final sounds = _RecordingSoundService();
    final controller = SettingsController(
      _SettingsRepositoryStub(),
      sounds: sounds,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.soundEnabled, isTrue);
    await controller.playSound(AppSound.saved);
    expect(sounds.played, [AppSound.saved]);

    expect(await controller.setSoundEnabled(false), isTrue);
    await controller.playSound(AppSound.achievement);

    expect(controller.soundEnabled, isFalse);
    expect(sounds.played, [AppSound.saved]);
  });

  test('un fallo al guardar el sonido deja el ajuste como estaba', () async {
    final controller = SettingsController(
      _SettingsRepositoryStub(failSound: true),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final saved = await controller.setSoundEnabled(false);

    expect(saved, isFalse);
    expect(controller.soundEnabled, isTrue);
    expect(controller.errorMessage, contains('Inténtalo de nuevo'));
  });
}

class _RecordingSoundService implements SoundService {
  final played = <AppSound>[];

  @override
  Future<void> play(AppSound sound) async => played.add(sound);

  @override
  Future<void> dispose() async {}
}

class _SettingsRepositoryStub implements SettingsRepository {
  _SettingsRepositoryStub({this.failHaptics = false, this.failSound = false});

  final bool failHaptics;
  final bool failSound;
  final themeSave = Completer<void>();

  @override
  Future<ProfileSettings> load() async => const ProfileSettings();

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {
    if (failHaptics) throw StateError('fallo simulado');
  }

  @override
  Future<void> saveSoundEnabled(bool enabled) async {
    if (failSound) throw StateError('fallo simulado');
  }

  @override
  Future<void> saveTheme(AppThemePreference theme) => themeSave.future;
}

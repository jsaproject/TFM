import 'dart:async';

import 'package:animalspredictor/features/profile/data/settings_repository.dart';
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
}

class _SettingsRepositoryStub implements SettingsRepository {
  _SettingsRepositoryStub({this.failHaptics = false});

  final bool failHaptics;
  final themeSave = Completer<void>();

  @override
  Future<ProfileSettings> load() async => const ProfileSettings();

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {
    if (failHaptics) throw StateError('fallo simulado');
  }

  @override
  Future<void> saveTheme(AppThemePreference theme) => themeSave.future;
}

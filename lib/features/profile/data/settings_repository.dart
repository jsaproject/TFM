import 'dart:async';

import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

@immutable
class ProfileSettings {
  const ProfileSettings({
    this.theme = AppThemePreference.system,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
  });

  final AppThemePreference theme;
  final bool hapticsEnabled;
  final bool soundEnabled;
}

abstract class SettingsRepository {
  Future<ProfileSettings> load();
  Future<void> saveTheme(AppThemePreference theme);
  Future<void> saveHapticsEnabled(bool enabled);
  Future<void> saveSoundEnabled(bool enabled);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _themeKey = 'profile.theme';
  static const _hapticsKey = 'profile.haptics_enabled';
  static const _soundKey = 'profile.sound_enabled';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<ProfileSettings> load() async {
    final preferences = await _preferences();
    final storedTheme = preferences.getString(_themeKey);
    final theme = AppThemePreference.values.firstWhere(
      (preference) => preference.name == storedTheme,
      orElse: () => AppThemePreference.system,
    );
    return ProfileSettings(
      theme: theme,
      hapticsEnabled: preferences.getBool(_hapticsKey) ?? true,
      soundEnabled: preferences.getBool(_soundKey) ?? true,
    );
  }

  @override
  Future<void> saveTheme(AppThemePreference theme) async {
    final saved = await (await _preferences()).setString(_themeKey, theme.name);
    if (!saved) throw StateError('No se ha podido guardar el tema.');
  }

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {
    final saved = await (await _preferences()).setBool(_hapticsKey, enabled);
    if (!saved) {
      throw StateError('No se ha podido guardar la respuesta háptica.');
    }
  }

  @override
  Future<void> saveSoundEnabled(bool enabled) async {
    final saved = await (await _preferences()).setBool(_soundKey, enabled);
    if (!saved) throw StateError('No se ha podido guardar el sonido.');
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository, {SoundService? sounds})
    : _sounds = sounds ?? const SilentSoundService();

  final SettingsRepository _repository;

  /// Quien reproduce de verdad. Pasa por aquí para que el interruptor de
  /// sonido se respete en un único sitio y no en cada pantalla.
  final SoundService _sounds;
  AppThemePreference _theme = AppThemePreference.system;
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;
  bool _isLoading = true;
  String? _errorMessage;

  AppThemePreference get theme => _theme;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode => switch (_theme) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final settings = await _repository.load();
      _theme = settings.theme;
      _hapticsEnabled = settings.hapticsEnabled;
      _soundEnabled = settings.soundEnabled;
    } catch (_) {
      _errorMessage = TextosAdulto.errorCargarAjustes;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setTheme(AppThemePreference theme) async {
    if (_isLoading || theme == _theme) return true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveTheme(theme);
      _theme = theme;
      return true;
    } catch (_) {
      _errorMessage = TextosAdulto.errorGuardarTema;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setHapticsEnabled(bool enabled) async {
    if (_isLoading || enabled == _hapticsEnabled) return true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveHapticsEnabled(enabled);
      _hapticsEnabled = enabled;
      return true;
    } catch (_) {
      _errorMessage = TextosAdulto.errorGuardarHaptica;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setSoundEnabled(bool enabled) async {
    if (_isLoading || enabled == _soundEnabled) return true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveSoundEnabled(enabled);
      _soundEnabled = enabled;
      return true;
    } catch (_) {
      _errorMessage = TextosAdulto.errorGuardarSonido;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> provideConfirmationFeedback() async {
    if (_hapticsEnabled && !kIsWeb) await HapticFeedback.mediumImpact();
  }

  /// Suena solo si el adulto lo ha dejado activado.
  Future<void> playSound(AppSound sound) async {
    if (_soundEnabled) await _sounds.play(sound);
  }

  @override
  void dispose() {
    unawaited(_sounds.dispose());
    super.dispose();
  }
}

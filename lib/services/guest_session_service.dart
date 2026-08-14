import 'package:shared_preferences/shared_preferences.dart';

/// Mantiene separado el modo invitado del inicio de sesión de Firebase.
///
/// No contiene datos de la colección: esos viven en Realm. Solo recuerda que
/// la persona eligió continuar sin crear una cuenta.
abstract class GuestSessionService {
  Future<bool> isActive();
  Future<void> start();
  Future<void> stop();
}

class SharedPreferencesGuestSessionService implements GuestSessionService {
  static const _key = 'guest_session_active';

  @override
  Future<bool> isActive() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  @override
  Future<void> start() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }

  @override
  Future<void> stop() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

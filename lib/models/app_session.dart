/// La identidad que usa la interfaz. Un invitado no representa ni crea un
/// usuario de Firebase: solo tiene una colección local en este dispositivo.
class AppSession {
  const AppSession({
    required this.id,
    required this.isAnonymous,
    this.displayName,
    this.email,
  });

  const AppSession.guest()
    : id = 'guest',
      isAnonymous = true,
      displayName = null,
      email = null;

  final String id;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
}

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.email,
    required this.isAnonymous,
    required this.authService,
  });

  final String? email;
  final bool isAnonymous;
  final AuthService authService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.authService.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido cerrar sesión. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: ListView(
      padding: MichiTokens.pagePadding,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(MichiTokens.space16),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: MichiTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isAnonymous
                            ? 'Invitado'
                            : (widget.email ?? 'Usuario'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: MichiTokens.space4),
                      Text(
                        widget.isAnonymous
                            ? 'Tus descubrimientos no se guardan en una colección.'
                            : 'Tu colección está asociada a esta cuenta.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MichiTokens.space24),
        FilledButton.tonalIcon(
          onPressed: _signingOut ? null : _signOut,
          icon: _signingOut
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(_signingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
        ),
      ],
    ),
  );
}

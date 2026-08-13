import 'package:animalspredictor/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';

/// Muestra una explicación breve una sola vez en cada dispositivo.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({
    super.key,
    required this.user,
    required this.authService,
    required this.settings,
  });

  final User user;
  final AuthService authService;
  final SettingsController settings;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool? _seenWelcome;

  @override
  void initState() {
    super.initState();
    _loadWelcomeStatus();
  }

  Future<void> _loadWelcomeStatus() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _seenWelcome = preferences.getBool('seen_welcome') ?? false,
      );
    }
  }

  Future<void> _finishWelcome() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('seen_welcome', true);
    if (mounted) setState(() => _seenWelcome = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenWelcome == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_seenWelcome!) {
      return HomePage(
        user: widget.user,
        authService: widget.authService,
        settings: widget.settings,
      );
    }
    return _WelcomePage(onStart: _finishWelcome);
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.pets,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido a La granja de Michi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  const _WelcomeStep(
                    icon: Icons.camera_alt_outlined,
                    title: 'Haz una foto',
                    text:
                        'Usa la cámara para identificar un animal al momento.',
                  ),
                  const _WelcomeStep(
                    icon: Icons.photo_library_outlined,
                    title: 'O elige de tu galería',
                    text: 'También puedes clasificar una imagen que ya tengas.',
                  ),
                  const _WelcomeStep(
                    icon: Icons.collections_bookmark_outlined,
                    title: 'Completa tu colección',
                    text:
                        'Confirma cada resultado para guardarlo en tu cuenta.',
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: onStart,
                    child: const Text('Empezar a explorar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Semantics(
      label: '$title. $text',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

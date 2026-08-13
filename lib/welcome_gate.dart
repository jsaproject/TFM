import 'package:animalspredictor/home_page.dart';
import 'package:animalspredictor/app_theme.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: MichiTokens.welcomeMaxWidth,
                  ),
                  child: Padding(
                    padding: MichiTokens.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.pets,
                          size: MichiTokens.iconSizeHero,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: MichiTokens.space20),
                        Text(
                          'Bienvenido a La granja de Michi',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: MichiTokens.space24),
                        const _WelcomeStep(
                          icon: Icons.camera_alt_outlined,
                          title: 'Haz una foto',
                          text:
                              'Usa la cámara para identificar un animal al momento.',
                        ),
                        const _WelcomeStep(
                          icon: Icons.photo_library_outlined,
                          title: 'O elige de tu galería',
                          text:
                              'También puedes clasificar una imagen que ya tengas.',
                        ),
                        const _WelcomeStep(
                          icon: Icons.collections_bookmark_outlined,
                          title: 'Completa tu colección',
                          text:
                              'Confirma cada resultado para guardarlo en tu cuenta.',
                        ),
                        const SizedBox(height: MichiTokens.space28),
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
    padding: const EdgeInsets.symmetric(vertical: MichiTokens.space8),
    child: Semantics(
      label: '$title. $text',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: MichiTokens.iconSizeMedium,
          ),
          const SizedBox(width: MichiTokens.space16),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: Theme.of(context).textTheme.titleMedium,
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

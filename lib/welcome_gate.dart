import 'package:animalspredictor/home_page.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/models/app_session.dart';

/// Muestra una explicación breve una sola vez en cada dispositivo.
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({
    super.key,
    required this.session,
    required this.authService,
    required this.settings,
    this.onGuestSignOut,
    this.onDeleteGuestCollection,
  });

  final AppSession session;
  final AuthService authService;
  final SettingsController settings;
  final Future<void> Function()? onGuestSignOut;
  final Future<void> Function()? onDeleteGuestCollection;

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
        session: widget.session,
        authService: widget.authService,
        settings: widget.settings,
        onGuestSignOut: widget.onGuestSignOut,
        onDeleteGuestCollection: widget.onDeleteGuestCollection,
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
                        // La marca, en una pastilla de color: es lo primero
                        // que se ve al abrir la app.
                        Center(
                          child: Container(
                            width: MichiTokens.brandMarkSize,
                            height: MichiTokens.brandMarkSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.pets,
                              size: MichiTokens.iconSizeHero,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: MichiTokens.space20),
                        Text(
                          TextosNino.marca,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: MichiTokens.space24),
                        const _WelcomeStep(
                          icon: Icons.camera_alt_outlined,
                          text: TextosNino.hazUnaFoto,
                        ),
                        const _WelcomeStep(
                          icon: Icons.photo_library_outlined,
                          text: TextosNino.bienvenidaPasoGaleria,
                        ),
                        const _WelcomeStep(
                          icon: Icons.collections_bookmark_outlined,
                          text: TextosNino.bienvenidaPasoColeccion,
                        ),
                        const SizedBox(height: MichiTokens.space28),
                        FilledButton(
                          onPressed: onStart,
                          child: const Text(TextosNino.bienvenidaBoton),
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

/// Un paso del onboarding: una frase corta y una ilustración más grande que
/// ella, para que se entienda sin saber leer.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MichiTokens.space12),
    child: Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: MichiTokens.iconSizeHero,
            ),
            const SizedBox(width: MichiTokens.space16),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    ),
  );
}

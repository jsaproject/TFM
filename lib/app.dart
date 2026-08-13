import 'package:animalspredictor/auth_gate.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:flutter/material.dart';

class AnimalsPredictorApp extends StatefulWidget {
  const AnimalsPredictorApp({super.key, this.settingsRepository});

  final SettingsRepository? settingsRepository;

  @override
  State<AnimalsPredictorApp> createState() => _AnimalsPredictorAppState();
}

class _AnimalsPredictorAppState extends State<AnimalsPredictorApp> {
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController(
      widget.settingsRepository ?? SharedPreferencesSettingsRepository(),
    )..load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _settings,
    builder: (context, _) => MaterialApp(
      title: 'La granja de Michi',
      debugShowCheckedModeBanner: false,
      theme: MichiTheme.light(),
      darkTheme: MichiTheme.dark(),
      themeMode: _settings.themeMode,
      home: AuthGate(settings: _settings),
    ),
  );
}

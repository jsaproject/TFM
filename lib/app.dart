import 'package:animalspredictor/auth_gate.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

class AnimalsPredictorApp extends StatelessWidget {
  const AnimalsPredictorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'La granja de Michi',
    debugShowCheckedModeBanner: false,
    theme: MichiTheme.light(),
    darkTheme: MichiTheme.dark(),
    themeMode: ThemeMode.system,
    home: const AuthGate(),
  );
}

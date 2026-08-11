import 'package:animalspredictor/auth_gate.dart';
import 'package:flutter/material.dart';

class AnimalsPredictorApp extends StatelessWidget {
  const AnimalsPredictorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'La granja de Michi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
      ),
    ),
    home: const AuthGate(),
  );
}

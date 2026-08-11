import 'package:animalspredictor/auth_gate.dart';
import 'package:flutter/material.dart';

class AnimalsPredictorApp extends StatelessWidget {
  const AnimalsPredictorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Animals Predictor',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      useMaterial3: true,
    ),
    home: const AuthGate(),
  );
}

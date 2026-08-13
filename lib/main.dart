import 'package:animalspredictor/app.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/firebase_options.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const AnimalsPredictorApp());
  } catch (_) {
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MichiTheme.light(),
    darkTheme: MichiTheme.dark(),
    themeMode: ThemeMode.system,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: MichiTokens.pagePadding,
          child: Text(TextosAdulto.errorArranque, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}

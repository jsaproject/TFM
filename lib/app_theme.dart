import 'package:flutter/material.dart';

/// Tokens de diseño compartidos de La granja de Michi.
abstract final class MichiTokens {
  static const forest = Color(0xFF285943);
  static const indigo = Color(0xFF324BCD);
  static const cream = Color(0xFFFFF8EC);
  static const amber = Color(0xFFB86D00);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const pagePadding = EdgeInsets.all(space24);

  static const radiusMedium = Radius.circular(16);
  static const radiusLarge = Radius.circular(24);
  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusMedium),
  );
  static const durationShort = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 250);
  static const cardElevation = 1.0;
  static const cardShadow = Color(0x1F000000);
  static const headlineSmall = TextStyle(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const titleLarge = TextStyle(fontWeight: FontWeight.w600);
}

abstract final class MichiTheme {
  static ThemeData light() => _data(_lightScheme);
  static ThemeData dark() => _data(_darkScheme);

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.forest,
    brightness: Brightness.light,
    surface: MichiTokens.cream,
  );
  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.forest,
    brightness: Brightness.dark,
  );

  static ThemeData _data(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: const TextTheme(
      headlineSmall: MichiTokens.headlineSmall,
      titleLarge: MichiTokens.titleLarge,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: MichiTokens.cardElevation,
      shape: MichiTokens.cardShape,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shadowColor: MichiTokens.cardShadow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: MichiTokens.cardShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: MichiTokens.cardShape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

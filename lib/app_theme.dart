import 'package:flutter/material.dart';

/// Tokens de diseño compartidos de La granja de Michi.
abstract final class MichiTokens {
  // Paleta "Granja al sol" — modo claro.
  static const naranja = Color(0xFFF76707);
  static const tinta = Color(0xFF211D18);
  static const verde = Color(0xFF37B24D);
  static const verdeOscuro = Color(0xFF00210A);
  static const amarillo = Color(0xFFFAB005);
  static const ambarOscuro = Color(0xFF3A2600);
  static const rojo = Color(0xFFC92A2A);
  static const crema = Color(0xFFFFF8EC);

  // Paleta "Granja al sol" — modo oscuro.
  static const naranjaClaro = Color(0xFFFF9F45);
  static const naranjaOscuro = Color(0xFF3D1A00);
  static const verdeClaro = Color(0xFF6BD47E);
  static const verdeNoche = Color(0xFF00320F);
  static const amarilloClaro = Color(0xFFFFD43B);
  static const rojoClaro = Color(0xFFFF8A8A);
  static const rojoOscuro = Color(0xFF4A0000);
  static const fondoOscuro = Color(0xFF1A1713);
  static const cremaClara = Color(0xFFF0E7DA);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space28 = 28.0;
  static const space32 = 32.0;
  static const pagePadding = EdgeInsets.all(space24);

  static const authenticationMaxWidth = 480.0;
  static const welcomeMaxWidth = 560.0;
  static const contentMaxWidth = 600.0;
  static const navigationRailBreakpoint = 840.0;
  static const brandMarkSize = 112.0;
  static const squareImageAspectRatio = 1.0;
  static const landscapeImageAspectRatio = 16 / 9;
  static const dividerThickness = 1.0;

  static const radiusMedium = Radius.circular(16);
  static const radiusLarge = Radius.circular(24);
  static const radiusExtraLarge = Radius.circular(32);
  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusMedium),
  );
  static const animalCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusExtraLarge),
  );

  static const durationShort = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 250);
  static const durationCelebration = Duration(milliseconds: 1500);

  static const cardElevation = 1.0;
  static const cardShadowLight = Color(0x1F000000);
  static const cardShadowDark = Color(0x66000000);

  /// Velo sobre la foto mientras se identifica el animal.
  static const veilOverlay = Color(0x33000000);

  static const iconSizeSmall = 20.0;
  static const iconSizeMedium = 32.0;
  static const iconSizeProminent = 40.0;
  static const iconSizeLarge = 64.0;
  static const iconSizeHero = 72.0;

  static const progressIndicatorSize = 20.0;
  static const progressIndicatorStrokeWidth = 2.0;
  static const chipVerticalPadding = 21.0;

  /// Ficha del selector de animales: imagen grande y nombre debajo.
  static const animalChoiceExtent = 176.0;
  static const animalChoiceMaxWidth = 168.0;
  static const animalChoiceMinWidth = 96.0;

  /// Parte de la ficha que ocupa el icono cuando el animal no tiene dibujo.
  static const animalIconRatio = 0.55;

  static const selectionBorderWidth = 4.0;
  static const selectorSheetHeightFactor = 0.92;

  static const navigationBarHeight = 88.0;
  static const navigationBadgePadding = EdgeInsets.symmetric(
    horizontal: space20,
    vertical: space8,
  );

  static const collectionGridMaxCrossAxisExtent = 260.0;
  static const collectionGridMainAxisExtent = 242.0;
  static const collectionHeaderSkeletonHeight = 190.0;
  static const collectionFilterSkeletonHeight = 40.0;
  static const collectionCardSkeletonHeight = 180.0;
  static const historySkeletonItemHeight = 72.0;
  static const historySkeletonItemCount = 6;

  /// Alto y ancho mínimo de cualquier elemento tocable por un niño.
  static const touchTargetMin = 64.0;

  static const fontFamily = 'Andika';

  static const displaySmall = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
  );
  static const headlineMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
  static const headlineSmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static const titleMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  static const bodyLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w400);
  static const bodyMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );
  static const labelLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
}

abstract final class MichiTheme {
  static ThemeData light() => _data(_lightScheme, MichiTokens.cardShadowLight);
  static ThemeData dark() => _data(_darkScheme, MichiTokens.cardShadowDark);

  // Se sigue partiendo de fromSeed para que los ~45 roles del esquema salgan
  // coherentes entre sí, pero primary/secondary/tertiary/error/surface se
  // sobrescriben a mano: con la semilla naranja sola, Material 3 fuerza esos
  // roles a un tono oscuro y apagado en modo claro (ver ANEXO PALETA en
  // docs/PLAN_UX_INFANTIL.txt).
  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.naranja,
    brightness: Brightness.light,
    primary: MichiTokens.naranja,
    onPrimary: MichiTokens.tinta,
    secondary: MichiTokens.verde,
    onSecondary: MichiTokens.verdeOscuro,
    tertiary: MichiTokens.amarillo,
    onTertiary: MichiTokens.ambarOscuro,
    error: MichiTokens.rojo,
    onError: Colors.white,
    surface: MichiTokens.crema,
    onSurface: MichiTokens.tinta,
  );
  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.naranja,
    brightness: Brightness.dark,
    primary: MichiTokens.naranjaClaro,
    onPrimary: MichiTokens.naranjaOscuro,
    secondary: MichiTokens.verdeClaro,
    onSecondary: MichiTokens.verdeNoche,
    tertiary: MichiTokens.amarilloClaro,
    onTertiary: MichiTokens.ambarOscuro,
    error: MichiTokens.rojoClaro,
    onError: MichiTokens.rojoOscuro,
    surface: MichiTokens.fondoOscuro,
    onSurface: MichiTokens.cremaClara,
  );

  static ThemeData _data(ColorScheme scheme, Color cardShadow) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: MichiTokens.fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: const TextTheme(
      displaySmall: MichiTokens.displaySmall,
      headlineMedium: MichiTokens.headlineMedium,
      headlineSmall: MichiTokens.headlineSmall,
      titleLarge: MichiTokens.titleLarge,
      titleMedium: MichiTokens.titleMedium,
      bodyLarge: MichiTokens.bodyLarge,
      bodyMedium: MichiTokens.bodyMedium,
      labelLarge: MichiTokens.labelLarge,
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
      shadowColor: cardShadow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(MichiTokens.touchTargetMin),
        shape: MichiTokens.cardShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(MichiTokens.touchTargetMin),
        shape: MichiTokens.cardShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(
          MichiTokens.touchTargetMin,
          MichiTokens.touchTargetMin,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        iconSize: MichiTokens.iconSizeMedium,
        minimumSize: const Size.square(MichiTokens.touchTargetMin),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: MichiTokens.labelLarge.copyWith(color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(
        horizontal: MichiTokens.space16,
        vertical: MichiTokens.chipVerticalPadding,
      ),
      shape: const StadiumBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      minTileHeight: MichiTokens.touchTargetMin,
      minVerticalPadding: MichiTokens.space12,
    ),
    // La navegación pinta su propia pastilla de color por sección
    // (`AdaptiveNavigationShell`), así que el indicador de Material sobra.
    navigationBarTheme: NavigationBarThemeData(
      height: MichiTokens.navigationBarHeight,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        MichiTokens.labelLarge.copyWith(color: scheme.onSurface),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: Colors.transparent,
      selectedLabelTextStyle: MichiTokens.labelLarge.copyWith(
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: MichiTokens.labelLarge.copyWith(
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(MichiTokens.radiusMedium),
      ),
    ),
  );
}

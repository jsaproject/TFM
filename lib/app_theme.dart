import 'package:flutter/material.dart';

/// Tokens de diseño compartidos de La granja de Michi.
abstract final class MichiTokens {
  // Paleta "Granja al sol" — modo claro.
  static const naranja = Color(0xFFF76707);
  static const naranjaSuave = Color(0xFFFFE2CE);
  static const naranjaTinta = Color(0xFF4A1B00);
  static const tinta = Color(0xFF231C15);
  static const verde = Color(0xFF37B24D);
  static const verdeSuave = Color(0xFFD6F3DB);
  static const verdeOscuro = Color(0xFF00210A);
  static const verdeTinta = Color(0xFF04310F);
  static const amarillo = Color(0xFFF5A623);
  static const amarilloSuave = Color(0xFFFFEFC7);
  static const ambarOscuro = Color(0xFF3A2600);
  static const rojo = Color(0xFFC92A2A);
  static const rojoSuave = Color(0xFFFFDAD6);
  static const rojoTinta = Color(0xFF410002);
  static const crema = Color(0xFFFFFAF3);
  static const cremaSuave = Color(0xFFFFF4E8);
  static const cremaMedia = Color(0xFFFAEBDB);
  static const cremaHonda = Color(0xFFF3E1CE);
  static const perfilClaro = Color(0xFF8B7563);
  static const perfilClaroSuave = Color(0xFFE7D6C4);

  // Paleta "Granja al sol" — modo oscuro.
  static const naranjaClaro = Color(0xFFFFB077);
  static const naranjaOscuro = Color(0xFF3D1A00);
  static const naranjaHondo = Color(0xFF5B2A00);
  static const naranjaTintaClara = Color(0xFFFFDCC2);
  static const verdeClaro = Color(0xFF7CD98F);
  static const verdeNoche = Color(0xFF00320F);
  static const verdeHondo = Color(0xFF14401F);
  static const verdeTintaClara = Color(0xFFC8F0CE);
  static const amarilloClaro = Color(0xFFFFD166);
  static const amarilloHondo = Color(0xFF463200);
  static const amarilloTintaClara = Color(0xFFFFE9AE);
  static const rojoClaro = Color(0xFFFFB4AB);
  static const rojoOscuro = Color(0xFF690005);
  static const rojoHondo = Color(0xFF93000A);
  static const fondoOscuro = Color(0xFF16130F);
  static const fondoOscuroBajo = Color(0xFF1D1915);
  static const fondoOscuroMedio = Color(0xFF241F1A);
  static const fondoOscuroAlto = Color(0xFF2C2620);
  static const fondoOscuroCima = Color(0xFF362F28);
  static const cremaClara = Color(0xFFF3E9DD);
  static const perfilOscuro = Color(0xFFA08D7B);
  static const perfilOscuroSuave = Color(0xFF473E36);

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

  static const radiusSmall = Radius.circular(12);
  static const radiusMedium = Radius.circular(20);
  static const radiusLarge = Radius.circular(28);
  static const radiusExtraLarge = Radius.circular(32);
  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusMedium),
  );
  static const animalCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusLarge),
  );

  /// Los botones son pastillas: se distinguen de las tarjetas de un vistazo y
  /// aciertan mejor con un dedo pequeño.
  static const buttonShape = StadiumBorder();

  /// Borde fino de las tarjetas. Sustituye a la sombra: en modo oscuro una
  /// sombra no se ve y las tarjetas se fundían con el fondo.
  static const cardBorderWidth = 1.0;

  static const durationShort = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 250);

  /// Entrada escalonada de las tarjetas de una pantalla.
  static const durationEntrance = Duration(milliseconds: 320);
  static const delayEntranceStep = Duration(milliseconds: 60);
  static const entranceOffset = 0.12;

  /// Cuánto dura la fiesta al guardar un animal nuevo…
  static const durationCelebration = Duration(milliseconds: 1500);

  /// …y cuánto cuando el animal ya estaba en la colección.
  static const durationCelebrationShort = Duration(milliseconds: 900);

  static const cardElevation = 0.0;
  static const cardShadowLight = Color(0x14000000);
  static const cardShadowDark = Color(0x66000000);

  /// Velo sobre la foto mientras se identifica el animal.
  static const veilOverlay = Color(0x66000000);

  static const iconSizeSmall = 20.0;
  static const iconSizeMedium = 32.0;
  static const iconSizeProminent = 40.0;
  static const iconSizeLarge = 64.0;
  static const iconSizeHero = 72.0;

  static const progressIndicatorSize = 20.0;
  static const progressIndicatorStrokeWidth = 2.0;
  static const progressBarHeight = 14.0;
  static const chipVerticalPadding = 21.0;
  static const chipCompactVerticalPadding = 23.0;

  /// Ficha del selector de animales: retrato grande y nombre debajo.
  static const animalChoiceExtent = 180.0;
  static const animalChoiceMaxWidth = 168.0;
  static const animalChoiceMinWidth = 96.0;

  /// Parte de la lámina que ocupa el retrato del animal.
  static const animalPortraitRatio = 0.52;

  /// Retrato pequeño, el de las listas.
  static const animalAvatarSize = 52.0;
  static const animalAvatarRatio = 0.62;

  static const selectionBorderWidth = 3.0;
  static const selectorSheetHeightFactor = 0.92;

  /// Celebración: la foto del niño, las medallas y el confeti.
  static const celebrationPhotoSize = 220.0;
  static const celebrationScrim = Color(0xE6231C15);
  static const medalSize = 72.0;
  static const medalSizeLarge = 132.0;
  static const medalLabelLines = 2;
  static const medalLabelLineHeight = 22.0;
  static const medalBorderWidth = 3.0;
  static const confettiPieces = 28;
  static const confettiPiecesShort = 12;
  static const confettiPieceSize = 18.0;

  static const navigationBarHeight = 84.0;
  static const navigationBadgePadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space4,
  );

  static const collectionGridMaxCrossAxisExtent = 260.0;
  static const collectionGridMainAxisExtent = 248.0;
  static const collectionHeaderSkeletonHeight = 190.0;
  static const collectionFilterSkeletonHeight = 40.0;
  static const collectionCardSkeletonHeight = 180.0;
  static const historySkeletonItemHeight = 72.0;
  static const historySkeletonItemCount = 6;

  /// Alto y ancho mínimo de cualquier elemento tocable por un niño.
  static const touchTargetMin = 64.0;

  /// Titulares: redonda y con mucha personalidad.
  static const fontFamily = 'Andika';

  /// Textos largos y etiquetas: pensada para leerse fácil.
  static const fontFamilyLectura = 'Atkinson Hyperlegible';

  static const displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const bodyLarge = TextStyle(
    fontFamily: fontFamilyLectura,
    fontSize: 19,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const bodyMedium = TextStyle(
    fontFamily: fontFamilyLectura,
    fontSize: 17,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const bodySmall = TextStyle(
    fontFamily: fontFamilyLectura,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const labelLarge = TextStyle(
    fontFamily: fontFamilyLectura,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    fontFamily: fontFamilyLectura,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}

abstract final class MichiTheme {
  static ThemeData light() => _data(_lightScheme, MichiTokens.cardShadowLight);
  static ThemeData dark() => _data(_darkScheme, MichiTokens.cardShadowDark);

  // Se sigue partiendo de fromSeed para que los ~45 roles del esquema salgan
  // coherentes entre sí, pero los roles que se ven en pantalla se fijan a
  // mano: con la semilla naranja sola, Material 3 apaga los principales en
  // claro y tiñe de marrón todas las superficies en oscuro (ver ANEXO PALETA
  // en docs/PLAN_UX_INFANTIL.txt).
  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.naranja,
    brightness: Brightness.light,
    primary: MichiTokens.naranja,
    onPrimary: MichiTokens.tinta,
    primaryContainer: MichiTokens.naranjaSuave,
    onPrimaryContainer: MichiTokens.naranjaTinta,
    secondary: MichiTokens.verde,
    onSecondary: MichiTokens.verdeOscuro,
    secondaryContainer: MichiTokens.verdeSuave,
    onSecondaryContainer: MichiTokens.verdeTinta,
    tertiary: MichiTokens.amarillo,
    onTertiary: MichiTokens.ambarOscuro,
    tertiaryContainer: MichiTokens.amarilloSuave,
    onTertiaryContainer: MichiTokens.ambarOscuro,
    error: MichiTokens.rojo,
    onError: Colors.white,
    errorContainer: MichiTokens.rojoSuave,
    onErrorContainer: MichiTokens.rojoTinta,
    surface: MichiTokens.crema,
    onSurface: MichiTokens.tinta,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: MichiTokens.cremaSuave,
    surfaceContainer: MichiTokens.cremaSuave,
    surfaceContainerHigh: MichiTokens.cremaMedia,
    surfaceContainerHighest: MichiTokens.cremaHonda,
    onSurfaceVariant: MichiTokens.perfilClaro,
    outline: MichiTokens.perfilClaro,
    outlineVariant: MichiTokens.perfilClaroSuave,
  );
  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: MichiTokens.naranja,
    brightness: Brightness.dark,
    primary: MichiTokens.naranjaClaro,
    onPrimary: MichiTokens.naranjaOscuro,
    primaryContainer: MichiTokens.naranjaHondo,
    onPrimaryContainer: MichiTokens.naranjaTintaClara,
    secondary: MichiTokens.verdeClaro,
    onSecondary: MichiTokens.verdeNoche,
    secondaryContainer: MichiTokens.verdeHondo,
    onSecondaryContainer: MichiTokens.verdeTintaClara,
    tertiary: MichiTokens.amarilloClaro,
    onTertiary: MichiTokens.ambarOscuro,
    tertiaryContainer: MichiTokens.amarilloHondo,
    onTertiaryContainer: MichiTokens.amarilloTintaClara,
    error: MichiTokens.rojoClaro,
    onError: MichiTokens.rojoOscuro,
    errorContainer: MichiTokens.rojoHondo,
    onErrorContainer: MichiTokens.rojoSuave,
    surface: MichiTokens.fondoOscuro,
    onSurface: MichiTokens.cremaClara,
    surfaceContainerLowest: MichiTokens.fondoOscuro,
    surfaceContainerLow: MichiTokens.fondoOscuroBajo,
    surfaceContainer: MichiTokens.fondoOscuroMedio,
    surfaceContainerHigh: MichiTokens.fondoOscuroAlto,
    surfaceContainerHighest: MichiTokens.fondoOscuroCima,
    onSurfaceVariant: MichiTokens.perfilOscuro,
    outline: MichiTokens.perfilOscuro,
    outlineVariant: MichiTokens.perfilOscuroSuave,
  );

  static ThemeData _data(ColorScheme scheme, Color cardShadow) {
    final textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: MichiTokens.fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: MichiTokens.headlineSmall.copyWith(
          color: scheme.onSurface,
        ),
      ),
      // Tarjetas planas con un filo suave: en claro separan sin ensuciar de
      // gris y en oscuro se distinguen del fondo, donde una sombra no se ve.
      cardTheme: CardThemeData(
        elevation: MichiTokens.cardElevation,
        color: scheme.surfaceContainerLow,
        shape: MichiTokens.cardShape.copyWith(
          side: BorderSide(
            color: scheme.outlineVariant,
            width: MichiTokens.cardBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shadowColor: cardShadow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(MichiTokens.touchTargetMin),
          shape: MichiTokens.buttonShape,
          textStyle: MichiTokens.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: MichiTokens.space24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(MichiTokens.touchTargetMin),
          shape: MichiTokens.buttonShape,
          textStyle: MichiTokens.labelLarge,
          side: BorderSide(color: scheme.outlineVariant, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: MichiTokens.space24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            MichiTokens.touchTargetMin,
            MichiTokens.touchTargetMin,
          ),
          shape: MichiTokens.buttonShape,
          textStyle: MichiTokens.labelLarge,
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
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant, width: 2),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: MichiTokens.space16,
          vertical: MichiTokens.chipVerticalPadding,
        ),
        shape: const StadiumBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: MichiTokens.touchTargetMin,
        minVerticalPadding: MichiTokens.space12,
        titleTextStyle: MichiTokens.titleSmall,
        subtitleTextStyle: MichiTokens.bodySmall,
      ),
      // Barra gruesa y con las puntas redondeadas: se lee de lejos y pega con
      // el resto de formas de la app.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: MichiTokens.progressBarHeight,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(MichiTokens.radiusSmall),
        color: scheme.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(MichiTokens.radiusLarge),
        ),
        titleTextStyle: MichiTokens.titleLarge.copyWith(
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: MichiTokens.radiusLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(MichiTokens.radiusMedium),
        ),
        contentTextStyle: MichiTokens.bodyMedium.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      // La navegación pinta su propia pastilla de color por sección
      // (`AdaptiveNavigationShell`), así que el indicador de Material sobra.
      navigationBarTheme: NavigationBarThemeData(
        height: MichiTokens.navigationBarHeight,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          MichiTokens.labelMedium.copyWith(color: scheme.onSurface),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: Colors.transparent,
        selectedLabelTextStyle: MichiTokens.labelMedium.copyWith(
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: MichiTokens.labelMedium.copyWith(
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        // Los avisos de un formulario suelen ser frases enteras: a una línea
        // se cortaban a media palabra.
        errorMaxLines: 3,
        helperMaxLines: 3,
        labelStyle: MichiTokens.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: MichiTokens.bodySmall.copyWith(color: scheme.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MichiTokens.space20,
          vertical: MichiTokens.space16,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(MichiTokens.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  /// Dos familias con papeles distintos: Andika titula y Atkinson
  /// Hyperlegible lee. La mezcla da jerarquía sin subir el tamaño de letra.
  static TextTheme _textTheme(ColorScheme scheme) => const TextTheme(
    displaySmall: MichiTokens.displaySmall,
    headlineMedium: MichiTokens.headlineMedium,
    headlineSmall: MichiTokens.headlineSmall,
    titleLarge: MichiTokens.titleLarge,
    titleMedium: MichiTokens.titleMedium,
    titleSmall: MichiTokens.titleSmall,
    bodyLarge: MichiTokens.bodyLarge,
    bodyMedium: MichiTokens.bodyMedium,
    bodySmall: MichiTokens.bodySmall,
    labelLarge: MichiTokens.labelLarge,
    labelMedium: MichiTokens.labelMedium,
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

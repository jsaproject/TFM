import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/shell/presentation/adaptive_navigation_shell.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinations = [
    ShellDestination(
      label: TextosNino.navegacionInicio,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      accent: ShellAccent.primary,
    ),
    ShellDestination(
      label: TextosNino.navegacionColeccion,
      icon: Icons.collections_bookmark_outlined,
      selectedIcon: Icons.collections_bookmark,
      accent: ShellAccent.secondary,
    ),
    ShellDestination(
      label: TextosNino.navegacionAdultos,
      icon: Icons.lock_outline,
      selectedIcon: Icons.lock,
      accent: ShellAccent.tertiary,
    ),
  ];

  Future<void> pumpShell(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: AdaptiveNavigationShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: destinations,
          children: const [
            Text(TextosNino.navegacionInicio),
            Text(TextosNino.navegacionColeccion),
            Text(TextosNino.navegacionAdultos),
          ],
        ),
      ),
    );
  }

  testWidgets('muestra una NavigationBar en teléfono', (tester) async {
    await pumpShell(tester, 390);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text(TextosNino.navegacionInicio), findsAtLeastNWidgets(1));
  });

  testWidgets('usa el indicador Material rectangular y sin brillo', (
    tester,
  ) async {
    await pumpShell(tester, 390);

    final navigationTheme = MichiTheme.light().navigationBarTheme;
    expect(
      navigationTheme.indicatorColor,
      MichiTheme.light().colorScheme.secondaryContainer,
    );
    expect(
      navigationTheme.indicatorShape,
      MichiTokens.navigationDestinationShape,
    );
    for (final icono in tester.widgetList<Icon>(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Icon),
      ),
    )) {
      expect(icono.size, MichiTokens.iconSizeMedium);
    }
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );
  });

  testWidgets('muestra una NavigationRail en pantalla ancha', (tester) async {
    await pumpShell(tester, 900);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text(TextosNino.navegacionInicio), findsAtLeastNWidgets(1));
  });
}

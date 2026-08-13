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
    ),
    ShellDestination(
      label: TextosNino.navegacionColeccion,
      icon: Icons.collections_bookmark_outlined,
      selectedIcon: Icons.collections_bookmark,
    ),
    ShellDestination(
      label: TextosNino.navegacionPerfil,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  Future<void> pumpShell(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: destinations,
          children: const [
            Text(TextosNino.navegacionInicio),
            Text(TextosNino.navegacionColeccion),
            Text(TextosNino.navegacionPerfil),
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

  testWidgets('muestra una NavigationRail en pantalla ancha', (tester) async {
    await pumpShell(tester, 900);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text(TextosNino.navegacionInicio), findsAtLeastNWidgets(1));
  });
}

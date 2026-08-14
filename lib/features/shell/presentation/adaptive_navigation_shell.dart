import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Rol histórico de cada destino. El tema Material decide ahora el indicador
/// común para evitar que cada sección parezca una pastilla distinta.
enum ShellAccent { primary, secondary, tertiary }

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ShellAccent accent;
}

class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.children,
  }) : assert(destinations.length == children.length);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;
  final List<Widget> children;

  static const railBreakpoint = MichiTokens.navigationRailBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = IndexedStack(index: selectedIndex, children: children);
      if (constraints.maxWidth >= railBreakpoint) {
        return Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: _DestinationBadge(icon: destination.icon),
                      selectedIcon: _DestinationBadge(
                        icon: destination.selectedIcon,
                      ),
                      label: Text(destination.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: MichiTokens.dividerThickness),
            Expanded(child: content),
          ],
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations
              .map(
                (destination) => NavigationDestination(
                  icon: _DestinationBadge(icon: destination.icon),
                  selectedIcon: _DestinationBadge(
                    icon: destination.selectedIcon,
                  ),
                  label: destination.label,
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

/// Icono de destino; el indicador rectangular suave pertenece a Material.
class _DestinationBadge extends StatelessWidget {
  const _DestinationBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: MichiTokens.iconSizeMedium);
}

import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Color con el que se reconoce cada sección de la app.
///
/// Un niño que no lee distingue las secciones por el color de la pastilla del
/// icono, no por la etiqueta. Los tres valores salen del esquema del tema.
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
                      icon: _DestinationBadge(
                        icon: destination.icon,
                        accent: destination.accent,
                        selected: false,
                      ),
                      selectedIcon: _DestinationBadge(
                        icon: destination.selectedIcon,
                        accent: destination.accent,
                        selected: true,
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
                  icon: _DestinationBadge(
                    icon: destination.icon,
                    accent: destination.accent,
                    selected: false,
                  ),
                  selectedIcon: _DestinationBadge(
                    icon: destination.selectedIcon,
                    accent: destination.accent,
                    selected: true,
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

/// Pastilla de color con el icono de la sección dentro.
///
/// Sustituye al indicador de Material (que el tema deja transparente) para que
/// cada sección tenga su propio color en los dos estados.
class _DestinationBadge extends StatelessWidget {
  const _DestinationBadge({
    required this.icon,
    required this.accent,
    required this.selected,
  });

  final IconData icon;
  final ShellAccent accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (accent) {
      ShellAccent.primary =>
        selected
            ? (colors.primary, colors.onPrimary)
            : (colors.primaryContainer, colors.onPrimaryContainer),
      ShellAccent.secondary =>
        selected
            ? (colors.secondary, colors.onSecondary)
            : (colors.secondaryContainer, colors.onSecondaryContainer),
      ShellAccent.tertiary =>
        selected
            ? (colors.tertiary, colors.onTertiary)
            : (colors.tertiaryContainer, colors.onTertiaryContainer),
    };
    return AnimatedContainer(
      duration: MichiTokens.durationShort,
      curve: Curves.easeOut,
      padding: MichiTokens.navigationBadgePadding,
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
        shadows: selected
            ? [
                BoxShadow(
                  color: background.withValues(alpha: 0.45),
                  blurRadius: MichiTokens.space12,
                  offset: const Offset(0, MichiTokens.space4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: MichiTokens.iconSizeMedium, color: foreground),
    );
  }
}

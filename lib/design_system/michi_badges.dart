import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/design_system/michi_colors.dart';
import 'package:flutter/material.dart';

/// La única pastilla seleccionable del sistema, destinada a filtros breves.
class MichiFilterChip extends StatelessWidget {
  const MichiFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    ),
  );
}

/// Estado breve que se apoya también en icono y texto, nunca solo en color.
class MichiStatusBadge extends StatelessWidget {
  const MichiStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.tone = MichiStatusTone.neutral,
  });

  final String label;
  final IconData icon;
  final MichiStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.michiColors;
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      MichiStatusTone.progress => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      MichiStatusTone.discovery => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      MichiStatusTone.danger => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      MichiStatusTone.neutral => (scheme.surfaceContainerHigh, colors.ink),
    };
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: MichiTokens.touchTargetMin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MichiTokens.space16,
          vertical: MichiTokens.space8,
        ),
        decoration: ShapeDecoration(
          color: background,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: MichiTokens.iconSizeSmall, color: foreground),
            const SizedBox(width: MichiTokens.space8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MichiStatusTone { neutral, progress, discovery, danger }

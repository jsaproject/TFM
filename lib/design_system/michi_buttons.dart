import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/design_system/michi_colors.dart';
import 'package:flutter/material.dart';

/// Botones rectangulares y suaves para acciones de página.
///
/// El estado nulo de [onPressed] utiliza el estilo deshabilitado del tema y
/// evita envíos duplicados cuando la pantalla lo controla de ese modo.
class MichiPrimaryButton extends StatelessWidget {
  const MichiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: icon == null
        ? FilledButton(
            onPressed: onPressed,
            child: Text(label, textAlign: TextAlign.center),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          ),
  );
}

class MichiSecondaryButton extends StatelessWidget {
  const MichiSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: icon == null
        ? OutlinedButton(
            onPressed: onPressed,
            child: Text(label, textAlign: TextAlign.center),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          ),
  );
}

class MichiDestructiveButton extends StatelessWidget {
  const MichiDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.michiColors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: colors.danger,
          foregroundColor: Theme.of(context).colorScheme.onError,
          disabledBackgroundColor: colors.danger.withValues(alpha: 0.18),
          disabledForegroundColor: colors.ink.withValues(alpha: 0.45),
          shape: MichiTokens.buttonShape,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

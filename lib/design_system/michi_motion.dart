import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/material.dart';

/// Motion semántico y respetuoso con la preferencia de reducir animaciones.
abstract final class MichiMotion {
  static Duration duration(BuildContext context, Duration standard) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : standard;

  static Duration get reveal => MichiTokens.durationShort;
  static Duration get contentChange => MichiTokens.durationMedium;
}

/// Aparición puramente decorativa para contenido que ya existe.
///
/// Nunca representa progreso ni modifica la duración de una operación real.
class MichiAnimatedReveal extends StatelessWidget {
  const MichiAnimatedReveal({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: MichiMotion.duration(context, MichiMotion.reveal),
    opacity: visible ? 1 : 0,
    child: child,
  );
}

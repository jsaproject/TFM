import 'package:flutter/material.dart';

/// Roles cromáticos del cuaderno de campo.
///
/// Los nombres describen la intención y no el pigmento. Así los componentes
/// conservan significado cuando el tema cambia entre claro y oscuro.
@immutable
class MichiColors extends ThemeExtension<MichiColors> {
  const MichiColors({
    required this.paper,
    required this.ink,
    required this.actionPrimary,
    required this.onActionPrimary,
    required this.progress,
    required this.discovery,
    required this.danger,
    required this.border,
    required this.focus,
    required this.heroSurface,
    required this.photoFrameSurface,
    required this.albumPageSurface,
    required this.statePanelSurface,
    required this.adultSectionSurface,
  });

  final Color paper;
  final Color ink;
  final Color actionPrimary;
  final Color onActionPrimary;
  final Color progress;
  final Color discovery;
  final Color danger;
  final Color border;
  final Color focus;
  final Color heroSurface;
  final Color photoFrameSurface;
  final Color albumPageSurface;
  final Color statePanelSurface;
  final Color adultSectionSurface;

  @override
  MichiColors copyWith({
    Color? paper,
    Color? ink,
    Color? actionPrimary,
    Color? onActionPrimary,
    Color? progress,
    Color? discovery,
    Color? danger,
    Color? border,
    Color? focus,
    Color? heroSurface,
    Color? photoFrameSurface,
    Color? albumPageSurface,
    Color? statePanelSurface,
    Color? adultSectionSurface,
  }) => MichiColors(
    paper: paper ?? this.paper,
    ink: ink ?? this.ink,
    actionPrimary: actionPrimary ?? this.actionPrimary,
    onActionPrimary: onActionPrimary ?? this.onActionPrimary,
    progress: progress ?? this.progress,
    discovery: discovery ?? this.discovery,
    danger: danger ?? this.danger,
    border: border ?? this.border,
    focus: focus ?? this.focus,
    heroSurface: heroSurface ?? this.heroSurface,
    photoFrameSurface: photoFrameSurface ?? this.photoFrameSurface,
    albumPageSurface: albumPageSurface ?? this.albumPageSurface,
    statePanelSurface: statePanelSurface ?? this.statePanelSurface,
    adultSectionSurface: adultSectionSurface ?? this.adultSectionSurface,
  );

  @override
  MichiColors lerp(MichiColors? other, double t) {
    if (other is! MichiColors) return this;
    return MichiColors(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      onActionPrimary: Color.lerp(onActionPrimary, other.onActionPrimary, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      discovery: Color.lerp(discovery, other.discovery, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      border: Color.lerp(border, other.border, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      photoFrameSurface: Color.lerp(
        photoFrameSurface,
        other.photoFrameSurface,
        t,
      )!,
      albumPageSurface: Color.lerp(
        albumPageSurface,
        other.albumPageSurface,
        t,
      )!,
      statePanelSurface: Color.lerp(
        statePanelSurface,
        other.statePanelSurface,
        t,
      )!,
      adultSectionSurface: Color.lerp(
        adultSectionSurface,
        other.adultSectionSurface,
        t,
      )!,
    );
  }
}

extension MichiColorsContext on BuildContext {
  /// Roles del tema activo. Siempre se registra desde [MichiTheme].
  MichiColors get michiColors => Theme.of(this).extension<MichiColors>()!;
}

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/design_system/michi_colors.dart';
import 'package:flutter/material.dart';

/// Marco semántico para una fotografía. No carga archivos ni decide su origen.
class PhotoFrame extends StatelessWidget {
  const PhotoFrame({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.aspectRatio = MichiTokens.photoAspectRatio,
  });

  final Widget child;
  final String semanticLabel;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: context.michiColors.photoFrameSurface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(MichiTokens.radiusLarge),
          side: BorderSide(
            color: context.michiColors.border,
            width: MichiTokens.borderWidth,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(MichiTokens.radiusLarge),
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      ),
    ),
  );
}

/// Apertura editorial sin altura fija: admite texto al 200 % sin truncarlo.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.action,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.michiColors.heroSurface,
      borderRadius: const BorderRadius.all(MichiTokens.radiusExtraLarge),
      border: Border.all(
        color: context.michiColors.border,
        width: MichiTokens.borderWidth,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (description case final description?) ...[
            const SizedBox(height: MichiTokens.space8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: MichiTokens.space20),
          child,
          if (action case final action?) ...[
            const SizedBox(height: MichiTokens.space20),
            action,
          ],
        ],
      ),
    ),
  );
}

/// Superficie de álbum, deliberadamente más plana que una tarjeta de estado.
class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.michiColors.albumPageSurface),
    child: child,
  );
}

/// Panel de carga, vacío, error u offline con explicación y recuperación.
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.semanticLabel,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final String semanticLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: semanticLabel,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: context.michiColors.statePanelSurface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
          side: BorderSide(
            color: context.michiColors.border,
            width: MichiTokens.borderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: MichiTokens.iconSizeProminent),
            const SizedBox(height: MichiTokens.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MichiTokens.space8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action case final action?) ...[
              const SizedBox(height: MichiTokens.space20),
              action,
            ],
          ],
        ),
      ),
    ),
  );
}

/// Agrupación sobria para ajustes y acciones de adultos.
class AdultSection extends StatelessWidget {
  const AdultSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.michiColors.adultSectionSurface,
      border: Border(
        top: BorderSide(
          color: context.michiColors.border,
          width: MichiTokens.borderWidth,
        ),
        bottom: BorderSide(
          color: context.michiColors.border,
          width: MichiTokens.borderWidth,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: MichiTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (description case final description?) ...[
            const SizedBox(height: MichiTokens.space4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: MichiTokens.space16),
          child,
        ],
      ),
    ),
  );
}

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({super.key, required this.title, this.kicker});

  final String title;
  final String? kicker;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (kicker case final kicker?)
        Text(kicker, style: Theme.of(context).textTheme.labelMedium),
      Text(title, style: Theme.of(context).textTheme.displaySmall),
    ],
  );
}

class CompactProgress extends StatelessWidget {
  const CompactProgress({super.key, required this.value, required this.label})
    : assert(value >= 0 && value <= 1);

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value * 100).round()}%',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: MichiTokens.space8),
        LinearProgressIndicator(value: value),
      ],
    ),
  );
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/achievement_medal.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/material.dart';

/// Abre la celebración a pantalla completa y vuelve cuando se cierra.
///
/// Se cierra sola al acabar la animación o antes, si el niño toca la pantalla.
Future<void> showCelebration(
  BuildContext context, {
  required Celebration celebration,
  required SettingsController settings,
  Uint8List? photo,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: MichiTokens.celebrationScrim,
  transitionDuration: MichiTokens.durationShort,
  pageBuilder: (_, _, _) => CelebrationOverlay(
    celebration: celebration,
    settings: settings,
    photo: photo,
  ),
);

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.celebration,
    required this.settings,
    this.photo,
  });

  final Celebration celebration;
  final SettingsController settings;
  final Uint8List? photo;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _confetti;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    final celebration = widget.celebration;
    _confetti = _ConfettiPiece.generate(
      celebration.isBig
          ? MichiTokens.confettiPieces
          : MichiTokens.confettiPiecesShort,
    );
    _controller =
        AnimationController(vsync: this, duration: celebration.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _close();
          })
          ..forward();
    unawaited(
      widget.settings.playSound(
        celebration.newAchievements.isEmpty
            ? AppSound.saved
            : AppSound.achievement,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final celebration = widget.celebration;
    final colors = Theme.of(context).colorScheme;
    // Un niño de 4 años no busca el botón de cerrar: toca donde sea. El gesto
    // no envuelve el contenido en un único nodo para que un lector de
    // pantalla siga leyendo el nombre del animal y las medallas.
    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!MediaQuery.disableAnimationsOf(context))
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    pieces: _confetti,
                    progress: _controller.value,
                    colors: [colors.primary, colors.secondary, colors.tertiary],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: MichiTokens.pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: MichiTokens.contentMaxWidth,
                  ),
                  child: _CelebrationPanel(
                    celebration: celebration,
                    photo: widget.photo,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPanel extends StatelessWidget {
  const _CelebrationPanel({required this.celebration, this.photo});

  final Celebration celebration;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = celebration.savedToCollection
        ? (celebration.isNewAnimal
              ? TextosNino.celebracionNuevo
              : TextosNino.celebracionOtraFoto)
        : null;
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photo != null)
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  MichiTokens.radiusExtraLarge,
                ),
                child: Image.memory(
                  photo!,
                  width: MichiTokens.celebrationPhotoSize,
                  height: MichiTokens.celebrationPhotoSize,
                  fit: BoxFit.cover,
                  // La foto acompaña, no informa: si no se puede pintar, la
                  // celebración sigue con el nombre y las medallas.
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: MichiTokens.space16),
            if (badge != null) ...[
              Text(
                badge,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: MichiTokens.space8),
            ],
            Text(
              celebration.savedToCollection
                  ? TextosNino.yaTienes(celebration.animal)
                  : TextosNino.guardado,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            if (celebration.newAchievements.isNotEmpty) ...[
              const SizedBox(height: MichiTokens.space24),
              Text(
                TextosNino.medallaNueva,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: MichiTokens.space16,
                runSpacing: MichiTokens.space16,
                children: [
                  for (final achievement in celebration.newAchievements)
                    AchievementMedal(
                      achievement: achievement,
                      earned: true,
                      large: true,
                    ),
                ],
              ),
            ],
            const SizedBox(height: MichiTokens.space24),
            Text(
              TextosNino.tocaParaSeguir,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un trozo de confeti. Las posiciones salen de una semilla fija: la fiesta se
/// ve igual en cada foto y los tests no dependen del azar.
class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.drift,
    required this.spin,
    required this.colorIndex,
  });

  final double x;
  final double delay;
  final double drift;
  final double spin;
  final int colorIndex;

  static List<_ConfettiPiece> generate(int count) {
    final random = math.Random(_seed);
    return [
      for (var index = 0; index < count; index++)
        _ConfettiPiece(
          x: random.nextDouble(),
          delay: random.nextDouble() * 0.35,
          drift: random.nextDouble() * 2 - 1,
          spin: random.nextDouble() * 4 + 1,
          colorIndex: index % 3,
        ),
    ];
  }

  static const _seed = 4;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.colors,
  });

  final List<_ConfettiPiece> pieces;
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const side = MichiTokens.confettiPieceSize;
    for (final piece in pieces) {
      final advance = (progress - piece.delay) / (1 - piece.delay);
      if (advance <= 0) continue;
      final travel = advance.clamp(0.0, 1.0);
      final dx = size.width * piece.x + piece.drift * side * 4 * travel;
      final dy = -side + (size.height + side * 2) * travel;
      final paint = Paint()
        ..color = colors[piece.colorIndex].withValues(
          alpha: (1 - travel).clamp(0.0, 1.0),
        );
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(piece.spin * travel * math.pi * 2)
        ..drawRect(
          const Rect.fromLTWH(-side / 2, -side / 4, side, side / 2),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

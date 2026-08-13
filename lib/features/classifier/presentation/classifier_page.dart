import 'dart:async';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_animations.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/classifier/domain/confidence_level.dart';
import 'package:animalspredictor/features/classifier/presentation/celebration_overlay.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/animal_image.dart';
import 'package:animalspredictor/features/collection/presentation/animal_selector.dart';
import 'package:animalspredictor/features/collection/presentation/collection_progress.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'classifier_controller.dart';

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({
    super.key,
    required this.controller,
    required this.onConfirmPrediction,
    required this.settings,
    this.collection,
    this.greetingName,
  });

  final ClassifierController controller;

  /// Guarda el animal y devuelve qué hay que celebrar por él.
  final Future<Celebration> Function(String animal) onConfirmPrediction;
  final SettingsController settings;

  /// Colección del niño, para enseñarle el progreso sin salir de aquí. Nula
  /// mientras no ha llegado o cuando entra como invitado.
  final UserCollection? collection;
  final String? greetingName;

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  String? _selectedAnimal;
  bool _saving = false;
  String? _saveError;
  ClassifierStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncSelectedAnimal);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncSelectedAnimal);
    super.dispose();
  }

  void _syncSelectedAnimal() {
    final state = widget.controller.state;
    if (state.status != _lastStatus) {
      if (state.status == ClassifierStatus.success) {
        final animal = state.prediction?.animal;
        final sound = animal == null ? null : AppSound.forAnimal(animal);
        unawaited(widget.settings.playSound(sound ?? AppSound.success));
      }
      _lastStatus = state.status;
      // El fallo al guardar es de la foto anterior: en cuanto cambia el
      // estado deja de tener sentido.
      if (_saveError != null) setState(() => _saveError = null);
    }
    final animal = state.status == ClassifierStatus.success
        ? state.prediction?.animal
        : null;
    if (animal != _selectedAnimal) setState(() => _selectedAnimal = animal);
  }

  /// La cámara es la acción principal y la galería la secundaria: no hay un
  /// menú intermedio entre el niño y la foto.
  Future<void> _choosePhoto(ImageSource source) =>
      widget.controller.selectAndClassifyPhoto(source);

  Future<void> _chooseAnimal(List<String> suggestions) async {
    final chosen = await showAnimalSelector(
      context,
      selected: _selectedAnimal,
      suggestions: suggestions,
    );
    if (!mounted || chosen == null) return;
    setState(() => _selectedAnimal = chosen);
  }

  void _playSelectedAnimalSound() {
    final animal = _selectedAnimal;
    final sound = animal == null ? null : AppSound.forAnimal(animal);
    if (sound != null) unawaited(widget.settings.playSound(sound));
  }

  Future<void> _confirm() async {
    final animal = _selectedAnimal;
    if (animal == null || _saving) return;
    final photo = widget.controller.state.image;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final celebration = await widget.onConfirmPrediction(animal);
      await widget.settings.provideConfirmationFeedback();
      if (!mounted) return;
      widget.controller.reset();
      await showCelebration(
        context,
        celebration: celebration,
        settings: widget.settings,
        photo: photo,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = TextosNino.noHePodidoGuardarlo);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      return Scaffold(
        appBar: AppBar(title: const Text(TextosNino.marca)),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MichiTokens.contentMaxWidth,
              ),
              child: ListView(
                padding: MichiTokens.pagePadding,
                children: [
                  _WelcomeHeader(name: widget.greetingName).entrance(),
                  const SizedBox(height: MichiTokens.space20),
                  if (widget.collection != null) ...[
                    CollectionProgress(
                      collection: widget.collection!,
                    ).entrance(step: 1),
                    const SizedBox(height: MichiTokens.space20),
                  ],
                  AnimatedSwitcher(
                    duration: MichiTokens.durationMedium,
                    child: _PhotoPreview(
                      key: ValueKey(state.image),
                      state: state,
                    ),
                  ).entrance(step: 2),
                  if (state.status == ClassifierStatus.success ||
                      state.status == ClassifierStatus.unrecognized)
                    _PredictionPanel(
                      state: state,
                      selectedAnimal: _selectedAnimal,
                      saving: _saving,
                      onChanged: (value) =>
                          setState(() => _selectedAnimal = value),
                      onChooseAnimal: _chooseAnimal,
                      onPlaySound: _playSelectedAnimalSound,
                      onConfirm: _confirm,
                    ),
                  if (_saveError != null)
                    _ErrorCard(
                      message: _saveError!,
                      showSettings: false,
                      onRetry: _confirm,
                    ),
                  if (state.noticeMessage != null)
                    _NoticeCard(message: state.noticeMessage!),
                  if (state.errorMessage != null)
                    _ErrorCard(
                      message: state.errorMessage!,
                      showSettings: state.permissionDenied,
                      onRetry: state.canRetryClassification
                          ? widget.controller.classifySelectedPhoto
                          : widget.controller.load,
                    ),
                  const SizedBox(height: MichiTokens.space24),
                  FilledButton.icon(
                    key: const Key('classifier-primary-cta'),
                    style: FilledButton.styleFrom(
                      textStyle: MichiTokens.titleMedium,
                    ),
                    onPressed: state.isBusy || !widget.controller.isModelReady
                        ? null
                        : () => _choosePhoto(ImageSource.camera),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      state.hasPhoto
                          ? TextosNino.elegirOtraFoto
                          : TextosNino.hazUnaFoto,
                    ),
                  ),
                  const SizedBox(height: MichiTokens.space8),
                  TextButton.icon(
                    key: const Key('classifier-gallery-cta'),
                    onPressed: state.isBusy || !widget.controller.isModelReady
                        ? null
                        : () => _choosePhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(TextosNino.usarGaleria),
                  ),
                  // Los consejos van detrás del botón: son de leer una vez, y
                  // delante dejaban la cámara por debajo del pliegue.
                  const SizedBox(height: MichiTokens.space24),
                  const _CaptureGuide().entrance(step: 3),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = name?.trim() ?? '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trimmed.isEmpty
                    ? TextosNino.saludoSinNombre
                    : TextosNino.saludo(trimmed),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: MichiTokens.space4),
              Text(
                TextosNino.buscaUnAnimal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureGuide extends StatelessWidget {
  const _CaptureGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TextosNino.consejosTitulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: MichiTokens.space16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CaptureTip(
                    icon: Icons.pets,
                    label: TextosNino.consejoUnAnimal,
                  ),
                ),
                SizedBox(width: MichiTokens.space8),
                Expanded(
                  child: _CaptureTip(
                    icon: Icons.wb_sunny_outlined,
                    label: TextosNino.consejoLuz,
                  ),
                ),
                SizedBox(width: MichiTokens.space8),
                Expanded(
                  child: _CaptureTip(
                    icon: Icons.zoom_in,
                    label: TextosNino.consejoCerca,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MichiTokens.space16),
            Text(
              TextosNino.conozcoAnimales(animalCatalog.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureTip extends StatelessWidget {
  const _CaptureTip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
          children: [
            // Icono dentro de un círculo de color: los tres consejos se leen
            // como una fila de tres piezas iguales, no como tres dibujos
            // sueltos de distinto tamaño.
            Container(
              width: MichiTokens.touchTargetMin,
              height: MichiTokens.touchTargetMin,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
              ),
              child: Icon(
                icon,
                size: MichiTokens.iconSizeMedium,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: MichiTokens.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({super.key, required this.state});
  final ClassifierState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: state.image == null
          ? TextosNino.dibujoDeAnimales
          : TextosNino.tuFoto,
      image: true,
      child: AspectRatio(
        aspectRatio: MichiTokens.squareImageAspectRatio,
        child: Card(
          shape: MichiTokens.animalCardShape.copyWith(
            side: BorderSide(
              color: colors.outlineVariant,
              width: MichiTokens.cardBorderWidth,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cacheWidth =
                  (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .round();
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (state.image != null)
                    Image.memory(
                      state.image!,
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidth,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text(TextosNino.noVeoLaFoto)),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer,
                            colors.tertiaryContainer,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(MichiTokens.space24),
                        child: Image.asset(
                          'assets/farm_animals.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  if (state.isBusy) ...[
                    const ColoredBox(color: MichiTokens.veilOverlay),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: MichiTokens.space16),
                          Text(
                            TextosNino.mirandoLaFoto,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PredictionPanel extends StatelessWidget {
  const _PredictionPanel({
    required this.state,
    required this.selectedAnimal,
    required this.saving,
    required this.onChanged,
    required this.onChooseAnimal,
    required this.onPlaySound,
    required this.onConfirm,
  });

  final ClassifierState state;
  final String? selectedAnimal;
  final bool saving;
  final ValueChanged<String?> onChanged;
  final ValueChanged<List<String>> onChooseAnimal;
  final VoidCallback onPlaySound;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final reliable = state.status == ClassifierStatus.success;
    final level = ConfidenceLevel.of(
      reliable: reliable,
      confidence: result.primary.confidence,
    );
    final suggestions = <String>[
      result.primary.animal,
      for (final alternative in result.alternatives) alternative.animal,
    ];
    // Si el niño ya ha elegido otro animal en la rejilla, su ficha se queda a
    // la vista junto a las sugerencias para que pueda cambiar de opinión.
    final choices = animalsByName(<String>[
      ...suggestions,
      if (selectedAnimal != null && !suggestions.contains(selectedAnimal))
        selectedAnimal!,
    ]);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MichiTokens.space16),
      child: Card(
        color: reliable ? null : theme.colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(MichiTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimalAvatar(
                    animal: currentAnimalByName[result.primary.animal],
                  ),
                  const SizedBox(width: MichiTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reliable
                              ? TextosNino.yaLoTengo
                              : TextosNino.noLoReconozco,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          TextosNino.creoQueEs(result.primary.animal),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!reliable) ...[
                const SizedBox(height: MichiTokens.space4),
                Text(
                  TextosNino.puedesCambiarlo,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: MichiTokens.space12),
              _ConfidenceBadge(level: level),
              if (selectedAnimal != null &&
                  AppSound.forAnimal(selectedAnimal!) != null) ...[
                const SizedBox(height: MichiTokens.space16),
                FilledButton.tonalIcon(
                  onPressed: saving ? null : onPlaySound,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text(TextosNino.escucharAnimal),
                ),
              ],
              const SizedBox(height: MichiTokens.space20),
              Text(TextosNino.esEste, style: theme.textTheme.titleMedium),
              const SizedBox(height: MichiTokens.space8),
              SizedBox(
                height: MichiTokens.animalChoiceExtent,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: choices.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: MichiTokens.space12),
                  itemBuilder: (context, index) {
                    final animal = choices[index];
                    return SizedBox(
                      width: MichiTokens.animalChoiceMaxWidth,
                      child: AnimalChoiceCard(
                        animal: animal,
                        selected: animal.name == selectedAnimal,
                        onTap: saving ? null : () => onChanged(animal.name),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: MichiTokens.space12),
              OutlinedButton.icon(
                onPressed: saving ? null : () => onChooseAnimal(suggestions),
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text(TextosNino.esOtro),
              ),
              const SizedBox(height: MichiTokens.space12),
              FilledButton.icon(
                onPressed: saving || selectedAnimal == null ? null : onConfirm,
                icon: saving
                    ? const SizedBox.square(
                        dimension: MichiTokens.progressIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: MichiTokens.progressIndicatorStrokeWidth,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(saving ? TextosNino.guardando : TextosNino.guardar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sustituye al porcentaje de confianza: icono, color y tres palabras.
class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.level});
  final ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, label, background, foreground) = switch (level) {
      ConfidenceLevel.sure => (
        Icons.sentiment_very_satisfied,
        TextosNino.nivelSeguro,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ConfidenceLevel.almostSure => (
        Icons.sentiment_satisfied,
        TextosNino.nivelCasiSeguro,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      ConfidenceLevel.unsure => (
        Icons.help_outline,
        TextosNino.nivelNoLoSe,
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        // Una pastilla en vez de un icono suelto: la confianza se lee como una
        // etiqueta, igual que los filtros de la colección.
        child: Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: background,
              shape: const StadiumBorder(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MichiTokens.space16,
                vertical: MichiTokens.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: MichiTokens.iconSizeMedium,
                    color: foreground,
                  ),
                  const SizedBox(width: MichiTokens.space8),
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: MichiTokens.space16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space16),
        child: Text(message),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.showSettings,
    required this.onRetry,
  });
  final String message;
  final bool showSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: MichiTokens.space16),
    child: Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sentiment_dissatisfied,
                  size: MichiTokens.iconSizeProminent,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: MichiTokens.space12),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: MichiTokens.space8),
            Wrap(
              spacing: MichiTokens.space8,
              children: [
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(TextosNino.pruebaOtraVez),
                ),
                if (showSettings)
                  TextButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text(TextosNino.abrirAjustes),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

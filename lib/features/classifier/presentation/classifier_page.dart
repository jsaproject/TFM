import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/classifier/domain/confidence_level.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'classifier_controller.dart';

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({
    super.key,
    required this.controller,
    required this.onConfirmPrediction,
    required this.isAnonymous,
    required this.settings,
    this.greetingName,
  });

  final ClassifierController controller;
  final Future<void> Function(String animal) onConfirmPrediction;
  final bool isAnonymous;
  final SettingsController settings;
  final String? greetingName;

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  String? _selectedAnimal;
  bool _saving = false;

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
    final animal = state.status == ClassifierStatus.success
        ? state.prediction?.animal
        : null;
    if (animal != _selectedAnimal) setState(() => _selectedAnimal = animal);
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MichiTokens.space24,
            MichiTokens.space8,
            MichiTokens.space24,
            MichiTokens.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextosNino.eligeUnaFoto,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  size: MichiTokens.iconSizeMedium,
                ),
                title: const Text(TextosNino.usarCamara),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.photo_library_outlined,
                  size: MichiTokens.iconSizeMedium,
                ),
                title: const Text(TextosNino.usarGaleria),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || source == null) return;
    await widget.controller.selectPhoto(source);
  }

  Future<void> _confirm() async {
    final animal = _selectedAnimal;
    if (animal == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirmPrediction(animal);
      await widget.settings.provideConfirmationFeedback();
      if (!mounted) return;
      widget.controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAnonymous
                ? TextosNino.guardado
                : TextosNino.yaTienes(animal),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TextosNino.noHePodidoGuardarlo)),
      );
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
                  _WelcomeHeader(name: widget.greetingName),
                  const SizedBox(height: MichiTokens.space16),
                  const _CaptureGuide(),
                  const SizedBox(height: MichiTokens.space24),
                  AnimatedSwitcher(
                    duration: MichiTokens.durationMedium,
                    child: _PhotoPreview(
                      key: ValueKey(state.image),
                      state: state,
                    ),
                  ),
                  if (state.status == ClassifierStatus.previewing) ...[
                    const SizedBox(height: MichiTokens.space16),
                    FilledButton.icon(
                      onPressed: widget.controller.classifySelectedPhoto,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text(TextosNino.queAnimalEs),
                    ),
                    const SizedBox(height: MichiTokens.space8),
                    TextButton(
                      onPressed: _choosePhoto,
                      child: const Text(TextosNino.elegirOtraFoto),
                    ),
                  ],
                  if (state.status == ClassifierStatus.success ||
                      state.status == ClassifierStatus.unrecognized)
                    _PredictionPanel(
                      state: state,
                      selectedAnimal: _selectedAnimal,
                      saving: _saving,
                      onChanged: (value) =>
                          setState(() => _selectedAnimal = value),
                      onConfirm: _confirm,
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
                    onPressed: state.isBusy || !widget.controller.isModelReady
                        ? null
                        : _choosePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text(TextosNino.hazUnaFoto),
                  ),
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
    final trimmed = name?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trimmed.isEmpty
              ? TextosNino.saludoSinNombre
              : TextosNino.saludo(trimmed),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: MichiTokens.space4),
        const Text(TextosNino.buscaUnAnimal),
      ],
    );
  }
}

class _CaptureGuide extends StatelessWidget {
  const _CaptureGuide();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextosNino.consejosTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space12),
          const Row(
            children: [
              Expanded(
                child: _CaptureTip(
                  icon: Icons.pets,
                  label: TextosNino.consejoUnAnimal,
                ),
              ),
              Expanded(
                child: _CaptureTip(
                  icon: Icons.wb_sunny_outlined,
                  label: TextosNino.consejoLuz,
                ),
              ),
              Expanded(
                child: _CaptureTip(
                  icon: Icons.zoom_in,
                  label: TextosNino.consejoCerca,
                ),
              ),
            ],
          ),
          const SizedBox(height: MichiTokens.space12),
          Text(TextosNino.conozcoAnimales(animalCatalog.length)),
        ],
      ),
    ),
  );
}

class _CaptureTip extends StatelessWidget {
  const _CaptureTip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Column(
        children: [
          Icon(
            icon,
            size: MichiTokens.iconSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: MichiTokens.space8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({super.key, required this.state});
  final ClassifierState state;

  @override
  Widget build(BuildContext context) => Semantics(
    label: state.image == null
        ? TextosNino.dibujoDeAnimales
        : TextosNino.tuFoto,
    image: true,
    child: AspectRatio(
      aspectRatio: MichiTokens.squareImageAspectRatio,
      child: Card(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cacheWidth =
                (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
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
                  Image.asset('assets/farm_animals.png', fit: BoxFit.contain),
                if (state.isBusy)
                  const ColoredBox(color: MichiTokens.veilOverlay),
                if (state.isBusy)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: MichiTokens.space12),
                        Text(TextosNino.mirandoLaFoto),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _PredictionPanel extends StatelessWidget {
  const _PredictionPanel({
    required this.state,
    required this.selectedAnimal,
    required this.saving,
    required this.onChanged,
    required this.onConfirm,
  });

  final ClassifierState state;
  final String? selectedAnimal;
  final bool saving;
  final ValueChanged<String?> onChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final reliable = state.status == ClassifierStatus.success;
    final level = ConfidenceLevel.of(
      reliable: reliable,
      confidence: result.primary.confidence,
    );
    return Padding(
      padding: const EdgeInsets.only(top: MichiTokens.space16),
      child: Card(
        color: reliable
            ? null
            : Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(MichiTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reliable ? TextosNino.yaLoTengo : TextosNino.noLoReconozco,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space8),
              Text(TextosNino.creoQueEs(result.primary.animal)),
              if (!reliable) const Text(TextosNino.puedesCambiarlo),
              const SizedBox(height: MichiTokens.space8),
              _ConfidenceBadge(level: level),
              if (result.alternatives.isNotEmpty) ...[
                const SizedBox(height: MichiTokens.space12),
                Text(
                  TextosNino.tambienPuedeSer,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MichiTokens.space4),
                ...result.alternatives.map(
                  (alternative) => Text(alternative.animal),
                ),
              ],
              const SizedBox(height: MichiTokens.space12),
              DropdownButtonFormField<String>(
                initialValue: selectedAnimal,
                isExpanded: true,
                decoration: const InputDecoration(labelText: TextosNino.esEste),
                items: animalCatalog
                    .map(
                      (animal) => DropdownMenuItem(
                        value: animal.name,
                        child: Text(animal.name),
                      ),
                    )
                    .toList(),
                onChanged: saving ? null : onChanged,
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
    final (icon, label, color) = switch (level) {
      ConfidenceLevel.sure => (
        Icons.sentiment_very_satisfied,
        TextosNino.nivelSeguro,
        colors.secondary,
      ),
      ConfidenceLevel.almostSure => (
        Icons.sentiment_satisfied,
        TextosNino.nivelCasiSeguro,
        colors.onTertiaryContainer,
      ),
      ConfidenceLevel.unsure => (
        Icons.help_outline,
        TextosNino.nivelNoLoSe,
        colors.onTertiaryContainer,
      ),
    };
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(icon, size: MichiTokens.iconSizeMedium, color: color),
            const SizedBox(width: MichiTokens.space8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
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

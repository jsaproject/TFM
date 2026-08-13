import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
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
                'Añade una foto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space8),
              const Text('Elige cómo quieres identificar al animal.'),
              const SizedBox(height: MichiTokens.space12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Usar cámara'),
                subtitle: const Text('Haz una foto ahora'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                subtitle: const Text('Selecciona una foto guardada'),
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
                ? 'Resultado confirmado.'
                : '$animal se ha añadido a tu colección.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La predicción se ha hecho, pero no se ha podido guardar en la colección.',
          ),
        ),
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
        appBar: AppBar(title: const Text('Identificar animal')),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
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
                      label: const Text('Identificar esta foto'),
                    ),
                    const SizedBox(height: MichiTokens.space8),
                    TextButton(
                      onPressed: _choosePhoto,
                      child: const Text('Elegir otra foto'),
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
                      retryLabel: state.canRetryClassification
                          ? 'Reintentar identificación'
                          : 'Reintentar carga',
                    ),
                  const SizedBox(height: MichiTokens.space24),
                  FilledButton.icon(
                    key: const Key('classifier-primary-cta'),
                    onPressed: state.isBusy || !widget.controller.isModelReady
                        ? null
                        : _choosePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Identificar animal'),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name == null || name!.trim().isEmpty ? 'Hola' : 'Hola, ${name!.trim()}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: MichiTokens.space4),
      const Text('Tu próxima foto puede ampliar tu colección.'),
    ],
  );
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
            'Prepara la foto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space8),
          const Text(
            'Encuadra un solo animal, con buena luz y sin que quede muy lejos.',
          ),
          const SizedBox(height: MichiTokens.space8),
          Text(
            'Reconoce ${animalCatalog.length} animales de granja, domésticos '
            'y de zoo. Los tienes todos en tu colección.',
          ),
          const SizedBox(height: MichiTokens.space8),
          const Row(
            children: [
              Icon(Icons.phone_android_outlined, size: 18),
              SizedBox(width: MichiTokens.space8),
              Expanded(
                child: Text('La imagen se procesa solo en este dispositivo.'),
              ),
            ],
          ),
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
        ? 'Imagen de ejemplo de animales de granja'
        : 'Vista previa de la imagen seleccionada',
    image: true,
    child: AspectRatio(
      aspectRatio: 1,
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
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('No se ha podido mostrar esta imagen.'),
                    ),
                  )
                else
                  Image.asset('assets/farm_animals.png', fit: BoxFit.contain),
                if (state.isBusy) const ColoredBox(color: Color(0x33000000)),
                if (state.isBusy)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: MichiTokens.space12),
                        Text('Identificando animal…'),
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
                reliable
                    ? 'Resultado de la identificación'
                    : 'No reconocido con fiabilidad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space8),
              Text(
                reliable
                    ? 'Parece ser: ${result.primary.animal}'
                    : 'La foto se parece a ${result.primary.animal}, pero la confianza es baja. Elige el animal correcto antes de guardarlo.',
              ),
              Text(
                'Confianza: ${(result.primary.confidence * 100).toStringAsFixed(1)} %',
              ),
              if (result.alternatives.isNotEmpty) ...[
                const SizedBox(height: MichiTokens.space12),
                Text(
                  'Otras posibilidades',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MichiTokens.space4),
                ...result.alternatives.map(
                  (alternative) => Text(
                    '${alternative.animal} · ${(alternative.confidence * 100).toStringAsFixed(1)} %',
                  ),
                ),
              ],
              const SizedBox(height: MichiTokens.space12),
              DropdownButtonFormField<String>(
                initialValue: selectedAnimal,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Confirma el animal',
                ),
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
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(saving ? 'Guardando…' : 'Confirmar resultado'),
              ),
            ],
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
    required this.retryLabel,
  });
  final String message;
  final bool showSettings;
  final VoidCallback onRetry;
  final String retryLabel;

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
            Text(message),
            const SizedBox(height: MichiTokens.space8),
            Wrap(
              spacing: MichiTokens.space8,
              children: [
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
                if (showSettings)
                  TextButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Abrir Ajustes'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

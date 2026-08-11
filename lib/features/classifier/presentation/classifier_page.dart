import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
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
  });

  final ClassifierController controller;
  final Future<void> Function(String animal) onConfirmPrediction;
  final bool isAnonymous;

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
    final animal = widget.controller.state.prediction?.animal;
    if (animal != null && animal != _selectedAnimal) {
      setState(() => _selectedAnimal = animal);
    }
  }

  Future<void> _confirm() async {
    final animal = _selectedAnimal;
    if (animal == null) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirmPrediction(animal);
      if (!mounted) return;
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
                  Text(
                    'Identifica animales en una foto',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: MichiTokens.space8),
                  Text(
                    'El análisis se realiza localmente en tu dispositivo.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: MichiTokens.space24),
                  _PhotoPreview(state: state),
                  if (state.status == ClassifierStatus.success)
                    _PredictionCard(
                      state: state,
                      selectedAnimal: _selectedAnimal,
                      saving: _saving,
                      onChanged: (value) =>
                          setState(() => _selectedAnimal = value),
                      onConfirm: _confirm,
                    ),
                  if (state.errorMessage != null)
                    _ErrorCard(
                      message: state.errorMessage!,
                      showSettings: state.permissionDenied,
                    ),
                  const SizedBox(height: MichiTokens.space24),
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => widget.controller.pickAndClassify(
                            ImageSource.camera,
                          ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Hacer una foto'),
                  ),
                  const SizedBox(height: MichiTokens.space12),
                  OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => widget.controller.pickAndClassify(
                            ImageSource.gallery,
                          ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Elegir de la galería'),
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

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.state});
  final ClassifierState state;

  @override
  Widget build(BuildContext context) => Semantics(
    label: state.image == null
        ? 'Imagen de ejemplo de animales de granja'
        : 'Imagen seleccionada para clasificar',
    image: true,
    child: AspectRatio(
      aspectRatio: 1,
      child: Card(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (state.image != null)
              Image.memory(state.image!, fit: BoxFit.cover)
            else
              Image.asset('assets/farm_animals.png', fit: BoxFit.contain),
            if (state.isBusy) const ColoredBox(color: Color(0x33000000)),
            if (state.isBusy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    ),
  );
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
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
    final prediction = state.prediction!;
    return Padding(
      padding: const EdgeInsets.only(top: MichiTokens.space16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MichiTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: MichiTokens.space8),
              Text('Detectado: ${prediction.animal}'),
              Text(
                'Confianza: ${(prediction.confidence * 100).toStringAsFixed(1)} %',
              ),
              const SizedBox(height: MichiTokens.space12),
              DropdownButtonFormField<String>(
                initialValue: selectedAnimal,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Es el animal correcto?',
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
                onPressed: saving ? null : onConfirm,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.showSettings});
  final String message;
  final bool showSettings;

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
            if (showSettings)
              TextButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Abrir Ajustes'),
              ),
          ],
        ),
      ),
    ),
  );
}

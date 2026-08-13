import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/profile/domain/adult_gate_challenge.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pide una multiplicación antes de abrir la zona de adultos.
///
/// Es una barrera de edad deliberadamente ligera, no un mecanismo de
/// seguridad ni una segunda forma de autenticación.
class AdultGate extends StatefulWidget {
  const AdultGate({super.key, required this.onUnlocked, this.challenge});

  /// Completa cuando se cierra la zona de adultos protegida.
  final Future<void> Function() onUnlocked;

  /// Permite una operación fija en pruebas; la app crea una nueva al abrirse.
  final AdultGateChallenge? challenge;

  @override
  State<AdultGate> createState() => _AdultGateState();
}

class _AdultGateState extends State<AdultGate> {
  late final AdultGateChallenge _challenge;
  final _answerController = TextEditingController();
  String? _errorText;
  bool _openingSettings = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge ?? AdultGateChallenge.random();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_openingSettings) return;
    if (!_challenge.accepts(_answerController.text)) {
      setState(() {
        _errorText = TextosAdulto.puertaAdultosError;
        _answerController.clear();
      });
      return;
    }
    setState(() {
      _openingSettings = true;
      _errorText = null;
    });

    try {
      await widget.onUnlocked();
    } finally {
      if (mounted) {
        _answerController.clear();
        setState(() {
          _openingSettings = false;
          _errorText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: TextosAdulto.puertaAdultosSemantica,
                child: const ExcludeSemantics(child: Icon(Icons.lock_outline)),
              ),
              const SizedBox(width: MichiTokens.space8),
              Text(
                TextosAdulto.puertaAdultosTitulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: MichiTokens.space12),
          const Text(TextosAdulto.puertaAdultosTexto),
          const SizedBox(height: MichiTokens.space12),
          Text(
            TextosAdulto.puertaAdultosPregunta(_challenge.expression),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: MichiTokens.space12),
          TextField(
            controller: _answerController,
            autofocus: false,
            enabled: !_openingSettings,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: TextosAdulto.puertaAdultosRespuesta,
              errorText: _errorText,
              constraints: const BoxConstraints(
                minHeight: MichiTokens.touchTargetMin,
              ),
            ),
          ),
          const SizedBox(height: MichiTokens.space12),
          FilledButton.icon(
            key: const Key('adult-gate-submit'),
            onPressed: _openingSettings ? null : _submit,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text(TextosAdulto.puertaAdultosAbrir),
          ),
        ],
      ),
    ),
  );
}

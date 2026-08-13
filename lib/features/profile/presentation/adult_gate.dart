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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Tarjeta neutra con un acento ámbar: es la zona del adulto, no otra
    // pantalla de colores del niño.
    return Card(
      color: colors.surfaceContainerHigh,
      shape: MichiTokens.animalCardShape.copyWith(
        side: BorderSide(
          color: colors.outlineVariant,
          width: MichiTokens.cardBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  label: TextosAdulto.puertaAdultosSemantica,
                  child: ExcludeSemantics(
                    child: Container(
                      width: MichiTokens.touchTargetMin,
                      height: MichiTokens.touchTargetMin,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.tertiary,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: MichiTokens.iconSizeMedium,
                        color: colors.onTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MichiTokens.space16),
                Expanded(
                  child: Text(
                    TextosAdulto.puertaAdultosTitulo,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MichiTokens.space16),
            Text(
              TextosAdulto.puertaAdultosTexto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MichiTokens.space16),
            // La operación, destacada sobre su propio fondo: es lo que hay que
            // resolver, no una línea más del texto.
            DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.surfaceContainerLowest,
                shape: MichiTokens.cardShape,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MichiTokens.space20,
                  vertical: MichiTokens.space16,
                ),
                child: Text(
                  TextosAdulto.puertaAdultosPregunta(_challenge.expression),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: MichiTokens.space16),
            TextField(
              controller: _answerController,
              autofocus: false,
              enabled: !_openingSettings,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: TextosAdulto.puertaAdultosRespuesta,
                errorText: _errorText,
                constraints: const BoxConstraints(
                  minHeight: MichiTokens.touchTargetMin,
                ),
              ),
            ),
            const SizedBox(height: MichiTokens.space16),
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
}

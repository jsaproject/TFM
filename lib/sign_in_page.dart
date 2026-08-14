import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/services/guest_session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  SignInPage({
    super.key,
    AuthService? authService,
    GuestSessionService? guestSessionService,
    this.onGuestSessionStarted,
  }) : authService =
           authService ??
           FirebaseAuthService(
             FirebaseAuth.instance,
             FirebaseFirestore.instance,
           ),
       guestSessionService =
           guestSessionService ?? SharedPreferencesGuestSessionService();

  final AuthService authService;
  final GuestSessionService guestSessionService;
  final VoidCallback? onGuestSessionStarted;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _register = false;
  var _busy = false;
  var _passwordVisible = false;
  String? _errorMessage;

  AuthService get _auth => widget.authService;

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      if (_register) {
        await _auth.signUp(_email.text.trim(), _password.text);
        await widget.guestSessionService.stop();
        if (!mounted) return;
        await _showRegistrationConfirmation();
      } else {
        await _auth.signIn(_email.text.trim(), _password.text);
        await widget.guestSessionService.stop();
      }
    } on FirebaseAuthException catch (error) {
      _setError(_authErrorMessage(error));
    } on FirebaseException {
      _setError(TextosAdulto.errorGuardarCuenta);
    } catch (_) {
      _setError(TextosAdulto.errorInesperado);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInAnonymously() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await widget.guestSessionService.start();
      widget.onGuestSessionStarted?.call();
    } catch (_) {
      _setError(TextosAdulto.errorInvitado);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRegistrationConfirmation() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.check_circle_outline),
      title: const Text(TextosAdulto.cuentaCreadaTitulo),
      content: const Text(TextosAdulto.cuentaCreadaTexto),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(TextosAdulto.continuar),
        ),
      ],
    ),
  );

  void _setError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _changeMode() {
    setState(() {
      _register = !_register;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => TextosAdulto.errorCorreoInvalido,
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => TextosAdulto.errorCredenciales,
    'email-already-in-use' => TextosAdulto.errorCorreoEnUso,
    'weak-password' => TextosAdulto.errorContrasenaDebil,
    'network-request-failed' => TextosAdulto.errorSinConexion,
    'too-many-requests' => TextosAdulto.errorDemasiadosIntentos,
    'operation-not-allowed' => TextosAdulto.errorMetodoNoPermitido,
    _ => TextosAdulto.errorAutenticacion,
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = _register
        ? TextosAdulto.registroTitulo
        : TextosAdulto.accesoTitulo;
    final actionLabel = _register
        ? TextosAdulto.registroBoton
        : TextosAdulto.accesoBoton;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: MichiTokens.authenticationMaxWidth,
            ),
            child: ListView(
              padding: MichiTokens.pagePadding,
              children: [
                const _BrandWelcome(),
                const SizedBox(height: MichiTokens.space32),
                Text(title, style: textTheme.headlineSmall),
                const SizedBox(height: MichiTokens.space8),
                Text(
                  _register
                      ? TextosAdulto.registroSubtitulo
                      : TextosAdulto.accesoSubtitulo,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: MichiTokens.space24),
                if (_errorMessage != null) ...[
                  _AuthError(message: _errorMessage!),
                  const SizedBox(height: MichiTokens.space16),
                ],
                AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: [AutofillHints.email],
                          validator: _emailValidator,
                          decoration: const InputDecoration(
                            labelText: TextosAdulto.correo,
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: MichiTokens.space16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: !_passwordVisible,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _busy ? null : _submit(),
                          validator: _passwordValidator,
                          decoration: InputDecoration(
                            labelText: TextosAdulto.contrasena,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _passwordVisible
                                  ? TextosAdulto.ocultarContrasena
                                  : TextosAdulto.mostrarContrasena,
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () =>
                                          _passwordVisible = !_passwordVisible,
                                    ),
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_register) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _openPasswordRecovery,
                      child: const Text(TextosAdulto.olvideContrasena),
                    ),
                  ),
                ],
                const SizedBox(height: MichiTokens.space8),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: MichiTokens.progressIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth:
                                MichiTokens.progressIndicatorStrokeWidth,
                          ),
                        )
                      : Text(actionLabel),
                ),
                TextButton(
                  onPressed: _busy ? null : _changeMode,
                  child: Text(
                    _register
                        ? TextosAdulto.irAAcceso
                        : TextosAdulto.irARegistro,
                  ),
                ),
                const SizedBox(height: MichiTokens.space16),
                const Divider(),
                const SizedBox(height: MichiTokens.space16),
                Text(TextosAdulto.invitadoTitulo, style: textTheme.titleMedium),
                const SizedBox(height: MichiTokens.space4),
                const Text(TextosAdulto.invitadoTexto),
                const SizedBox(height: MichiTokens.space12),
                OutlinedButton(
                  onPressed: _busy ? null : _signInAnonymously,
                  child: const Text(TextosAdulto.invitadoBoton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPasswordRecovery() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _PasswordRecoveryDialog(initialEmail: _email.text),
    );
    if (!mounted || email == null) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TextosAdulto.recuperacionEnviada(email))),
      );
    } on FirebaseAuthException catch (error) {
      _setError(_authErrorMessage(error));
    } catch (_) {
      _setError(TextosAdulto.errorRecuperacion);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : TextosAdulto.correoInvalido;
  }

  String? _passwordValidator(String? value) =>
      (value?.length ?? 0) >= 6 ? null : TextosAdulto.contrasenaCorta;
}

class _BrandWelcome extends StatelessWidget {
  const _BrandWelcome();

  @override
  Widget build(BuildContext context) => Semantics(
    label: TextosAdulto.marcaSemantica,
    child: Column(
      children: [
        Container(
          width: MichiTokens.brandMarkSize,
          height: MichiTokens.brandMarkSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pets_outlined,
            size: MichiTokens.iconSizeLarge,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: MichiTokens.space16),
        Text(
          TextosAdulto.marca,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: MichiTokens.space8),
        Text(
          TextosAdulto.marcaDescripcion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(MichiTokens.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: MichiTokens.space12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _PasswordRecoveryDialog extends StatefulWidget {
  const _PasswordRecoveryDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<_PasswordRecoveryDialog> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(TextosAdulto.recuperarTitulo),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _email,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onFieldSubmitted: (_) => _send(),
        validator: (value) {
          final email = value?.trim() ?? '';
          return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
              ? null
              : TextosAdulto.correoInvalido;
        },
        decoration: const InputDecoration(labelText: TextosAdulto.correo),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(TextosAdulto.cancelar),
      ),
      FilledButton(
        onPressed: _send,
        child: const Text(TextosAdulto.recuperarBoton),
      ),
    ],
  );

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_email.text.trim());
  }
}

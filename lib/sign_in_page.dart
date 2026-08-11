import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  SignInPage({super.key, AuthService? authService})
    : authService =
          authService ??
          FirebaseAuthService(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          );

  final AuthService authService;

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
        if (!mounted) return;
        await _showRegistrationConfirmation();
      } else {
        await _auth.signIn(_email.text.trim(), _password.text);
      }
    } on FirebaseAuthException catch (error) {
      _setError(_authErrorMessage(error));
    } on FirebaseException {
      _setError('No se ha podido guardar la cuenta. Inténtalo de nuevo.');
    } catch (_) {
      _setError('Ha ocurrido un error inesperado. Inténtalo de nuevo.');
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
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      _setError(_authErrorMessage(error));
    } catch (_) {
      _setError('No se ha podido iniciar como invitado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRegistrationConfirmation() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.check_circle_outline),
      title: const Text('Cuenta creada'),
      content: const Text(
        'Tu colección se guardará con esta cuenta cuando confirmes tus identificaciones.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continuar'),
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
    'invalid-email' => 'El correo electrónico no es válido.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'El correo o la contraseña no son correctos.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'network-request-failed' =>
      'No hay conexión a internet. Comprueba tu red y reintenta.',
    'too-many-requests' =>
      'Has hecho demasiados intentos. Espera unos minutos y vuelve a probar.',
    'operation-not-allowed' => 'Este método de acceso no está habilitado.',
    _ => 'No se ha podido autenticar. Inténtalo de nuevo.',
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
    final title = _register ? 'Crea tu cuenta' : 'Bienvenido de nuevo';
    final actionLabel = _register ? 'Crear cuenta' : 'Iniciar sesión';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: MichiTokens.pagePadding,
              children: [
                const _BrandWelcome(),
                const SizedBox(height: MichiTokens.space32),
                Text(title, style: textTheme.headlineSmall),
                const SizedBox(height: MichiTokens.space8),
                Text(
                  _register
                      ? 'Guarda tus descubrimientos y sigue completando tu colección.'
                      : 'Identifica animales y continúa tu colección.',
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
                            labelText: 'Correo electrónico',
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
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _passwordVisible
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
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
                      child: const Text('He olvidado mi contraseña'),
                    ),
                  ),
                ],
                const SizedBox(height: MichiTokens.space8),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(actionLabel),
                ),
                TextButton(
                  onPressed: _busy ? null : _changeMode,
                  child: Text(
                    _register ? 'Ya tengo una cuenta' : 'Crear una cuenta',
                  ),
                ),
                const SizedBox(height: MichiTokens.space16),
                const Divider(),
                const SizedBox(height: MichiTokens.space16),
                Text('¿Quieres probar primero?', style: textTheme.titleMedium),
                const SizedBox(height: MichiTokens.space4),
                const Text(
                  'Como invitado no guardaremos tu correo ni tus descubrimientos en una colección.',
                ),
                const SizedBox(height: MichiTokens.space12),
                OutlinedButton(
                  onPressed: _busy ? null : _signInAnonymously,
                  child: const Text('Continuar como invitado'),
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
        SnackBar(
          content: Text('Hemos enviado un enlace de recuperación a $email.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _setError(_authErrorMessage(error));
    } catch (_) {
      _setError(
        'No se ha podido enviar el correo de recuperación. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Escribe un correo válido.';
  }

  String? _passwordValidator(String? value) => (value?.length ?? 0) >= 6
      ? null
      : 'La contraseña debe tener al menos 6 caracteres.';
}

class _BrandWelcome extends StatelessWidget {
  const _BrandWelcome();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'La granja de Michi. Identifica animales y completa tu colección.',
    child: Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.pets_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: MichiTokens.space16),
        Text(
          'La granja de Michi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: MichiTokens.space8),
        Text(
          'Descubre animales con una foto y crea tu propia colección.',
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
    title: const Text('Recuperar contraseña'),
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
              : 'Escribe un correo válido.';
        },
        decoration: const InputDecoration(labelText: 'Correo electrónico'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _send, child: const Text('Enviar enlace')),
    ],
  );

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_email.text.trim());
  }
}

import 'package:animalspredictor/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;

  AuthService get _auth =>
      AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        await _auth.signUp(_email.text.trim(), _password.text);
      } else {
        await _auth.signIn(_email.text.trim(), _password.text);
      }
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } on FirebaseException {
      _showError('No se ha podido guardar la cuenta. Inténtalo de nuevo.');
    } catch (_) {
      _showError('Ha ocurrido un error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _busy = true);
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      _showError(_authErrorMessage(error));
    } catch (_) {
      _showError('No se ha podido iniciar como invitado.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'El correo electrónico no es válido.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'El correo o la contraseña no son correctos.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'network-request-failed' => 'No hay conexión a internet.',
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Text(_register ? 'Crear cuenta' : 'Iniciar sesión'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'La granja de Michi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Escribe un correo válido.',
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'La contraseña debe tener al menos 6 caracteres.',
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_register ? 'Crear cuenta' : 'Iniciar sesión'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _register = !_register),
                  child: Text(
                    _register ? 'Ya tengo una cuenta' : 'Crear una cuenta',
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _signInAnonymously,
                  child: const Text('Continuar como invitado'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

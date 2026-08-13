import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/profile/model_information.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.email,
    required this.isAnonymous,
    required this.authService,
    required this.settings,
    required this.permissionService,
  });

  final String? email;
  final bool isAnonymous;
  final AuthService authService;
  final SettingsController settings;
  final PermissionService permissionService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;
  bool _deleting = false;
  PermissionOverview? _permissions;
  String? _permissionsError;
  bool _loadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _loadingPermissions = true;
      _permissionsError = null;
    });
    try {
      final permissions = await widget.permissionService.getOverview();
      if (mounted) setState(() => _permissions = permissions);
    } catch (_) {
      if (mounted) {
        setState(() => _permissionsError = TextosAdulto.permisosError);
      }
    } finally {
      if (mounted) setState(() => _loadingPermissions = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.authService.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TextosAdulto.errorCerrarSesion)),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _changeTheme(AppThemePreference? preference) async {
    if (preference == null) return;
    final saved = await widget.settings.setTheme(preference);
    if (!mounted || saved) return;
    _showSettingsError();
  }

  Future<void> _changeHaptics(bool enabled) async {
    final saved = await widget.settings.setHapticsEnabled(enabled);
    if (!mounted || saved) return;
    _showSettingsError();
  }

  void _showSettingsError() {
    final message = widget.settings.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openSettings() async {
    final opened = await widget.permissionService.openSettings();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TextosAdulto.ajustesNoAbiertos)),
      );
      return;
    }
    await _loadPermissions();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<_DeleteConfirmation>(
      context: context,
      builder: (dialogContext) =>
          _DeleteAccountDialog(isAnonymous: widget.isAnonymous),
    );
    if (!mounted || confirmed == null || _deleting) return;

    setState(() => _deleting = true);
    try {
      await widget.authService.deleteAccount(password: confirmed.password);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_deletionMessage(error))));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TextosAdulto.errorEliminarCuenta)),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _deletionMessage(FirebaseAuthException error) => switch (error.code) {
    'wrong-password' ||
    'invalid-credential' => TextosAdulto.errorContrasenaIncorrecta,
    'too-many-requests' => TextosAdulto.errorEsperaUnosMinutos,
    'network-request-failed' => TextosAdulto.errorCompruebaInternet,
    'requires-recent-login' => TextosAdulto.errorVuelveAIniciarSesion,
    _ => TextosAdulto.errorIdentidad,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(TextosAdulto.perfilTitulo)),
    body: AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) => ListView(
        padding: MichiTokens.pagePadding,
        children: [
          _AccountCard(email: widget.email, isAnonymous: widget.isAnonymous),
          const SizedBox(height: MichiTokens.space24),
          Text(
            TextosAdulto.aparienciaTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text(TextosAdulto.tema),
                  subtitle: const Text(TextosAdulto.temaTexto),
                  trailing: DropdownButton<AppThemePreference>(
                    value: widget.settings.theme,
                    onChanged: widget.settings.isLoading ? null : _changeTheme,
                    items: const [
                      DropdownMenuItem(
                        value: AppThemePreference.system,
                        child: Text(TextosAdulto.temaSistema),
                      ),
                      DropdownMenuItem(
                        value: AppThemePreference.light,
                        child: Text(TextosAdulto.temaClaro),
                      ),
                      DropdownMenuItem(
                        value: AppThemePreference.dark,
                        child: Text(TextosAdulto.temaOscuro),
                      ),
                    ],
                  ),
                ),
                const Divider(height: MichiTokens.dividerThickness),
                SwitchListTile(
                  title: const Text(TextosAdulto.hapticaTitulo),
                  subtitle: const Text(TextosAdulto.hapticaTexto),
                  value: widget.settings.hapticsEnabled,
                  onChanged: widget.settings.isLoading ? null : _changeHaptics,
                ),
              ],
            ),
          ),
          const SizedBox(height: MichiTokens.space24),
          Text(
            TextosAdulto.permisosTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space8),
          _PermissionsCard(
            permissions: _permissions,
            isLoading: _loadingPermissions,
            errorMessage: _permissionsError,
            onRetry: _loadPermissions,
            onOpenSettings: _openSettings,
          ),
          const SizedBox(height: MichiTokens.space24),
          Text(
            TextosAdulto.privacidadTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space8),
          const _PrivacyCard(),
          const SizedBox(height: MichiTokens.space24),
          Text(
            TextosAdulto.modeloTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MichiTokens.space8),
          const _ModelInformationCard(),
          const SizedBox(height: MichiTokens.space24),
          FilledButton.tonalIcon(
            onPressed: _signingOut || _deleting ? null : _signOut,
            icon: _signingOut
                ? const SizedBox.square(
                    dimension: MichiTokens.progressIndicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: MichiTokens.progressIndicatorStrokeWidth,
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(
              _signingOut
                  ? TextosAdulto.cerrandoSesion
                  : TextosAdulto.cerrarSesion,
            ),
          ),
          const SizedBox(height: MichiTokens.space12),
          OutlinedButton.icon(
            onPressed: _signingOut || _deleting ? null : _deleteAccount,
            icon: _deleting
                ? const SizedBox.square(
                    dimension: MichiTokens.progressIndicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: MichiTokens.progressIndicatorStrokeWidth,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(
              _deleting
                  ? TextosAdulto.eliminandoCuenta
                  : TextosAdulto.eliminarCuenta,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email, required this.isAnonymous});
  final String? email;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: MichiTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous
                      ? TextosAdulto.cuentaInvitado
                      : (email ?? TextosAdulto.cuentaUsuario),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: MichiTokens.space4),
                Text(
                  isAnonymous
                      ? TextosAdulto.cuentaInvitadoTexto
                      : TextosAdulto.cuentaTexto,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({
    required this.permissions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenSettings,
  });
  final PermissionOverview? permissions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(MichiTokens.space8),
                child: CircularProgressIndicator(),
              ),
            )
          : errorMessage != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage!),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(TextosAdulto.reintentar),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PermissionRow(
                  label: TextosAdulto.permisoCamara,
                  status: permissions!.camera,
                ),
                const SizedBox(height: MichiTokens.space8),
                _PermissionRow(
                  label: TextosAdulto.permisoFotos,
                  status: permissions!.photos,
                ),
                const SizedBox(height: MichiTokens.space12),
                TextButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text(TextosAdulto.abrirAjustes),
                ),
              ],
            ),
    ),
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.status});
  final String label;
  final AppPermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final granted =
        status == AppPermissionStatus.granted ||
        status == AppPermissionStatus.limited;
    final text = switch (status) {
      AppPermissionStatus.granted => TextosAdulto.permisoConcedido,
      AppPermissionStatus.limited => TextosAdulto.permisoLimitado,
      AppPermissionStatus.unavailable => TextosAdulto.permisoNoDisponible,
      AppPermissionStatus.permanentlyDenied => TextosAdulto.permisoBloqueado,
      AppPermissionStatus.restricted => TextosAdulto.permisoRestringido,
      AppPermissionStatus.denied => TextosAdulto.permisoDenegado,
    };
    return Semantics(
      label: TextosAdulto.permisoSemantica(label, text),
      child: Row(
        children: [
          Icon(granted ? Icons.check_circle_outline : Icons.info_outline),
          const SizedBox(width: MichiTokens.space8),
          Expanded(child: Text(label)),
          Text(text),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(MichiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TextosAdulto.privacidadResumen),
          SizedBox(height: MichiTokens.space8),
          Text(TextosAdulto.privacidadDetalle),
          SizedBox(height: MichiTokens.space8),
          Text(TextosAdulto.privacidadBorrado),
        ],
      ),
    ),
  );
}

class _ModelInformationCard extends StatelessWidget {
  const _ModelInformationCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(MichiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TextosAdulto.modeloVersion(ModelInformation.version)),
          const SizedBox(height: MichiTokens.space8),
          Text(TextosAdulto.modeloClases(ModelInformation.classes.join(', '))),
          const SizedBox(height: MichiTokens.space8),
          Text(ModelInformation.limitations),
        ],
      ),
    ),
  );
}

class _DeleteConfirmation {
  const _DeleteConfirmation(this.password);
  final String? password;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.isAnonymous});
  final bool isAnonymous;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _acknowledged = false;
  bool _obscurePassword = true;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(TextosAdulto.eliminarCuentaTitulo),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(TextosAdulto.eliminarCuentaTexto),
          if (!widget.isAnonymous) ...[
            const SizedBox(height: MichiTokens.space16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: TextosAdulto.eliminarCuentaContrasena,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? TextosAdulto.mostrarContrasena
                      : TextosAdulto.ocultarContrasena,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: MichiTokens.space12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acknowledged,
            onChanged: (value) =>
                setState(() => _acknowledged = value ?? false),
            title: const Text(TextosAdulto.eliminarCuentaCasilla),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(TextosAdulto.cancelar),
      ),
      FilledButton(
        onPressed:
            _acknowledged &&
                (widget.isAnonymous || _passwordController.text.isNotEmpty)
            ? () => Navigator.pop(
                context,
                _DeleteConfirmation(
                  widget.isAnonymous ? null : _passwordController.text,
                ),
              )
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: const Text(TextosAdulto.eliminarCuentaBoton),
      ),
    ],
  );
}

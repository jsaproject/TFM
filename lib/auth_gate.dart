import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/collection/data/guest_collection_sync_service.dart';
import 'package:animalspredictor/features/collection/data/local_collection_repository.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/app_session.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:animalspredictor/services/guest_session_service.dart';
import 'package:animalspredictor/sign_in_page.dart';
import 'package:animalspredictor/welcome_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authService,
    this.guestSessionService,
    required this.settings,
  });

  final AuthService? authService;
  final GuestSessionService? guestSessionService;
  final SettingsController settings;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth =
      widget.authService ??
      FirebaseAuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
  late final GuestSessionService _guestSession =
      widget.guestSessionService ?? SharedPreferencesGuestSessionService();
  late Future<bool> _guestActive = _guestSession.isActive();
  Future<void>? _syncingGuestCollection;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _auth.changes,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: MichiTokens.pagePadding,
              child: Text(
                TextosAdulto.sesionNoComprobada,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      final user = snapshot.data;
      if (user != null && !user.isAnonymous) {
        return _AccountWithGuestSync(
          user: user,
          authService: _auth,
          settings: widget.settings,
          sync: () =>
              _syncingGuestCollection ??= _syncGuestCollection(user.uid),
        );
      }
      return FutureBuilder<bool>(
        future: _guestActive,
        builder: (context, guestSnapshot) {
          if (guestSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (guestSnapshot.data == true) {
            return WelcomeGate(
              session: const AppSession.guest(),
              authService: _auth,
              settings: widget.settings,
              onGuestSignOut: _endGuestSession,
              onDeleteGuestCollection: _deleteGuestCollection,
            );
          }
          return SignInPage(
            authService: _auth,
            guestSessionService: _guestSession,
            onGuestSessionStarted: () {
              setState(() => _guestActive = _guestSession.isActive());
            },
          );
        },
      );
    },
  );

  Future<void> _syncGuestCollection(String uid) async {
    final local = LocalCollectionRepository.open();
    final sync = GuestCollectionSyncService(
      local,
      FirestoreCollectionRepository(FirebaseFirestore.instance),
    );
    try {
      await sync.syncTo(uid);
      await _guestSession.stop();
    } finally {
      await sync.dispose();
      _syncingGuestCollection = null;
    }
  }

  Future<void> _endGuestSession() => _guestSession.stop();

  Future<void> _deleteGuestCollection() async {
    final local = LocalCollectionRepository.open();
    try {
      await local.clearAfterSync();
    } finally {
      await local.dispose();
    }
    await _guestSession.stop();
  }
}

class _AccountWithGuestSync extends StatefulWidget {
  const _AccountWithGuestSync({
    required this.user,
    required this.authService,
    required this.settings,
    required this.sync,
  });

  final User user;
  final AuthService authService;
  final SettingsController settings;
  final Future<void> Function() sync;

  @override
  State<_AccountWithGuestSync> createState() => _AccountWithGuestSyncState();
}

class _AccountWithGuestSyncState extends State<_AccountWithGuestSync> {
  late Future<void> _sync = widget.sync();

  void _retry() => setState(() => _sync = widget.sync());

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _sync,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: MichiTokens.pagePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    TextosAdulto.errorSincronizarColeccion,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MichiTokens.space16),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text(TextosAdulto.reintentar),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return WelcomeGate(
        session: AppSession(
          id: widget.user.uid,
          isAnonymous: false,
          displayName: widget.user.displayName,
          email: widget.user.email,
        ),
        authService: widget.authService,
        settings: widget.settings,
      );
    },
  );
}

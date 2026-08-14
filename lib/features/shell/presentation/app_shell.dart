import 'dart:async';

import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/profile/presentation/profile_page.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/app_session.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';

import 'adaptive_navigation_shell.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.session,
    required this.authService,
    required this.classifier,
    required this.collectionRepository,
    required this.photoPicker,
    required this.settings,
    required this.permissionService,
    this.onGuestSignOut,
    this.onDeleteGuestCollection,
  });

  final AppSession session;
  final AuthService authService;
  final ClassifierService classifier;
  final CollectionRepository collectionRepository;
  final PhotoPickerService photoPicker;
  final SettingsController settings;
  final PermissionService permissionService;
  final Future<void> Function()? onGuestSignOut;
  final Future<void> Function()? onDeleteGuestCollection;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ClassifierController _classifierController;
  StreamSubscription<UserCollection>? _collectionSubscription;
  UserCollection? _collection;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _classifierController = ClassifierController(
      classifier: widget.classifier,
      photoPicker: widget.photoPicker,
    );
    // El progreso y las celebraciones necesitan la misma fuente de verdad en
    // ambos modos: Realm para invitado y Firestore para cuentas.
    _collectionSubscription = widget.collectionRepository
        .watch(widget.session.id)
        .listen(
          (collection) {
            if (mounted) setState(() => _collection = collection);
          },
          onError: (_) {
            if (mounted) setState(() => _collection = null);
          },
        );
  }

  @override
  void dispose() {
    unawaited(_collectionSubscription?.cancel());
    _classifierController.dispose();
    super.dispose();
  }

  Future<Celebration> _savePrediction(String animal) async {
    final before = _collection;
    await widget.collectionRepository.savePrediction(widget.session.id, animal);
    if (before == null) return Celebration(animal: animal);

    final celebration = celebrationFor(before, animal);
    if (celebration.newAchievements.isNotEmpty) {
      await _markSeen(celebration.newAchievements);
    }
    return celebration;
  }

  Future<void> _markSeen(List<Achievement> achievements) async {
    try {
      await widget.collectionRepository.markAchievementsSeen(
        widget.session.id,
        achievements.map((achievement) => achievement.id),
      );
    } catch (_) {
      // Las medallas se pueden volver a anunciar sin perder una foto.
    }
  }

  @override
  Widget build(BuildContext context) => AdaptiveNavigationShell(
    selectedIndex: _selectedIndex,
    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
    destinations: const [
      ShellDestination(
        label: TextosNino.navegacionInicio,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        accent: ShellAccent.primary,
      ),
      ShellDestination(
        label: TextosNino.navegacionColeccion,
        icon: Icons.collections_bookmark_outlined,
        selectedIcon: Icons.collections_bookmark,
        accent: ShellAccent.secondary,
      ),
      ShellDestination(
        label: TextosNino.navegacionAdultos,
        icon: Icons.lock_outline,
        selectedIcon: Icons.lock,
        accent: ShellAccent.tertiary,
      ),
    ],
    children: [
      ClassifierPage(
        controller: _classifierController,
        onConfirmPrediction: _savePrediction,
        collection: _collection,
        greetingName: widget.session.displayName,
        settings: widget.settings,
      ),
      CollectionPage(
        userId: widget.session.id,
        isAnonymous: widget.session.isAnonymous,
        repository: widget.collectionRepository,
        settings: widget.settings,
        onStartIdentifying: () => setState(() => _selectedIndex = 0),
      ),
      ProfilePage(
        displayName: widget.session.displayName,
        collection: _collection,
        email: widget.session.email,
        isAnonymous: widget.session.isAnonymous,
        authService: widget.authService,
        settings: widget.settings,
        permissionService: widget.permissionService,
        onGuestSignOut: widget.onGuestSignOut,
        onDeleteGuestCollection: widget.onDeleteGuestCollection,
      ),
    ],
  );
}

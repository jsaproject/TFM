import 'dart:async';

import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/features/profile/presentation/profile_page.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'adaptive_navigation_shell.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.user,
    required this.authService,
    required this.classifier,
    required this.collectionRepository,
    required this.photoPicker,
    required this.settings,
    required this.permissionService,
  });

  final User user;
  final AuthService authService;
  final ClassifierService classifier;
  final CollectionRepository collectionRepository;
  final PhotoPickerService photoPicker;
  final SettingsController settings;
  final PermissionService permissionService;

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
    // La colección se escucha aquí, y no solo en su pantalla, porque el
    // progreso se ve mientras el niño hace fotos y porque para celebrar hay
    // que saber si el animal ya estaba.
    if (!widget.user.isAnonymous) {
      _collectionSubscription = widget.collectionRepository
          .watch(widget.user.uid)
          .listen(
            (collection) => setState(() => _collection = collection),
            // Si la colección no llega, la pantalla de la colección ya enseña
            // su error y su reintento; aquí basta con no mostrar progreso.
            onError: (_) => setState(() => _collection = null),
          );
    }
  }

  @override
  void dispose() {
    unawaited(_collectionSubscription?.cancel());
    _classifierController.dispose();
    super.dispose();
  }

  Future<Celebration> _savePrediction(String animal) async {
    if (widget.user.isAnonymous) {
      return Celebration(animal: animal, savedToCollection: false);
    }
    final before = _collection;
    await widget.collectionRepository.savePrediction(widget.user.uid, animal);
    // Sin colección conocida no se puede saber qué es nuevo, así que se
    // celebra sin promesas en lugar de anunciar medallas que quizá ya tenía.
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
        widget.user.uid,
        achievements.map((achievement) => achievement.id),
      );
    } catch (_) {
      // Anotar la medalla es secundario: si falla, lo peor que pasa es que se
      // vuelva a celebrar en la siguiente foto. No se interrumpe el guardado.
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
      // Perfil es la puerta de la zona de adultos (FASE 5): candado y nombre.
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
        greetingName: widget.user.displayName,
        settings: widget.settings,
      ),
      CollectionPage(
        userId: widget.user.uid,
        isAnonymous: widget.user.isAnonymous,
        repository: widget.collectionRepository,
        onStartIdentifying: () => setState(() => _selectedIndex = 0),
      ),
      ProfilePage(
        email: widget.user.email,
        isAnonymous: widget.user.isAnonymous,
        authService: widget.authService,
        settings: widget.settings,
        permissionService: widget.permissionService,
      ),
    ],
  );
}

import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_controller.dart';
import 'package:animalspredictor/features/classifier/presentation/classifier_page.dart';
import 'package:animalspredictor/features/collection/presentation/collection_page.dart';
import 'package:animalspredictor/features/profile/presentation/profile_page.dart';
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
  });

  final User user;
  final AuthService authService;
  final ClassifierService classifier;
  final CollectionRepository collectionRepository;
  final PhotoPickerService photoPicker;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ClassifierController _classifierController;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _classifierController = ClassifierController(
      classifier: widget.classifier,
      photoPicker: widget.photoPicker,
    );
  }

  @override
  void dispose() {
    _classifierController.dispose();
    super.dispose();
  }

  Future<void> _savePrediction(String animal) async {
    if (widget.user.isAnonymous) return;
    await widget.collectionRepository.savePrediction(widget.user.uid, animal);
  }

  @override
  Widget build(BuildContext context) => AdaptiveNavigationShell(
    selectedIndex: _selectedIndex,
    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
    destinations: const [
      ShellDestination(
        label: 'Inicio',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      ShellDestination(
        label: 'Colección',
        icon: Icons.collections_bookmark_outlined,
        selectedIcon: Icons.collections_bookmark,
      ),
      ShellDestination(
        label: 'Perfil',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ],
    children: [
      ClassifierPage(
        controller: _classifierController,
        onConfirmPrediction: _savePrediction,
        isAnonymous: widget.user.isAnonymous,
        greetingName: widget.user.displayName,
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
      ),
    ],
  );
}

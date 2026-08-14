import 'dart:async';

import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/profile/data/permission_service.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/features/shell/presentation/app_shell.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:animalspredictor/features/collection/data/local_collection_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animalspredictor/models/app_session.dart';

/// Punto de composición temporal para no romper las rutas existentes.
/// La interfaz principal vive en [AppShell].
class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    required this.session,
    required this.authService,
    ClassifierService? classifier,
    CollectionRepository? collectionRepository,
    PhotoPickerService? photoPicker,
    required this.settings,
    PermissionService? permissionService,
    this.onGuestSignOut,
    this.onDeleteGuestCollection,
  }) : classifier = classifier ?? TinyClipClassifierService(),
       collectionRepository =
           collectionRepository ??
           (session.isAnonymous
               ? LocalCollectionRepository.open()
               : FirestoreCollectionRepository(FirebaseFirestore.instance)),
       photoPicker = photoPicker ?? DevicePhotoPickerService(),
       permissionService = permissionService ?? DevicePermissionService();

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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void dispose() {
    final repository = widget.collectionRepository;
    if (repository is DisposableCollectionRepository) {
      unawaited((repository as DisposableCollectionRepository).dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
    session: widget.session,
    authService: widget.authService,
    classifier: widget.classifier,
    collectionRepository: widget.collectionRepository,
    photoPicker: widget.photoPicker,
    settings: widget.settings,
    permissionService: widget.permissionService,
    onGuestSignOut: widget.onGuestSignOut,
    onDeleteGuestCollection: widget.onDeleteGuestCollection,
  );
}

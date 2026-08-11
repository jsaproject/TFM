import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/features/classifier/data/photo_picker_service.dart';
import 'package:animalspredictor/features/shell/presentation/app_shell.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Punto de composición temporal para no romper las rutas existentes.
/// La interfaz principal vive en [AppShell].
class HomePage extends StatelessWidget {
  HomePage({
    super.key,
    required this.user,
    required this.authService,
    ClassifierService? classifier,
    CollectionRepository? collectionRepository,
    PhotoPickerService? photoPicker,
  }) : classifier = classifier ?? TfliteClassifierService(),
       collectionRepository =
           collectionRepository ??
           FirestoreCollectionRepository(FirebaseFirestore.instance),
       photoPicker = photoPicker ?? DevicePhotoPickerService();

  final User user;
  final AuthService authService;
  final ClassifierService classifier;
  final CollectionRepository collectionRepository;
  final PhotoPickerService photoPicker;

  @override
  Widget build(BuildContext context) => AppShell(
    user: user,
    authService: authService,
    classifier: classifier,
    collectionRepository: collectionRepository,
    photoPicker: photoPicker,
  );
}

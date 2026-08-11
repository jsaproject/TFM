import 'package:animalspredictor/models/prediction.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/photo_picker_service.dart';

enum ClassifierStatus { loading, ready, classifying, success, error }

@immutable
class ClassifierState {
  const ClassifierState({
    required this.status,
    this.image,
    this.prediction,
    this.errorMessage,
    this.permissionDenied = false,
  });

  const ClassifierState.loading() : this(status: ClassifierStatus.loading);
  const ClassifierState.ready() : this(status: ClassifierStatus.ready);

  final ClassifierStatus status;
  final Uint8List? image;
  final Prediction? prediction;
  final String? errorMessage;
  final bool permissionDenied;

  bool get isBusy =>
      status == ClassifierStatus.loading ||
      status == ClassifierStatus.classifying;
}

class ClassifierController extends ChangeNotifier {
  ClassifierController({
    required ClassifierService classifier,
    required PhotoPickerService photoPicker,
  }) : _classifier = classifier,
       _photoPicker = photoPicker;

  final ClassifierService _classifier;
  final PhotoPickerService _photoPicker;
  ClassifierState _state = const ClassifierState.loading();

  ClassifierState get state => _state;

  Future<void> load() async {
    _state = const ClassifierState.loading();
    notifyListeners();
    try {
      await _classifier.load();
      _state = const ClassifierState.ready();
    } on UnsupportedError {
      _state = const ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: 'La clasificación está disponible en Android e iOS.',
      );
    } catch (_) {
      _state = const ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: 'No se ha podido cargar el modelo. Inténtalo de nuevo.',
      );
    }
    notifyListeners();
  }

  Future<void> pickAndClassify(ImageSource source) async {
    if (_state.status != ClassifierStatus.ready &&
        _state.status != ClassifierStatus.success) {
      return;
    }
    try {
      final photo = await _photoPicker.pick(source);
      if (photo == null) return;
      _state = ClassifierState(
        status: ClassifierStatus.classifying,
        image: photo.bytes,
      );
      notifyListeners();
      final prediction = await _classifier.classify(photo.path);
      _state = ClassifierState(
        status: ClassifierStatus.success,
        image: photo.bytes,
        prediction: prediction,
      );
    } on PhotoPermissionDenied catch (error) {
      _state = ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: error.message,
        permissionDenied: true,
      );
    } catch (_) {
      _state = const ClassifierState(
        status: ClassifierStatus.error,
        errorMessage:
            'No se ha podido clasificar la imagen. Inténtalo de nuevo.',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}

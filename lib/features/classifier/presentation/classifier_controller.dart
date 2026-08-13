import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/prediction.dart';
import 'package:animalspredictor/services/classifier_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/photo_picker_service.dart';

enum ClassifierStatus {
  loading,
  ready,
  previewing,
  classifying,
  success,
  unrecognized,
  error,
}

@immutable
class ClassifierState {
  const ClassifierState({
    required this.status,
    this.image,
    this.photoPath,
    this.result,
    this.errorMessage,
    this.noticeMessage,
    this.permissionDenied = false,
  });

  const ClassifierState.loading() : this(status: ClassifierStatus.loading);
  const ClassifierState.ready() : this(status: ClassifierStatus.ready);

  final ClassifierStatus status;
  final Uint8List? image;
  final String? photoPath;
  final ClassificationResult? result;
  final String? errorMessage;
  final String? noticeMessage;
  final bool permissionDenied;

  Prediction? get prediction => result?.primary;

  bool get hasPhoto => image != null && photoPath != null;
  bool get canRetryClassification =>
      status == ClassifierStatus.error && hasPhoto;

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
  bool _isModelReady = false;

  ClassifierState get state => _state;
  bool get isModelReady => _isModelReady;

  Future<void> load() async {
    _isModelReady = false;
    _state = const ClassifierState.loading();
    notifyListeners();
    try {
      await _classifier.load();
      _isModelReady = true;
      _state = const ClassifierState.ready();
    } on UnsupportedError {
      _state = const ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: TextosNino.soloEnMovil,
      );
    } catch (_) {
      _state = const ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: TextosNino.noHePodidoEmpezar,
      );
    }
    notifyListeners();
  }

  Future<void> selectPhoto(ImageSource source) async {
    if (_state.isBusy || !_isModelReady) return;
    try {
      final photo = await _photoPicker.pick(source);
      if (photo == null) {
        _state = const ClassifierState(
          status: ClassifierStatus.ready,
          noticeMessage: TextosNino.noHasElegidoFoto,
        );
        return;
      }
      _state = ClassifierState(
        status: ClassifierStatus.previewing,
        image: photo.bytes,
        photoPath: photo.path,
      );
    } on PhotoPermissionDenied catch (error) {
      _state = ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: error.message,
        permissionDenied: true,
      );
    } catch (_) {
      _state = ClassifierState(
        status: ClassifierStatus.error,
        errorMessage: TextosNino.noHePodidoAbrirLaFoto,
      );
    } finally {
      notifyListeners();
    }
  }

  /// Elegir la foto ya la identifica: el niño no tiene que pulsar un segundo
  /// botón para preguntar qué animal es.
  Future<void> selectAndClassifyPhoto(ImageSource source) async {
    await selectPhoto(source);
    if (_state.status != ClassifierStatus.previewing) return;
    await classifySelectedPhoto();
  }

  Future<void> classifySelectedPhoto() async {
    final path = _state.photoPath;
    final image = _state.image;
    if (path == null || image == null || _state.isBusy) return;

    _state = ClassifierState(
      status: ClassifierStatus.classifying,
      image: image,
      photoPath: path,
    );
    notifyListeners();
    try {
      final result = await _classifier.classify(path);
      _state = ClassifierState(
        status: _isReliable(result)
            ? ClassifierStatus.success
            : ClassifierStatus.unrecognized,
        image: image,
        photoPath: path,
        result: result,
      );
    } catch (_) {
      _state = ClassifierState(
        status: ClassifierStatus.error,
        image: image,
        photoPath: path,
        errorMessage: TextosNino.noHePodidoMirarLaFoto,
      );
    } finally {
      notifyListeners();
    }
  }

  /// Deja la pantalla lista para la siguiente foto. No deja ningún aviso: de
  /// decir que se ha guardado se encarga la celebración.
  void reset() {
    _state = const ClassifierState(status: ClassifierStatus.ready);
    notifyListeners();
  }

  /// Los modelos con rechazo calibrado deciden de forma explícita. Se conserva
  /// la heurística anterior para fakes y clasificadores antiguos.
  static bool _isReliable(ClassificationResult result) =>
      result.reliable ??
      (result.primary.confidence >= minimumReliableConfidence &&
          !result.looksLikeSomethingElse);

  /// Umbral heredado que solo se usa cuando el servicio no aporta su propia
  /// decisión de fiabilidad.
  static const minimumReliableConfidence = 0.5;

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}

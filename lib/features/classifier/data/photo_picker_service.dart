import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PickedPhoto {
  const PickedPhoto({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;
}

abstract class PhotoPickerService {
  Future<PickedPhoto?> pick(ImageSource source);
}

class PhotoPermissionDenied implements Exception {
  const PhotoPermissionDenied(this.message);
  final String message;
}

class DevicePhotoPickerService implements PhotoPickerService {
  DevicePhotoPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick(ImageSource source) async {
    if (!kIsWeb) {
      final permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        throw PhotoPermissionDenied(
          source == ImageSource.camera
              ? TextosNino.dejameUsarLaCamara
              : TextosNino.dejameVerTusFotos,
        );
      }
    }

    final image = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (image == null) return null;
    return PickedPhoto(path: image.path, bytes: await image.readAsBytes());
  }
}

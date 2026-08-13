import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionStatus {
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

@immutable
class PermissionOverview {
  const PermissionOverview({required this.camera, required this.photos});

  final AppPermissionStatus camera;
  final AppPermissionStatus photos;
}

abstract class PermissionService {
  Future<PermissionOverview> getOverview();
  Future<bool> openSettings();
}

class DevicePermissionService implements PermissionService {
  @override
  Future<PermissionOverview> getOverview() async {
    if (kIsWeb) {
      return const PermissionOverview(
        camera: AppPermissionStatus.unavailable,
        photos: AppPermissionStatus.unavailable,
      );
    }
    final statuses = await Future.wait(<Future<PermissionStatus>>[
      Permission.camera.status,
      Permission.photos.status,
    ]);
    return PermissionOverview(
      camera: _fromPlatform(statuses[0]),
      photos: _fromPlatform(statuses[1]),
    );
  }

  @override
  Future<bool> openSettings() async => !kIsWeb && await openAppSettings();

  static AppPermissionStatus _fromPlatform(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isLimited) return AppPermissionStatus.limited;
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }
}

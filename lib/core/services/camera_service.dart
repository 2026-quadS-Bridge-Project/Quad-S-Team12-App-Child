import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();

  /// Launches the native camera and returns the local file path of the captured photo,
  /// or null if the user cancelled or permission was denied.
  /// IMPORTANT: This intentionally does NOT use ImageSource.gallery.
  static Future<String?> capturePhoto({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: CameraDevice.rear,
      );
      return picked?.path;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CameraService.capturePhoto failed: $e\n$st');
      }
      return null;
    }
  }
}

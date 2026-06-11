import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum PhotoPickSource { camera, gallery }

class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();

  /// Opens the requested native image source and returns the local file path,
  /// or null if the user cancelled or permission was denied.
  ///
  /// The returned path points at a file on disk; mission submission attaches
  /// that file to the backend multipart endpoint at submit time.
  static Future<String?> pickPhoto({
    required PhotoPickSource source,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      return await _pickPhoto(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CameraService.pickPhoto failed: $e\n$st');
      }
      return null;
    }
  }

  /// Launches the native camera and returns the local file path of the captured
  /// photo, or null if the user cancelled or permission was denied.
  static Future<String?> capturePhoto({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      return await _pickPhoto(
        source: PhotoPickSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } on Object catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CameraService.capturePhoto failed: $e\n$st');
      }
      if (_isCameraPermissionError(e)) {
        return null;
      }
      return pickPhotoFromGallery(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
  }

  /// Opens the native photo library and returns the selected local image path.
  static Future<String?> pickPhotoFromGallery({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    return pickPhoto(
      source: PhotoPickSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<String?> _pickPhoto({
    required PhotoPickSource source,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    final bool useCamera = source == PhotoPickSource.camera;
    final XFile? picked = await _picker.pickImage(
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      preferredCameraDevice: CameraDevice.rear,
    );
    return picked?.path;
  }

  static bool _isCameraPermissionError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    final String text = '${error.code} ${error.message}'.toLowerCase();
    return text.contains('denied') || text.contains('restricted');
  }
}

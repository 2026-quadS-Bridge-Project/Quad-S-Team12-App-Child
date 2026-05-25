import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../config/environment.dart';
import '../models/result.dart';
import '../network/api_error.dart';

/// Contract for uploading a locally captured photo to remote storage.
///
/// Introduced as a seam between [CameraService] (which produces a
/// `String? path` pointing at a file on disk) and the mission submission
/// flow (which today passes those local paths into
/// `MissionRepository.submitMission` via the [List<String> photoPaths]
/// field).
///
/// In mock builds the local path is echoed back unchanged so the existing
/// mock submit flow continues to work. Once the backend ships, the api
/// implementation will upload the file (via `MultipartFile.fromFile`) and
/// return the remote URL — the mission repo keeps treating the strings
/// opaquely, so the only real wiring change is in
/// [ApiPhotoUploadService.uploadPhoto].
abstract interface class PhotoUploadService {
  Future<Result<String>> uploadPhoto(String localPath);
}

/// Cached singleton — lazy-initialized at first access.
final PhotoUploadService _photoUploadService = currentEnvironment.useMocks
    ? const MockPhotoUploadService()
    : ApiPhotoUploadService(DioConfig.create());

/// Factory: returns the cached service. Mirrors `createMissionRepository`.
PhotoUploadService createPhotoUploadService() => _photoUploadService;

/// Mock impl — pretends the local path IS the remote URL.
///
/// The mission repo will keep treating the returned string as-is until a
/// real backend supplies actual URLs.
class MockPhotoUploadService implements PhotoUploadService {
  const MockPhotoUploadService();

  @override
  Future<Result<String>> uploadPhoto(String localPath) async {
    return Result<String>.success(localPath);
  }
}

/// HTTP-backed impl. Uploads the file at [localPath] to `/uploads/photo`
/// via `multipart/form-data` per `docs/api-contract.md` § Photo Upload and
/// returns the server-assigned remote URL.
class ApiPhotoUploadService implements PhotoUploadService {
  ApiPhotoUploadService(this._dio);

  final Dio _dio;

  @override
  Future<Result<String>> uploadPhoto(String localPath) async {
    try {
      final String filename = _basename(localPath);
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(localPath, filename: filename),
        'purpose': 'mission',
      });
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/uploads/photo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final Map<String, dynamic> body =
          response.data as Map<String, dynamic>;
      return Result<String>.success(body['url'] as String);
    } on DioException catch (e) {
      return failureFromDioException<String>(e);
    }
  }

  /// Extracts the file name (last path segment) from [path]. Handles both
  /// POSIX (`/`) and Windows (`\`) separators so the multipart `filename`
  /// field is just the bare name regardless of where the file came from.
  static String _basename(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf(r'\');
    final int sep = slash > backslash ? slash : backslash;
    return sep == -1 ? path : path.substring(sep + 1);
  }
}

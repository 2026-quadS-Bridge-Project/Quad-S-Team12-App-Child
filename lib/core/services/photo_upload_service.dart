import 'package:dio/dio.dart';

import '../config/dio_config.dart';
import '../config/environment.dart';
import '../models/result.dart';

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

/// HTTP-backed impl.
///
/// The backend exposes no standalone photo-upload endpoint; the captured
/// photo is sent as a `multipart/form-data` file directly to
/// `POST /api/v1/missions/{id}/performances` at submission time (see
/// [ApiMissionRepository.submitMission] and backend-handoff §3.2). This
/// service therefore defers the upload and returns the **local path**, which
/// the controller stores and later hands to `submitMission` so the file can
/// be attached. Behaviour now matches [MockPhotoUploadService].
class ApiPhotoUploadService implements PhotoUploadService {
  ApiPhotoUploadService(this._dio);

  // Retained so the construction seam (DioConfig.create()) is unchanged and a
  // future direct-upload endpoint can be wired here without signature churn.
  // ignore: unused_field
  final Dio _dio;

  @override
  Future<Result<String>> uploadPhoto(String localPath) async {
    return Result<String>.success(localPath);
  }
}

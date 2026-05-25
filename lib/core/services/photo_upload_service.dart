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

/// Factory: selects mock vs. real implementation based on
/// [currentEnvironment.useMocks]. Mirrors `createMissionRepository`.
PhotoUploadService createPhotoUploadService() {
  if (currentEnvironment.useMocks) return const MockPhotoUploadService();
  return ApiPhotoUploadService(DioConfig.create());
}

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

/// HTTP-backed impl stub. Throws until the upload API contract is
/// finalised; at that point this will read the file from disk via
/// `MultipartFile.fromFile(localPath)` and return the remote URL.
class ApiPhotoUploadService implements PhotoUploadService {
  ApiPhotoUploadService(this._dio);

  // ignore: unused_field
  final Dio _dio;

  @override
  Future<Result<String>> uploadPhoto(String localPath) async {
    throw UnimplementedError('Photo upload API contract pending');
  }
}

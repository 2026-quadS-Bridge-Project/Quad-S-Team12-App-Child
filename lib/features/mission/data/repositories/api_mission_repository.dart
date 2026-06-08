import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/mission.dart';
import 'mission_repository.dart';

/// HTTP-backed [MissionRepository] wired to the endpoints defined under
/// "Mission" in `docs/api-contract.md`:
/// - `GET /api/v1/missions`               → list view (array, S1-unwrapped).
/// - `GET /api/v1/missions/:id`           → single mission detail.
/// - `POST /api/v1/missions/:id/performances` → photo submission as
///   `multipart/form-data` (`image` file). childId/category/prompt are
///   derived server-side (backend-handoff §3.2).
///
/// DioException → [Result.failure] via [failureFromDioException]; the
/// helper carries server-supplied Korean copy when available and falls
/// back to the generic status-code messages otherwise.
class ApiMissionRepository implements MissionRepository {
  ApiMissionRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Mission>>> listMissions() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/missions',
      );
      final List<Mission> missions = (response.data as List)
          .cast<Map<String, dynamic>>()
          .map(Mission.fromJson)
          .toList();
      return Result<List<Mission>>.success(missions);
    } on DioException catch (e) {
      return failureFromDioException<List<Mission>>(e);
    }
  }

  @override
  Future<Result<Mission>> fetchMission(String id) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/missions/$id',
      );
      return Result<Mission>.success(
        Mission.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return failureFromDioException<Mission>(e);
    }
  }

  @override
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    if (photoPaths.isEmpty) {
      return Result<MissionSubmissionResult>.failure('제출할 사진이 없어요.');
    }
    try {
      // Upload the captured photo file directly as multipart to the existing
      // backend endpoint. childId(JWT), category & prompt are derived
      // server-side — see backend-handoff §3.2. The backend returns an
      // AiVerificationResponse; the controller owns the UI status transition,
      // so a success signal is all this layer needs.
      final String path = photoPaths.first;
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(path, filename: _basename(path)),
      });
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/missions/$id/performances',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Result<MissionSubmissionResult>.success(
        MissionSubmissionResult.fromJson(_jsonMap(response.data)),
      );
    } on DioException catch (e) {
      return failureFromDioException<MissionSubmissionResult>(e);
    }
  }

  /// Last path segment (POSIX or Windows separator) for the multipart filename.
  static String _basename(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf(r'\');
    final int sep = slash > backslash ? slash : backslash;
    return sep == -1 ? path : path.substring(sep + 1);
  }

  static Map<String, dynamic> _jsonMap(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }
}

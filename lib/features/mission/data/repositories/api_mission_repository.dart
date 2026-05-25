import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/mission.dart';
import 'mission_repository.dart';

/// HTTP-backed [MissionRepository] wired to the endpoints defined under
/// "Mission" in `docs/api-contract.md`:
/// - `GET /missions`            → list view (response wraps the array in
///   `{ "missions": [...] }`).
/// - `GET /missions/:id`        → single mission detail.
/// - `POST /missions/:id/submit`→ photo submission; body uses `photoUrls`
///   per the contract even though the repo method parameter is named
///   `photoPaths` for historical (pre-upload) reasons.
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
      final Response<dynamic> response = await _dio.get<dynamic>('/missions');
      final List<Mission> missions = (response.data['missions'] as List)
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
      final Response<dynamic> response =
          await _dio.get<dynamic>('/missions/$id');
      return Result<Mission>.success(
        Mission.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return failureFromDioException<Mission>(e);
    }
  }

  @override
  Future<Result<Mission>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/missions/$id/submit',
        data: <String, dynamic>{'photoUrls': photoPaths},
      );
      return Result<Mission>.success(
        Mission.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return failureFromDioException<Mission>(e);
    }
  }
}

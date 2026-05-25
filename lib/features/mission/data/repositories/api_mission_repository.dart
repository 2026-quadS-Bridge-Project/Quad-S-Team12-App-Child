import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../models/mission.dart';
import 'mission_repository.dart';

/// HTTP-backed [MissionRepository] stub.
///
/// All methods throw [UnimplementedError] today — the mission API contract
/// is still being finalised. When the backend ships, wire each method to
/// the corresponding endpoint and decode via [Mission.fromJson]; on
/// DioException, return [Result.failure] with the error message + cause.
class ApiMissionRepository implements MissionRepository {
  ApiMissionRepository(this._dio);

  // ignore: unused_field
  final Dio _dio;

  @override
  Future<Result<List<Mission>>> listMissions() {
    throw UnimplementedError('Mission API contract pending');
  }

  @override
  Future<Result<Mission>> fetchMission(String id) {
    throw UnimplementedError('Mission API contract pending');
  }

  @override
  Future<Result<Mission>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) {
    throw UnimplementedError('Mission API contract pending');
  }
}

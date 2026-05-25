import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../models/time_schedule.dart';
import 'time_setup_repository.dart';

/// HTTP-backed implementation of [TimeSetupRepository].
///
/// Stub for Phase 2A — every method throws [UnimplementedError] until
/// backend endpoints are confirmed and wired through `DioConfig`.
class ApiTimeSetupRepository implements TimeSetupRepository {
  ApiTimeSetupRepository({required Dio dio}) : _dio = dio;

  // ignore: unused_field
  final Dio _dio;

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    throw UnimplementedError(
      'ApiTimeSetupRepository.fetchPreviousWeekSchedule: '
      'backend contract TBD.',
    );
  }

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    throw UnimplementedError(
      'ApiTimeSetupRepository.fetchCurrentSchedule: '
      'backend contract TBD.',
    );
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    throw UnimplementedError(
      'ApiTimeSetupRepository.saveSchedule: backend contract TBD.',
    );
  }
}

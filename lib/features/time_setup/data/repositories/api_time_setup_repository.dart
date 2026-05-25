import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/time_schedule.dart';
import 'time_setup_repository.dart';

/// HTTP-backed implementation of [TimeSetupRepository].
///
/// Wires the three Time Setup endpoints documented in
/// `docs/api-contract.md`:
///   * `GET  /time-setup/previous-week` → seed for the v2 (next-month) flow.
///   * `GET  /time-setup/current`       → currently-saved upcoming schedule
///                                        (wrapped as `{ "schedule": ... }`).
///   * `POST /time-setup`               → persist the finished plan.
///
/// All [DioException]s funnel through [failureFromDioException] for
/// consistent Korean error messages.
class ApiTimeSetupRepository implements TimeSetupRepository {
  ApiTimeSetupRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/time-setup/previous-week',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'GET /time-setup/previous-week response was not a JSON object.',
        );
      }
      final TimeSchedule schedule = TimeSchedule.fromJson(
        Map<String, dynamic>.from(data),
      );
      return Result<TimeSchedule>.success(schedule);
    } on DioException catch (e) {
      return failureFromDioException<TimeSchedule>(e);
    }
  }

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/time-setup/current',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'GET /time-setup/current response was not a JSON object.',
        );
      }
      final dynamic inner = data['schedule'];
      if (inner == null) {
        return Result<TimeSchedule?>.success(null);
      }
      if (inner is! Map) {
        throw const FormatException(
          'GET /time-setup/current `schedule` field was not a JSON object.',
        );
      }
      final TimeSchedule schedule = TimeSchedule.fromJson(
        Map<String, dynamic>.from(inner),
      );
      return Result<TimeSchedule?>.success(schedule);
    } on DioException catch (e) {
      return failureFromDioException<TimeSchedule?>(e);
    }
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    try {
      // Server echoes the normalized TimeSchedule on success, but the
      // interface returns Result<void>; we deliberately discard the body.
      await _dio.post<dynamic>(
        '/time-setup',
        data: schedule.toJson(),
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}

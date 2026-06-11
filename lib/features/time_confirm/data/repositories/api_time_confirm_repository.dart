import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../../../time_setup/data/models/time_schedule.dart';
import '../models/time_confirm_data.dart';
import 'time_confirm_repository.dart';

/// Network-backed [TimeConfirmRepository].
///
/// Implements the AWS schedule endpoints exposed by Swagger. There are no
/// `time-confirm` endpoints on the deployed API, so this repository reads the
/// current day via `GET /api/v1/schedules/daily` and treats modification /
/// acknowledgement as local-only UI actions.
///
/// Errors are funnelled through [failureFromDioException] so callers receive
/// contract-shaped Korean messages. The helper already surfaces the
/// server-supplied `error.message` (e.g. `'이미 수정 요청 중이에요.'` for the
/// `409 ALREADY_REQUESTED` case on `/request-modification`), so no extra
/// code-specific mapping is required here.
class ApiTimeConfirmRepository implements TimeConfirmRepository {
  ApiTimeConfirmRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<TimeConfirmData>> fetchCurrentSchedule() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/schedules/daily',
        queryParameters: <String, dynamic>{'date': _yyyyMmDd(DateTime.now())},
      );
      final Map<String, dynamic>? data = _responseObject(response.data);
      if (data == null) {
        return const Success<TimeConfirmData>(TimeConfirmData(schedule: null));
      }
      return Result<TimeConfirmData>.success(
        TimeConfirmData(schedule: dailyScheduleToTimeSchedule(data)),
      );
    } on DioException catch (e) {
      return failureFromDioException<TimeConfirmData>(e);
    }
  }

  @override
  Future<Result<void>> requestModification() async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> acknowledgeSchedule() async {
    return const Success<void>(null);
  }

  String _yyyyMmDd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic>? _responseObject(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}

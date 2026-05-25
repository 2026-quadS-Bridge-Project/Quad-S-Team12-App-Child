import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/time_confirm_data.dart';
import 'time_confirm_repository.dart';

/// Network-backed [TimeConfirmRepository].
///
/// Implements the three endpoints listed under "Time Confirm" in
/// `docs/api-contract.md`:
///   * `GET  /time-confirm/current`
///   * `POST /time-confirm/request-modification`
///   * `POST /time-confirm/acknowledge`
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
        '/time-confirm/current',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<TimeConfirmData>.failure(
          '요청을 처리할 수 없어요.',
          cause: 'malformed-response',
        );
      }
      final TimeConfirmData parsed = TimeConfirmData.fromJson(
        Map<String, dynamic>.from(data),
      );
      return Result<TimeConfirmData>.success(parsed);
    } on DioException catch (e) {
      return failureFromDioException<TimeConfirmData>(e);
    }
  }

  @override
  Future<Result<void>> requestModification() async {
    try {
      await _dio.post<dynamic>(
        '/time-confirm/request-modification',
        data: <String, dynamic>{},
      );
      return const Success<void>(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> acknowledgeSchedule() async {
    try {
      await _dio.post<dynamic>(
        '/time-confirm/acknowledge',
        data: <String, dynamic>{},
      );
      return const Success<void>(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}

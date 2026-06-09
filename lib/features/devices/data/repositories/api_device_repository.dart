import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import 'device_repository.dart';

class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/fcm/token',
        data: <String, dynamic>{'fcmToken': fcmToken},
      );
      final Object? body = response.data;
      if (body is String) {
        return Result.success(body);
      }
      if (body is Map<String, dynamic>) {
        final Object? data = body['data'];
        if (data is String && data.isNotEmpty) {
          return Result.success(data);
        }
        final String? id = body['id'] as String?;
        if (id != null) return Result.success(id);
      }
      return Result.success('registered');
    } on DioException catch (e) {
      // 409 ALREADY_REGISTERED is a transfer-case (token moved to current
      // user). Treat as success if the server still returned an id.
      if (e.response?.statusCode == 409) {
        final Object? body = e.response?.data;
        if (body is Map<String, dynamic>) {
          final String? id = body['id'] as String?;
          if (id != null) return Result.success(id);
        }
        return Result.success('transferred');
      }
      return failureFromDioException<String>(e);
    }
  }

  @override
  Future<Result<void>> unregisterDevice(String deviceId) async {
    // AWS Swagger exposes token registration only (`POST /api/v1/fcm/token`).
    // There is no unregister endpoint, so real-api mode must not call the
    // legacy `/devices/{id}` path. Local cleanup happens in the caller.
    return Result.success(null);
  }
}

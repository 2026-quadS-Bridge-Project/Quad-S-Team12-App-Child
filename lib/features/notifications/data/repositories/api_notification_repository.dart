import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/notification_item.dart';
import 'notification_repository.dart';

/// Network-backed [NotificationRepository].
///
/// Implements `GET /notifications`, `DELETE /notifications/:id`, and
/// `PATCH /notifications/:id/read` per `docs/api-contract.md`. Each method
/// wraps the Dio call in try/on DioException and funnels failures through
/// [failureFromDioException] for consistent Korean error messages.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/notifications',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'Notifications response was not a JSON object.',
        );
      }
      final dynamic raw = data['notifications'];
      if (raw is! List) {
        throw const FormatException(
          'Notifications response missing "notifications" array.',
        );
      }
      final List<NotificationItem> items = raw
          .cast<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
      return Result<List<NotificationItem>>.success(items);
    } on DioException catch (e) {
      return failureFromDioException<List<NotificationItem>>(e);
    }
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    try {
      await _dio.delete<dynamic>('/api/v1/notifications/$id');
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    try {
      await _dio.patch<dynamic>('/api/v1/notifications/$id/read');
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}

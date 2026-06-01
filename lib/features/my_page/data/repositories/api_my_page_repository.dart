import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/user_profile.dart';
import 'my_page_repository.dart';

/// Network-backed [MyPageRepository].
///
/// Implements `PATCH /api/v1/members/password` and `DELETE /api/v1/members`.
/// (`fetchProfile` still calls `GET /user/profile`, which the backend does not
/// yet expose for child accounts.) Each method wraps the
/// Dio call in try/on DioException and funnels failures through
/// [failureFromDioException] for consistent Korean error messages.
///
/// The password-change contract returns `'현재 비밀번호가 일치하지 않아요.'` for
/// the `WRONG_CURRENT_PASSWORD` (401) code; that exact substring is what the
/// password-change page's inline helper switches on, so we rely on the
/// server-supplied message and avoid bespoke code mapping.
class ApiMyPageRepository implements MyPageRepository {
  ApiMyPageRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<UserProfile>> fetchProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/user/profile',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'Profile response was not a JSON object.',
        );
      }
      final UserProfile profile = UserProfile.fromJson(
        Map<String, dynamic>.from(data),
      );
      return Result<UserProfile>.success(profile);
    } on DioException catch (e) {
      return failureFromDioException<UserProfile>(e);
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/v1/members/password',
        data: <String, dynamic>{
          'oldPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _dio.delete<dynamic>('/api/v1/members');
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}

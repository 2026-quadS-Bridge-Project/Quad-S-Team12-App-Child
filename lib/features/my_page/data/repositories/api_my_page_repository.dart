import 'package:dio/dio.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/user_profile.dart';
import 'my_page_repository.dart';

/// Network-backed [MyPageRepository].
///
/// Implements the AWS member endpoints exposed by Swagger:
/// `PATCH /api/v1/members/password` and `DELETE /api/v1/members`.
/// Swagger does not expose a child profile read endpoint, so [fetchProfile]
/// derives the display-only profile from the local auth session instead of
/// calling the legacy `/user/profile` path. Each network method wraps the
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
    final String username = await AuthSession.username();
    final String? childCode = await AuthSession.childCode();
    return Result<UserProfile>.success(
      UserProfile(
        username: username,
        accountType: '자녀회원',
        childCode: childCode?.isNotEmpty == true ? childCode! : '-',
      ),
    );
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

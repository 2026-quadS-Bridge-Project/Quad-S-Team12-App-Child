import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/auth_token.dart';
import 'auth_repository.dart';

/// Network-backed [AuthRepository].
///
/// Implements `POST /auth/login`, `POST /auth/signup`, `POST /auth/refresh`
/// per `docs/api-contract.md`. Each method wraps the Dio call in a
/// try/catch that funnels [DioException]s through [failureFromDioException]
/// for consistent Korean error messages.
///
/// For login/signup we first inspect the server's `error.code` and map a
/// handful of well-known values to canonical [AuthFailureMessages] strings.
/// This preserves the existing page-level `switch` that compares the
/// failure `message` against those constants. Unknown codes fall through
/// to the generic helper.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<AuthToken>> login({
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, dynamic>{
          'username': username,
          'password': password,
        },
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackUsername: username,
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return _mapAuthLoginError(e);
    }
  }

  @override
  Future<Result<AuthToken>> signup({
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/signup',
        data: <String, dynamic>{
          'username': username,
          'password': password,
        },
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackUsername: username,
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return _mapAuthSignupError(e);
    }
  }

  @override
  Future<Result<AuthToken>> refreshToken(String refreshToken) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      // Refresh response omits username; keep it empty so callers can decide
      // whether to preserve the previously stored value.
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackUsername: '',
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return failureFromDioException<AuthToken>(e);
    }
  }

  /// Tolerant parser: the `/auth/refresh` response shape is
  /// `{ accessToken, refreshToken }` (no username), while login/signup
  /// include `username`. We accept both and substitute [fallbackUsername]
  /// when missing.
  AuthToken _parseTokenResponse(
    dynamic data, {
    required String fallbackUsername,
  }) {
    if (data is! Map) {
      throw const FormatException('Auth response was not a JSON object.');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    return AuthToken(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      username: (json['username'] as String?) ?? fallbackUsername,
    );
  }

  /// Maps server error codes for `/auth/login` onto the canonical Korean
  /// messages the login page already switches on. Falls back to the generic
  /// helper for any unrecognised code.
  Failure<AuthToken> _mapAuthLoginError(DioException e) {
    final String? code = errorCodeOf(e);
    if (code == 'INVALID_CREDENTIALS') {
      return Failure<AuthToken>(
        AuthFailureMessages.wrongPassword,
        cause: code,
      );
    }
    if (code == 'USER_NOT_FOUND') {
      return Failure<AuthToken>(
        AuthFailureMessages.unknownUser,
        cause: code,
      );
    }
    return failureFromDioException<AuthToken>(e);
  }

  /// Same pattern as login: surface duplicate-username as the canonical
  /// constant so the signup page's existing switch keeps working.
  Failure<AuthToken> _mapAuthSignupError(DioException e) {
    final String? code = errorCodeOf(e);
    if (code == 'DUPLICATE_USERNAME') {
      return Failure<AuthToken>(
        AuthFailureMessages.duplicatedUsername,
        cause: code,
      );
    }
    return failureFromDioException<AuthToken>(e);
  }
}

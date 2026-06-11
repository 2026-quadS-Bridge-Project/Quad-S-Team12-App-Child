import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/auth_token.dart';
import 'auth_repository.dart';

/// Network-backed [AuthRepository].
///
/// Implements `POST /auth/children/login`, `POST /auth/children/signup`,
/// `POST /auth/token/refresh`
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
        '/auth/children/login',
        data: <String, dynamic>{'email': username, 'password': password},
      );
      final AuthToken token = _parseTokenResponse(
        response.data,
        fallbackUsername: username,
      );
      return Result<AuthToken>.success(token);
    } on DioException catch (e) {
      return _mapAuthLoginError(e);
    } on FormatException catch (e) {
      return Failure<AuthToken>(
        AuthFailureMessages.invalidAuthResponse,
        cause: e,
      );
    }
  }

  @override
  Future<Result<AuthToken>> signup({
    required String name,
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/children/signup',
        data: <String, dynamic>{
          'name': name,
          'email': username,
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
    } on FormatException catch (e) {
      return Failure<AuthToken>(
        AuthFailureMessages.invalidAuthResponse,
        cause: e,
      );
    }
  }

  @override
  Future<Result<AuthToken>> refreshToken(String refreshToken) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/token/refresh',
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
    } on FormatException catch (e) {
      return Failure<AuthToken>(
        AuthFailureMessages.invalidAuthResponse,
        cause: e,
      );
    }
  }

  /// Tolerant parser for both the unwrapped AuthResponse and the raw
  /// ApiResponse wrapper (`{ isSuccess, code, message, data: AuthResponse }`).
  ///
  /// Login returns tokens, while signup may be tokenless on some backend
  /// builds. In the tokenless case we return an empty [AuthToken.accessToken]
  /// and let the page hand the user off to login instead of crashing.
  AuthToken _parseTokenResponse(
    dynamic data, {
    required String fallbackUsername,
  }) {
    if (data is! Map) {
      throw const FormatException('Auth response was not a JSON object.');
    }
    final Map<String, dynamic> envelope = Map<String, dynamic>.from(data);
    final dynamic payload = envelope['data'] is Map
        ? envelope['data']
        : envelope;
    if (payload is! Map) {
      return AuthToken(
        accessToken: '',
        refreshToken: null,
        username: fallbackUsername,
      );
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(payload);
    return AuthToken(
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: json['refreshToken'] as String?,
      username:
          (json['username'] as String?) ??
          (json['email'] as String?) ??
          fallbackUsername,
      memberId: json['memberId']?.toString(),
      name: json['name'] as String?,
      childCode: json['childCode'] as String?,
    );
  }

  /// Maps server error codes for `/auth/login` onto the canonical Korean
  /// messages the login page already switches on. Falls back to the generic
  /// helper for any unrecognised code.
  Failure<AuthToken> _mapAuthLoginError(DioException e) {
    final String? code = errorCodeOf(e);
    if (code == 'INVALID_CREDENTIALS') {
      return Failure<AuthToken>(AuthFailureMessages.wrongPassword, cause: code);
    }
    if (code == 'USER_NOT_FOUND') {
      return Failure<AuthToken>(AuthFailureMessages.unknownUser, cause: code);
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

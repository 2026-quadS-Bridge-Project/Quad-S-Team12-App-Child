import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import 'environment.dart';

/// Factory for the app-wide [Dio] HTTP client.
///
/// Wires a single auth-header interceptor that injects the stored bearer
/// token (when present) and a stub 401 handler that will be replaced once
/// refresh-token rotation is implemented.
class DioConfig {
  const DioConfig._();

  static Dio create({EnvironmentConfig? overrideConfig}) {
    final EnvironmentConfig env = overrideConfig ?? currentEnvironment;
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          RequestOptions options,
          RequestInterceptorHandler handler,
        ) async {
          final String? token = await AuthSession.accessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          // TODO(auth): on 401, attempt refresh-token rotation before failing.
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}

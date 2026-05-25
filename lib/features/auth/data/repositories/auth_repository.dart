import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/auth_token.dart';
import 'api_auth_repository.dart';
import 'mock_auth_repository.dart';

/// Repository contract for authentication operations (login + signup).
///
/// Implementations return [Result] so the presentation layer can branch on
/// success / failure without exceptions leaking into widget code. Failure
/// messages are user-facing Korean strings that pages map back into their
/// local error enums.
abstract interface class AuthRepository {
  Future<Result<AuthToken>> login({
    required String username,
    required String password,
  });

  Future<Result<AuthToken>> signup({
    required String username,
    required String password,
  });

  /// Exchanges a [refreshToken] for a fresh access/refresh pair.
  ///
  /// The Dio 401 interceptor uses a separate, interceptor-free client to
  /// perform this exchange (so the refresh call itself cannot recurse). This
  /// method exists for callers that want an explicit refresh — e.g. a future
  /// "force re-auth" admin flow — and for tests.
  Future<Result<AuthToken>> refreshToken(String refreshToken);
}

/// Factory that resolves the active [AuthRepository] implementation based on
/// [currentEnvironment.useMocks]. Pages call this once via a `late final`
/// field so the choice is made lazily but cached for the widget's lifetime.
AuthRepository createAuthRepository() {
  if (currentEnvironment.useMocks) {
    return MockAuthRepository();
  }
  return ApiAuthRepository();
}

/// Canonical failure messages emitted by [MockAuthRepository.login]. Exposed
/// as constants so the login page can do an exact-match string comparison
/// when mapping back to its local `_LoginErrorType` enum — no substring
/// matching, no sealed-class plumbing.
abstract final class AuthFailureMessages {
  static const String unknownUser = '아이디를 다시 확인해 주세요.';
  static const String wrongPassword = '비밀번호가 일치하지 않아요.';
  static const String duplicatedUsername = '이미 사용 중인 아이디예요.';
}

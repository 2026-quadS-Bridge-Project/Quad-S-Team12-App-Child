import '../../../../core/models/result.dart';
import '../models/auth_token.dart';
import 'auth_repository.dart';

/// In-memory [AuthRepository] used while the real backend is unavailable.
///
/// Preserves the exact validation rules that previously lived inline in
/// `login_page.dart` and `signup_page.dart`:
/// - login accepts the hard-coded mock username set + single password.
/// - signup rejects usernames already in [_takenUsernames].
///
/// Mock tokens are deterministic strings derived from the username so that
/// the Dio interceptor (Phase 2A) sees a non-empty bearer value in dev.
class MockAuthRepository implements AuthRepository {
  static const Set<String> _mockUsernames = <String>{'gdg12', 'abcd00'};
  static const String _mockPassword = 'Gdg123456789!';
  static const Set<String> _takenUsernames = <String>{'gdg12'};

  @override
  Future<Result<AuthToken>> login({
    required String username,
    required String password,
  }) async {
    if (!_mockUsernames.contains(username)) {
      return Result<AuthToken>.failure(AuthFailureMessages.unknownUser);
    }
    if (password != _mockPassword) {
      return Result<AuthToken>.failure(AuthFailureMessages.wrongPassword);
    }
    return Result<AuthToken>.success(
      AuthToken(
        accessToken: 'mock_access_$username',
        refreshToken: 'mock_refresh_$username',
        username: username,
      ),
    );
  }

  @override
  Future<Result<AuthToken>> signup({
    required String username,
    required String password,
  }) async {
    if (_takenUsernames.contains(username)) {
      return Result<AuthToken>.failure(AuthFailureMessages.duplicatedUsername);
    }
    return Result<AuthToken>.success(
      AuthToken(
        accessToken: 'mock_access_$username',
        refreshToken: 'mock_refresh_$username',
        username: username,
      ),
    );
  }
}

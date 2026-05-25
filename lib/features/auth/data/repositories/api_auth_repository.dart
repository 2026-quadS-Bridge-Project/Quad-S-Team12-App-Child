import '../../../../core/models/result.dart';
import '../models/auth_token.dart';
import 'auth_repository.dart';

/// Network-backed [AuthRepository] stub.
///
/// Phase 2B scaffolding only — every method throws [UnimplementedError] so
/// that accidentally pointing the app at a non-mock environment fails loudly
/// instead of silently swallowing auth requests. Real Dio wiring lands in a
/// follow-up phase once backend endpoints are finalized.
class ApiAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthToken>> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError('ApiAuthRepository.login is not yet wired.');
  }

  @override
  Future<Result<AuthToken>> signup({
    required String username,
    required String password,
  }) {
    throw UnimplementedError('ApiAuthRepository.signup is not yet wired.');
  }
}

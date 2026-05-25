import '../../../../core/models/result.dart';
import '../models/user_profile.dart';
import 'my_page_repository.dart';

/// HTTP-backed implementation of [MyPageRepository].
///
/// Stub for Phase 2A — every method throws [UnimplementedError] until
/// backend endpoints are confirmed and wired through `DioConfig`.
class ApiMyPageRepository implements MyPageRepository {
  @override
  Future<Result<UserProfile>> fetchProfile() async {
    throw UnimplementedError(
      'ApiMyPageRepository.fetchProfile: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError(
      'ApiMyPageRepository.changePassword: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> deleteAccount() async {
    throw UnimplementedError(
      'ApiMyPageRepository.deleteAccount: backend not wired yet.',
    );
  }
}

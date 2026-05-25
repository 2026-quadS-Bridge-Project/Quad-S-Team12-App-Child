import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/user_profile.dart';
import 'api_my_page_repository.dart';
import 'mock_my_page_repository.dart';

/// Repository contract for the MyPage feature.
///
/// Covers the three operations surfaced on the profile screen:
///   * [fetchProfile]      — read the user's profile card data.
///   * [changePassword]    — submit a password update.
///   * [deleteAccount]     — request account deletion (탈퇴).
///
/// Concrete implementations:
///   * [MockMyPageRepository] — returns canned data and validates against
///     the existing demo password while [EnvironmentConfig.useMocks] is true.
///   * [ApiMyPageRepository]  — calls the real backend (stubbed for now).
abstract interface class MyPageRepository {
  /// Fetch the current user's profile card data.
  Future<Result<UserProfile>> fetchProfile();

  /// Change the user's password.
  ///
  /// Returns [Failure] with a user-facing message if [currentPassword]
  /// does not match the stored password.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Request permanent account deletion (탈퇴하기).
  Future<Result<void>> deleteAccount();
}

/// Factory that picks the right repo for the current environment.
MyPageRepository createMyPageRepository() {
  if (currentEnvironment.useMocks) {
    return MockMyPageRepository();
  }
  return ApiMyPageRepository();
}

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../models/user_profile.dart';
import 'my_page_repository.dart';

/// Mock implementation of [MyPageRepository].
///
/// Used while [currentEnvironment.useMocks] is true. [fetchProfile] sources
/// the username from [AuthSession] so the profile card reflects whichever
/// account the demo user logged in with; the remaining fields are canned
/// values aligned with the Figma spec (see audit 08-mypage.md Issue 8).
class MockMyPageRepository implements MyPageRepository {
  /// Demo password kept in sync with the existing
  /// `PasswordChangePage._mockCurrentPassword` value so the change-password
  /// flow validates against a single source of truth.
  static const String _mockCurrentPassword = 'Gdg123456789!';
  static const String _mockAccountType = '자녀회원';
  static const String _mockChildCode = 'XY785eZ';

  @override
  Future<Result<UserProfile>> fetchProfile() async {
    final String username = await AuthSession.username();
    return Result<UserProfile>.success(
      UserProfile(
        username: username,
        accountType: _mockAccountType,
        childCode: _mockChildCode,
      ),
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword != _mockCurrentPassword) {
      return Result<void>.failure('현재 비밀번호가 일치하지 않아요.');
    }
    // Mock backend accepts any new password that survived client-side
    // validation. No persistence — the next session still uses the demo
    // password.
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    return Result<void>.success(null);
  }
}

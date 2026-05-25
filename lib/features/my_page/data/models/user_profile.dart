/// User profile data surfaced on the MyPage screen.
///
/// Aggregates the three read-only fields rendered in the info rows
/// (회원유형 / 아이디 / 자녀코드). Wired through [MyPageRepository.fetchProfile].
class UserProfile {
  const UserProfile({
    required this.username,
    required this.accountType,
    required this.childCode,
  });

  /// Login id (e.g., 'gdg12').
  final String username;

  /// Account type label (e.g., '자녀회원').
  final String accountType;

  /// Child-link code displayed on the profile (e.g., 'XY785eZ').
  final String childCode;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        username: json['username'] as String,
        accountType: json['accountType'] as String? ?? '자녀회원',
        childCode: json['childCode'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'username': username,
        'accountType': accountType,
        'childCode': childCode,
      };
}

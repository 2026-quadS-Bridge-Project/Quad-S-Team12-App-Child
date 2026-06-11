/// Authentication token bundle returned from a successful login or signup.
///
/// Carries the [accessToken] (and optional [refreshToken]) used by the Dio
/// auth interceptor, plus the resolved [username] that the page layer
/// persists into [AuthSession] alongside the token pair.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.username,
    this.memberId,
    this.name,
    this.childCode,
  });

  final String accessToken;
  final String? refreshToken;
  final String username;
  final String? memberId;
  final String? name;
  final String? childCode;

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    username: json['username'] as String,
    memberId: json['memberId']?.toString(),
    name: json['name'] as String?,
    childCode: json['childCode'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'username': username,
    if (memberId != null) 'memberId': memberId,
    if (name != null) 'name': name,
    if (childCode != null) 'childCode': childCode,
  };
}

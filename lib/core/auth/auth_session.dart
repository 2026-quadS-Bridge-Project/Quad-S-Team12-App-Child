import 'package:shared_preferences/shared_preferences.dart';

abstract final class AuthSession {
  static const String loggedInKey = 'bridge_k.is_logged_in';
  static const String usernameKey = 'bridge_k.username';
  static const String memberIdKey = 'bridge_k.member_id';
  static const String nameKey = 'bridge_k.name';
  static const String childCodeKey = 'bridge_k.child_code';
  static const String fallbackUsername = 'abcd00';

  // Token storage keys (Phase 2A scaffolding — wired to interceptors).
  static const String _accessTokenKey = 'bridge_k.access_token';
  static const String _refreshTokenKey = 'bridge_k.refresh_token';

  static Future<void> saveLogin({
    required String username,
    String? memberId,
    String? name,
    String? childCode,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(loggedInKey, true);
    await preferences.setString(usernameKey, username);
    await _setOptionalString(preferences, memberIdKey, memberId);
    await _setOptionalString(preferences, nameKey, name);
    await _setOptionalString(preferences, childCodeKey, childCode);
  }

  static Future<void> saveProfile({
    String? memberId,
    String? name,
    String? childCode,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await _saveOptionalString(preferences, memberIdKey, memberId);
    await _saveOptionalString(preferences, nameKey, name);
    await _saveOptionalString(preferences, childCodeKey, childCode);
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loggedInKey) ?? false;
  }

  static Future<String> username() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(usernameKey) ?? fallbackUsername;
  }

  static Future<String?> memberId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(memberIdKey);
  }

  static Future<String?> name() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(nameKey);
  }

  static Future<String?> childCode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(childCodeKey);
  }

  static Future<void> clearLogin() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(loggedInKey);
    await preferences.remove(usernameKey);
    await preferences.remove(memberIdKey);
    await preferences.remove(nameKey);
    await preferences.remove(childCodeKey);
  }

  /// Persist an [accessToken] (and optional [refreshToken]) in
  /// SharedPreferences. Tokens are stored alongside — not in place of —
  /// the existing username/logged-in flags.
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await preferences.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Returns the stored access token, or `null` if none is present.
  static Future<String?> accessToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_accessTokenKey);
  }

  /// Returns the stored refresh token, or `null` if none is present.
  static Future<String?> refreshToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_refreshTokenKey);
  }

  /// Removes only token entries — kept separate from [clearLogin] so the
  /// auth flow can iterate on the two concerns independently.
  static Future<void> clearTokens() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
  }

  static Future<void> _saveOptionalString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      return;
    }
    await preferences.setString(key, value);
  }

  static Future<void> _setOptionalString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await preferences.remove(key);
      return;
    }
    await preferences.setString(key, value);
  }
}

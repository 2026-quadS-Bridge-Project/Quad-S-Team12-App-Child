import 'package:shared_preferences/shared_preferences.dart';

abstract final class AuthSession {
  static const String loggedInKey = 'bridge_k.is_logged_in';
  static const String usernameKey = 'bridge_k.username';
  static const String fallbackUsername = 'abcd00';

  // Token storage keys (Phase 2A scaffolding — wired to interceptors).
  static const String _accessTokenKey = 'bridge_k.access_token';
  static const String _refreshTokenKey = 'bridge_k.refresh_token';

  static Future<void> saveLogin({required String username}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(loggedInKey, true);
    await preferences.setString(usernameKey, username);
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loggedInKey) ?? false;
  }

  static Future<String> username() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(usernameKey) ?? fallbackUsername;
  }

  static Future<void> clearLogin() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(loggedInKey);
    await preferences.remove(usernameKey);
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
}

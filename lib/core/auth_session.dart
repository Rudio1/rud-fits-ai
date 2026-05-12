abstract final class AuthSession {
  static String? _token;
  static String? _username;

  static void setToken(String token) => _token = token;
  static void setUsername(String? username) => _username = username;
  static String? get token => _token;
  static String? get username => _username;
  static bool get isAuthenticated => _token != null;

  static void clear() {
    _token = null;
    _username = null;
  }
}

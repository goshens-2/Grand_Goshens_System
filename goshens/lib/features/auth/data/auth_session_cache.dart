class AuthSessionCache {
  static String? role;

  static bool get isAdmin => role == 'admin';

  static void remember(String? value) {
    role = value;
  }

  static void clear() {
    role = null;
  }
}

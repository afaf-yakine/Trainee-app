class AuthService {
  // This is a stub for future backend integration (Firebase, API, etc.)

  static Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required String specialty,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

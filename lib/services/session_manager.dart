import '../entities/user.dart';

// Singleton manager to hold user session tokens and credentials at runtime
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  String? _token;
  User? _currentUser;

  // Retrieve current active JWT token
  String? get token => _token;

  // Retrieve current active User profile
  User? get currentUser => _currentUser;

  // Checks whether the user is logged in
  bool get isAuthenticated => _token != null;

  // Save authentication details in memory
  void saveSession(String token, User user) {
    _token = token;
    _currentUser = user;
  }

  // Clear session data upon sign out
  void clearSession() {
    _token = null;
    _currentUser = null;
  }
}

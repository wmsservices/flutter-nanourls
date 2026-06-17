import 'package:purchases_flutter/purchases_flutter.dart';
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

  // Save authentication details in memory and bind user to RevenueCat
  void saveSession(String token, User user) {
    _token = token;
    _currentUser = user;
    if (user.userId.isNotEmpty) {
      _bindRevenueCatUser(user.userId);
    }
  }

  // Clear session data upon sign out and unbind from RevenueCat
  void clearSession() {
    _token = null;
    _currentUser = null;
    _unbindRevenueCatUser();
  }

  void _bindRevenueCatUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {
      // Silently catch configuration or connection issues during development
    }
  }

  void _unbindRevenueCatUser() async {
    try {
      await Purchases.logOut();
    } catch (_) {
      // Silently catch error
    }
  }
}

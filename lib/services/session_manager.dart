import 'package:purchases_flutter/purchases_flutter.dart';
import '../entities/user.dart';
import 'admob_controller.dart';
import 'api_service.dart';

// Singleton manager to hold user session tokens and credentials at runtime
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  String? _token;
  User? _currentUser;
  bool? _showAds;

  // Retrieve current active JWT token
  String? get token => _token;

  // Retrieve current active User profile
  User? get currentUser => _currentUser;

  // Checks whether the user is logged in
  bool get isAuthenticated => _token != null;

  // Getter for showAds (true if ads should be displayed, false otherwise)
  bool get showAds {
    if (_showAds != null) return _showAds!;
    if (_currentUser != null) {
      return _currentUser!.planId == 1; // Fallback: planId == 1 shows ads, others do not
    }
    return true; // Guest users see ads
  }

  void setShowAds(bool value) {
    _showAds = value;
    AdmobController.instance.onAdsStatusChanged();
  }

  // Save authentication details in memory and bind user to RevenueCat
  void saveSession(String token, User user) {
    final oldPlanId = _currentUser?.planId;
    _token = token;
    _currentUser = user;
    if (user.userId.isNotEmpty) {
      _bindRevenueCatUser(user.userId);
    }

    // If showAds is not set or user's plan changed, update default value and fetch details
    if (_showAds == null || oldPlanId != user.planId) {
      _showAds = (user.planId == 1);
      AdmobController.instance.onAdsStatusChanged();
      _fetchAndCachePlanAdsStatus(user.planId);
    }
  }

  // Clear session data upon sign out and unbind from RevenueCat
  void clearSession() {
    _token = null;
    _currentUser = null;
    _showAds = true;
    _unbindRevenueCatUser();
    AdmobController.instance.onAdsStatusChanged();
  }

  void _fetchAndCachePlanAdsStatus(int planId) async {
    try {
      final apiService = ApiService();
      final plan = await apiService.fetchPlanById(planId.toString());
      setShowAds(plan.showAds);
    } catch (_) {
      // Keep using fallback
    }
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

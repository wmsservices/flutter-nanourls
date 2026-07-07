import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to read, write and persist AdMob action counts by user ID
class AdsHelper {
  static const String _keyPrefix = 'ad_action_count_';

  /// Retrieves the current persisted action count for a user ID
  static Future<int> getActionCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print("Retrieve the current persisted action count for a user ID $userId");
      }
      return prefs.getInt('$_keyPrefix$userId') ?? 0;
    } catch (_) {
      if (kDebugMode) {
        print("Fail retrieving the current persisted action count for a user ID $userId");
      }
      return 0; // Return 0 if SharedPreferences throws an error
    }
  }

  /// Increments the action count for a user ID and returns the new count
  static Future<int> incrementActionCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt('$_keyPrefix$userId') ?? 0;
      if (kDebugMode) {
        print("Getting count for a user$userId at $current");
      }
      final next = current + 1;
      await prefs.setInt('$_keyPrefix$userId', next);
      if (kDebugMode) {
        print("Setting count for a user$userId at $next");
      }
      return next;
    } catch (_) {
      if (kDebugMode) {
        print("Fail increment the action count for a user $userId");
      }
      return 0;
    }
  }

  /// Resets the action count for a user ID
  static Future<void> resetActionCount(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_keyPrefix$userId', 0);
      if (kDebugMode) {
        print("Reset the action count for a user $userId");
      }
    } catch (_) {
      if (kDebugMode) {
        print("Fail reset the action count for a user $userId");
      }
    }
  }
}

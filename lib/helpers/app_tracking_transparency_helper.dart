import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

class AppTrackingTransparencyHelper {

  static Future<void> requestAppTrackingTransparency ()async {
    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency
            .trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          if (kDebugMode) {
            print("TrackingStatus not Determined. Requesting user's Authorization...");
          }
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
        if (kDebugMode) {
          print("TrackingStatus is ${status.name}");
        }
      }
    } catch (_) {
      // Fallback silencioso se falhar
      if (kDebugMode) {
        print("Error on Tracking Authorization Status");
      }
    }
  }
}
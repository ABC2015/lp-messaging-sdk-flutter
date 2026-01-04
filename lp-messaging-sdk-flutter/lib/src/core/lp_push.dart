import '../../lp_messaging_sdk_flutter_platform_interface.dart';

/// Push helper API.
///
/// This intentionally provides platform-agnostic helpers,
/// mapping to the platform interface method under the hood.
class LpPush {
  LpPush._(); // no instances

  /// Register an FCM token (Android).
  static Future<void> registerFcmToken(String token) {
    return LpMessagingSdkFlutterPlatform.instance.registerPushToken(
      token: token,
      provider: 'fcm',
    );
  }

  /// Register an APNs token (iOS).
  static Future<void> registerApnsToken(String token) {
    return LpMessagingSdkFlutterPlatform.instance.registerPushToken(
      token: token,
      provider: 'apns',
    );
  }

  /// Unregister current push token (if supported by native SDK).
  static Future<void> unregister() {
    return LpMessagingSdkFlutterPlatform.instance.unregisterPushToken();
  }
}

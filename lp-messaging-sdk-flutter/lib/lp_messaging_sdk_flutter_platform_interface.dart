import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lp_messaging_sdk_flutter_method_channel.dart';
import 'src/core/events/lp_event.dart';
import 'src/core/lp_config.dart';
import 'src/core/lp_conversation_params.dart';

/// Platform interface for the plugin.
///
/// Why this exists:
/// - Supports alternate implementations (e.g., web, desktop, mock)
/// - Keeps MethodChannel implementation replaceable and testable
/// - Follows Flutter plugin best practices
abstract class LpMessagingSdkFlutterPlatform extends PlatformInterface {
  LpMessagingSdkFlutterPlatform() : super(token: _token);

  /// Token used by PlatformInterface.verifyToken to prevent accidental overrides.
  static final Object _token = Object();

  /// Default implementation is the MethodChannel-based one.
  static LpMessagingSdkFlutterPlatform _instance =
      MethodChannelLpMessagingSdkFlutter();

  static LpMessagingSdkFlutterPlatform get instance => _instance;

  /// Override point for injecting mocks or platform-specific alternatives.
  static set instance(LpMessagingSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes underlying native SDK.
  ///
  /// You typically call this once at app startup or before showing conversation UI.
  Future<void> initialize(LpConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Shows the messaging UI / conversation.
  Future<void> showConversation(LpConversationParams params) {
    throw UnimplementedError('showConversation() has not been implemented.');
  }

  /// Dismisses conversation UI if the native side supports dismissal.
  Future<void> dismissConversation() {
    throw UnimplementedError('dismissConversation() has not been implemented.');
  }

  /// Logs out / clears session. Semantics depend on the underlying SDK.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Sets user profile info if the SDK supports identifying the user.
  Future<void> setUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    throw UnimplementedError('setUserProfile() has not been implemented.');
  }

  /// Registers a push token with the SDK (e.g., for proactive notifications).
  ///
  /// provider should be "apns" or "fcm"
  Future<void> registerPushToken({
    required String token,
    required String provider,
  }) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  /// Unregisters push token (if supported).
  Future<void> unregisterPushToken() {
    throw UnimplementedError('unregisterPushToken() has not been implemented.');
  }

  /// Stream of typed events emitted by native.
  ///
  /// Under the hood, this will map raw platform payloads into strongly typed
  /// Dart event classes.
  Stream<LpEvent> events() {
    throw UnimplementedError('events() has not been implemented.');
  }
}

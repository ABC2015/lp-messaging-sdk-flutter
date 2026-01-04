import '../../lp_messaging_sdk_flutter_platform_interface.dart';
import 'events/lp_event.dart';
import 'lp_config.dart';
import 'lp_conversation_params.dart';

/// High-level convenience wrapper for the plugin.
///
/// Why:
/// - Gives app developers a "simple" API without touching platform interface.
/// - Keeps platform interface reserved for advanced customization/mocking.
class LpMessaging {
  LpMessagingSdkFlutterPlatform get _platform =>
      LpMessagingSdkFlutterPlatform.instance;

  /// Initialize the SDK.
  Future<void> initialize(LpConfig config) => _platform.initialize(config);

  /// Show/open a conversation UI.
  Future<void> showConversation(LpConversationParams params) =>
      _platform.showConversation(params);

  /// Dismiss conversation UI.
  Future<void> dismissConversation() => _platform.dismissConversation();

  /// Clear session.
  Future<void> logout() => _platform.logout();

  /// Subscribe to events.
  Stream<LpEvent> events() => _platform.events();
}

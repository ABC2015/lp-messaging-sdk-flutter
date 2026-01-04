/// Public library entrypoint.
///
/// This file defines the public surface area of your plugin package.
/// Anything exported here becomes part of your plugin's public API.
///
/// Pattern:
/// - Keep this file "thin"
/// - Export stable types that app developers should import and use
library lp_messaging_sdk_flutter;

// Core configuration / parameters
export 'src/core/lp_config.dart';
export 'src/core/lp_conversation_params.dart';

// Events exposed to the app
export 'src/core/events/lp_event.dart';
export 'src/core/events/lp_connection_event.dart';
export 'src/core/events/lp_conversation_event.dart';
export 'src/core/events/lp_error_event.dart';
export 'src/core/events/lp_message_event.dart';

// Errors and logging utilities
export 'src/core/lp_errors.dart';
export 'src/core/lp_logging.dart';

// High-level convenience facades
export 'src/core/lp_messaging.dart';
export 'src/core/lp_push.dart';

// Optional: export platform interface so advanced callers can swap implementations.
export 'lp_messaging_sdk_flutter_platform_interface.dart'
    show LpMessagingSdkFlutterPlatform;

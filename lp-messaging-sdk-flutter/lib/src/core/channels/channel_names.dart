/// Central location for channel names.
///
/// Keeping these in one file prevents accidental mismatches between:
/// - Dart method channel
/// - Android Kotlin channel
/// - iOS Swift channel
class ChannelNames {
  static const String methodChannel = 'lp_messaging_sdk_flutter/methods';
  static const String eventChannel = 'lp_messaging_sdk_flutter/events';
}

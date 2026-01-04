/// Logging abstraction.
///
/// This keeps your plugin from depending on any specific logging package.
/// The host app can replace the sink to redirect logs into its logger.
typedef LpLogSink = void Function(String tag, String message);

class LpLog {
  // Default sink prints to console.
  static LpLogSink _sink = _defaultSink;

  /// Host app can call this to integrate with its own logging solution.
  static void setSink(LpLogSink sink) {
    _sink = sink;
  }

  /// Debug-level log.
  static void d(String tag, String message) => _sink(tag, message);

  static void _defaultSink(String tag, String message) {
    // ignore: avoid_print
    print('[LP][$tag] $message');
  }
}

import '../models/lp_enums.dart';

typedef LpLogSink = void Function(String message);

/// Simple logger with pluggable sink and level.
class LpLogger {
  LpLogger({
    this.level = LpLogLevel.info,
    LpLogSink? sink,
  }) : _sink = sink ?? _defaultSink;

  final LpLogLevel level;
  final LpLogSink _sink;

  static void _defaultSink(String message) {
    // ignore: avoid_print
    print(message);
  }

  bool get _debugEnabled => level.index <= LpLogLevel.debug.index;
  bool get _infoEnabled => level.index <= LpLogLevel.info.index;
  bool get _warnEnabled => level.index <= LpLogLevel.warning.index;
  bool get _errorEnabled => level.index <= LpLogLevel.error.index;

  void debug(String msg) {
    if (_debugEnabled) _sink('[LP DEBUG] $msg');
  }

  void info(String msg) {
    if (_infoEnabled) _sink('[LP INFO] $msg');
  }

  void warn(String msg) {
    if (_warnEnabled) _sink('[LP WARN] $msg');
  }

  void error(String msg, Object error, StackTrace st) {
    if (_errorEnabled) _sink('[LP ERROR] $msg - $error\n$st');
  }
}

import 'package:flutter/services.dart';

/// Thin wrapper around EventChannel.
///
/// Why:
/// - Lets you mock streams in tests
/// - Separates channel creation concerns from plugin logic
class EventChannelClient {
  final EventChannel channel;

  const EventChannelClient(this.channel);

  /// Receive a broadcast stream from native.
  ///
  /// Native side pushes events to this stream.
  Stream<dynamic> receiveBroadcastStream([Object? arguments]) {
    return channel.receiveBroadcastStream(arguments);
  }
}

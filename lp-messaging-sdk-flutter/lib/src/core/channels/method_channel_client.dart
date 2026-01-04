import 'package:flutter/services.dart';

/// Thin wrapper around MethodChannel.
///
/// Why:
/// - Allows dependency injection for tests
/// - Makes mocking easier without touching global channels
class MethodChannelClient {
  final MethodChannel channel;

  const MethodChannelClient(this.channel);

  /// Generic invoke helper.
  ///
  /// T is the expected return type (often void/null in plugin calls).
  Future<T?> invoke<T>(String method, [Object? arguments]) {
    return channel.invokeMethod<T>(method, arguments);
  }
}

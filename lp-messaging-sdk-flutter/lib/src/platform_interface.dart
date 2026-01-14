import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models.dart';
import 'method_channel_impl.dart';

abstract class LpMessagingPlatform extends PlatformInterface {
  LpMessagingPlatform() : super(token: _token);

  static final Object _token = Object();

  static LpMessagingPlatform _instance = MethodChannelLpMessaging();

  static LpMessagingPlatform get instance => _instance;

  static set instance(LpMessagingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize(LpNativeInitConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> showConversation({LpAuthConfig? auth}) {
    throw UnimplementedError('showConversation() has not been implemented.');
  }

  Future<void> hideConversation() {
    throw UnimplementedError('hideConversation() has not been implemented.');
  }

  Future<void> setUserProfile(LpUserProfile profile) {
    throw UnimplementedError('setUserProfile() has not been implemented.');
  }

  Future<void> registerPushToken(LpPushConfig config) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  Future<void> unregisterPushToken() {
    throw UnimplementedError('unregisterPushToken() has not been implemented.');
  }

  Future<int> getUnreadCount({LpAuthConfig? auth}) {
    throw UnimplementedError('getUnreadCount() has not been implemented.');
  }

  Future<void> setDebugLogging(bool enabled) {
    throw UnimplementedError('setDebugLogging() has not been implemented.');
  }

  Future<void> reset() {
    throw UnimplementedError('reset() has not been implemented.');
  }

  Stream<Map<String, dynamic>> get events {
    throw UnimplementedError('events has not been implemented.');
  }
}

/// Public facade your apps will use.
class LpMessaging {
  static Future<void> initialize(LpNativeInitConfig config) =>
      LpMessagingPlatform.instance.initialize(config);

  static Future<void> showConversation({LpAuthConfig? auth}) =>
      LpMessagingPlatform.instance.showConversation(auth: auth);

  static Future<void> hideConversation() =>
      LpMessagingPlatform.instance.hideConversation();

  static Future<void> setUserProfile(LpUserProfile profile) =>
      LpMessagingPlatform.instance.setUserProfile(profile);

  static Future<void> registerPushToken(LpPushConfig config) =>
      LpMessagingPlatform.instance.registerPushToken(config);

  static Future<void> unregisterPushToken() =>
      LpMessagingPlatform.instance.unregisterPushToken();

  static Future<int> getUnreadCount({LpAuthConfig? auth}) =>
      LpMessagingPlatform.instance.getUnreadCount(auth: auth);

  static Future<void> setDebugLogging(bool enabled) =>
      LpMessagingPlatform.instance.setDebugLogging(enabled);

  static Future<void> reset() => LpMessagingPlatform.instance.reset();

  static Stream<Map<String, dynamic>> get events =>
      LpMessagingPlatform.instance.events;

  static Stream<Map<String, dynamic>> eventsWithLogging({
    String tag = 'LpMessaging',
    bool pretty = true,
  }) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : null;
    return events.map((event) {
      final payload = encoder == null ? event.toString() : encoder.convert(event);
      debugPrint('[$tag] $payload');
      return event;
    });
  }
}

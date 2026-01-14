import 'package:flutter/services.dart';

import 'models.dart';
import 'platform_interface.dart';

class MethodChannelLpMessaging extends LpMessagingPlatform {
  static const MethodChannel _channel =
      MethodChannel('lp_messaging_sdk_flutter');
  static const EventChannel _eventChannel =
      EventChannel('lp_messaging_sdk_flutter/events');

  Stream<Map<String, dynamic>>? _events;

  @override
  Future<void> initialize(LpNativeInitConfig config) async {
    await _channel.invokeMethod('initialize', config.toMap());
  }

  @override
  Future<void> showConversation({LpAuthConfig? auth}) async {
    await _channel.invokeMethod('showConversation', {
      'auth': auth?.toMap(),
    });
  }

  @override
  Future<void> hideConversation() async {
    await _channel.invokeMethod('hideConversation');
  }

  @override
  Future<void> setUserProfile(LpUserProfile profile) async {
    await _channel.invokeMethod('setUserProfile', profile.toMap());
  }

  @override
  Future<void> registerPushToken(LpPushConfig config) async {
    await _channel.invokeMethod('registerPushToken', config.toMap());
  }

  @override
  Future<void> unregisterPushToken() async {
    await _channel.invokeMethod('unregisterPushToken');
  }

  @override
  Future<int> getUnreadCount({LpAuthConfig? auth}) async {
    final count = await _channel.invokeMethod<int>('getUnreadCount', {
      'auth': auth?.toMap(),
    });
    return count ?? 0;
  }

  @override
  Future<void> setDebugLogging(bool enabled) async {
    await _channel.invokeMethod('setDebugLogging', {
      'enabled': enabled,
    });
  }

  @override
  Future<void> reset() async {
    await _channel.invokeMethod('reset');
  }

  @override
  Stream<Map<String, dynamic>> get events {
    _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return event.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{'type': 'unknown', 'raw': event};
    });
    return _events!;
  }
}

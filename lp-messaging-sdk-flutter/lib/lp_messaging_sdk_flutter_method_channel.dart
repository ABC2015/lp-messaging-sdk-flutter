import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lp_messaging_sdk_flutter_platform_interface.dart';
import 'src/core/channels/channel_names.dart';
import 'src/core/channels/event_channel_client.dart';
import 'src/core/channels/method_channel_client.dart';
import 'src/core/events/lp_event.dart';
import 'src/core/lp_config.dart';
import 'src/core/lp_conversation_params.dart';
import 'src/core/mappers/event_mapper.dart';
import 'src/core/lp_logging.dart';

/// Default platform implementation using MethodChannel + EventChannel.
///
/// Responsibilities:
/// - Sends commands to native via MethodChannel
/// - Receives async events from native via EventChannel
/// - Converts events into typed Dart models
class MethodChannelLpMessagingSdkFlutter extends LpMessagingSdkFlutterPlatform {
  // Wrappers exist mainly to make unit testing easier (swap out in tests).
  final MethodChannelClient _methodClient;
  final EventChannelClient _eventClient;

  // Converts raw native events into typed LpEvent instances.
  final EventMapper _eventMapper;

  MethodChannelLpMessagingSdkFlutter({
    MethodChannelClient? methodClient,
    EventChannelClient? eventClient,
    EventMapper? eventMapper,
  }) : _methodClient =
           methodClient ??
           MethodChannelClient(const MethodChannel(ChannelNames.methodChannel)),
       _eventClient =
           eventClient ??
           EventChannelClient(const EventChannel(ChannelNames.eventChannel)),
       _eventMapper = eventMapper ?? const EventMapper();

  // Cached stream so multiple listeners share the same underlying event channel.
  Stream<LpEvent>? _events;

  @override
  Future<void> initialize(LpConfig config) async {
    // Debug logging for development; can be turned off by the app.
    LpLog.d('initialize', config.toJson().toString());

    // Send a fire-and-forget initialization request to native.
    await _methodClient.invoke<void>('initialize', config.toJson());
  }

  @override
  Future<void> showConversation(LpConversationParams params) async {
    LpLog.d('showConversation', params.toJson().toString());
    await _methodClient.invoke<void>('showConversation', params.toJson());
  }

  @override
  Future<void> dismissConversation() async {
    LpLog.d('dismissConversation', '');
    await _methodClient.invoke<void>('dismissConversation');
  }

  @override
  Future<void> logout() async {
    LpLog.d('logout', '');
    await _methodClient.invoke<void>('logout');
  }

  @override
  Future<void> setUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    // Keep payload stable and explicit; avoid sending nulls if you prefer.
    final payload = <String, Object?>{
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    };
    await _methodClient.invoke<void>('setUserProfile', payload);
  }

  @override
  Future<void> registerPushToken({
    required String token,
    required String provider,
  }) async {
    await _methodClient.invoke<void>('registerPushToken', {
      'token': token,
      'provider': provider, // expected: 'apns' or 'fcm'
    });
  }

  @override
  Future<void> unregisterPushToken() async {
    await _methodClient.invoke<void>('unregisterPushToken');
  }

  @override
  Stream<LpEvent> events() {
    // Build once, then share.
    _events ??= _eventClient
        .receiveBroadcastStream()
        .map((dynamic raw) {
          if (kDebugMode) {
            LpLog.d('event/raw', raw.toString());
          }
          return _eventMapper.fromNative(raw);
        })
        // Filter out unknown event types (mapper returns null).
        .where((e) => e != null)
        .cast<LpEvent>()
        // Make sure multiple Dart listeners don't create multiple native subscriptions.
        .asBroadcastStream();

    return _events!;
  }
}

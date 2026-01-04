import Flutter
import UIKit

/**
 iOS plugin entrypoint.

 Responsibilities:
 - Handle MethodChannel commands from Dart
 - Provide EventChannel stream back to Dart

 This is a stub implementation:
 - It emits simple lifecycle events so you can validate Dart-side plumbing
 - Later, wire each method to the real LivePerson iOS SDK calls
 */
public class LpMessagingSdkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?
  private var initialized: Bool = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    // MUST match Dart ChannelNames.methodChannel
    let methodChannel = FlutterMethodChannel(
      name: "lp_messaging_sdk_flutter/methods",
      binaryMessenger: registrar.messenger()
    )

    // MUST match Dart ChannelNames.eventChannel
    let eventChannel = FlutterEventChannel(
      name: "lp_messaging_sdk_flutter/events",
      binaryMessenger: registrar.messenger()
    )

    let instance = LpMessagingSdkFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {

      case "initialize":
        // TODO: Wire to LivePerson iOS SDK init.
        initialized = true

        // Emit "connected" so the Dart event stream can be tested.
        emit([
          "platform": "ios",
          "payload": [
            "type": "connection",
            "timestamp": isoNow(),
            "state": "connected"
          ]
        ])
        result(nil)

      case "showConversation":
        guard ensureInit(result: result) else { return }
        // TODO: Present conversation UI.
        emit([
          "platform": "ios",
          "payload": [
            "type": "conversation",
            "timestamp": isoNow(),
            "state": "opened"
          ]
        ])
        result(nil)

      case "dismissConversation":
        guard ensureInit(result: result) else { return }
        // TODO: Dismiss conversation UI.
        emit([
          "platform": "ios",
          "payload": [
            "type": "conversation",
            "timestamp": isoNow(),
            "state": "closed"
          ]
        ])
        result(nil)

      case "logout":
        // TODO: clear session in LP SDK.
        initialized = false
        emit([
          "platform": "ios",
          "payload": [
            "type": "connection",
            "timestamp": isoNow(),
            "state": "disconnected"
          ]
        ])
        result(nil)

      case "setUserProfile":
        guard ensureInit(result: result) else { return }
        // TODO: Wire to LivePerson profile APIs.
        result(nil)

      case "registerPushToken":
        guard ensureInit(result: result) else { return }
        // TODO: Wire to LivePerson push registration APIs.
        result(nil)

      case "unregisterPushToken":
        guard ensureInit(result: result) else { return }
        // TODO: Wire to LivePerson push unregister APIs.
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      // Emit async error event AND fail the call.
      emit([
        "platform": "ios",
        "payload": [
          "type": "error",
          "timestamp": isoNow(),
          "code": "native_error",
          "message": "\(error)"
        ]
      ])
      result(FlutterError(code: "native_error", message: "\(error)", details: nil))
    }
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // Dart started listening: save sink so we can push events.
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Dart stopped listening.
    eventSink = nil
    return nil
  }

  // MARK: - Helpers

  private func ensureInit(result: @escaping FlutterResult) -> Bool {
    if !initialized {
      result(FlutterError(code: "not_initialized", message: "Call initialize() first.", details: nil))
      return false
    }
    return true
  }

  private func emit(_ payload: [String: Any]) {
    eventSink?(payload)
  }

  private func isoNow() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
  }
}

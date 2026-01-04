package com.example.lp_messaging_sdk_flutter

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Android plugin entrypoint.
 *
 * Responsibilities:
 * - Set up MethodChannel (commands from Dart -> native)
 * - Set up EventChannel (events from native -> Dart)
 * - Own lifecycle references (Context, Activity)
 *
 * Note: This file currently contains STUB behavior (fake events) so the Dart
 * side can be built and tested end-to-end before wiring the real LivePerson SDK.
 */
class LpMessagingSdkFlutterPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware {

  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel

  private var context: Context? = null
  private var activity: Activity? = null

  // Event sink we push events into when Dart subscribes.
  private var events: EventChannel.EventSink? = null

  // Simple guard to demonstrate "initialize first" contract.
  private var initialized: Boolean = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext

    // MUST match Dart ChannelNames.methodChannel
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "lp_messaging_sdk_flutter/methods")
    methodChannel.setMethodCallHandler(this)

    // MUST match Dart ChannelNames.eventChannel
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "lp_messaging_sdk_flutter/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    context = null
  }

  // ActivityAware (optional but useful if you need to show UI)
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // EventChannel.StreamHandler
  override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
    // Dart is now listening: save sink to emit events
    events = eventSink
  }

  override fun onCancel(arguments: Any?) {
    // Dart stopped listening
    events = null
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    try {
      when (call.method) {
        "initialize" -> {
          // TODO: Wire to real LivePerson init calls.
          initialized = true

          // Emit a "connected" event to show the pipeline works.
          emitEvent(
            mapOf(
              "platform" to "android",
              "payload" to mapOf(
                "type" to "connection",
                "timestamp" to isoNow(),
                "state" to "connected"
              )
            )
          )
          result.success(null)
        }

        "showConversation" -> {
          ensureInit(result) ?: run {
            // TODO: Show/launch the LivePerson conversation UI.
            // activity might be required for presentation.
            emitEvent(
              mapOf(
                "platform" to "android",
                "payload" to mapOf(
                  "type" to "conversation",
                  "timestamp" to isoNow(),
                  "state" to "opened"
                )
              )
            )
            result.success(null)
          }
        }

        "dismissConversation" -> {
          ensureInit(result) ?: run {
            // TODO: Dismiss/hide conversation UI.
            emitEvent(
              mapOf(
                "platform" to "android",
                "payload" to mapOf(
                  "type" to "conversation",
                  "timestamp" to isoNow(),
                  "state" to "closed"
                )
              )
            )
            result.success(null)
          }
        }

        "logout" -> {
          // TODO: clear SDK user/session.
          initialized = false

          emitEvent(
            mapOf(
              "platform" to "android",
              "payload" to mapOf(
                "type" to "connection",
                "timestamp" to isoNow(),
                "state" to "disconnected"
              )
            )
          )
          result.success(null)
        }

        "setUserProfile" -> {
          ensureInit(result) ?: run {
            // TODO: pass profile data to LivePerson SDK
            result.success(null)
          }
        }

        "registerPushToken" -> {
          ensureInit(result) ?: run {
            // TODO: register token in LivePerson SDK
            result.success(null)
          }
        }

        "unregisterPushToken" -> {
          ensureInit(result) ?: run {
            // TODO: unregister token in LivePerson SDK
            result.success(null)
          }
        }

        else -> result.notImplemented()
      }
    } catch (t: Throwable) {
      // Emit async error event AND fail the MethodChannel call.
      emitError(t)
      result.error("native_error", t.message, t.toString())
    }
  }

  /**
   * Enforces the contract: initialize() must be called first.
   *
   * Returns non-null sentinel if not initialized.
   */
  private fun ensureInit(result: MethodChannel.Result): Any? {
    if (!initialized) {
      result.error("not_initialized", "Call initialize() first.", null)
      return Any()
    }
    return null
  }

  private fun emitEvent(payload: Map<String, Any?>) {
    events?.success(payload)
  }

  private fun emitError(t: Throwable) {
    emitEvent(
      mapOf(
        "platform" to "android",
        "payload" to mapOf(
          "type" to "error",
          "timestamp" to isoNow(),
          "code" to "native_error",
          "message" to (t.message ?: "Unknown error"),
          "details" to t.toString()
        )
      )
    )
  }

  private fun isoNow(): String {
    val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    return sdf.format(Date())
  }
}

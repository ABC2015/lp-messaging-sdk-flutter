package com.liveperson.lp_messaging_sdk_flutter

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull

import com.liveperson.messaging.sdk.api.LivePerson
import com.liveperson.infra.InitLivePersonProperties
import com.liveperson.infra.MonitoringInitParams
import com.liveperson.infra.ConversationViewParams
import com.liveperson.infra.auth.LPAuthenticationParams
import com.liveperson.infra.auth.LPAuthenticationType
import com.liveperson.infra.callbacks.InitLivePersonCallBack
import com.liveperson.infra.ICallback
import com.liveperson.messaging.sdk.api.model.ConsumerProfile

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LpMessagingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    private var accountId: String? = null
    private var appId: String? = null
    private var initialized: Boolean = false
    private var debugLogging: Boolean = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "lp_messaging_sdk_flutter")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "lp_messaging_sdk_flutter/events")
        eventChannel.setStreamHandler(this)
        applicationContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        applicationContext = null
    }

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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid_args", "Missing arguments", null)
                } else {
                    handleInitialize(args, result)
                }
            }
            "showConversation" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                handleShowConversation(args, result)
            }
            "hideConversation" -> {
                handleHideConversation(result)
            }
            "setUserProfile" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid_args", "Missing arguments", null)
                } else {
                    handleSetUserProfile(args, result)
                }
            }
            "registerPushToken" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid_args", "Missing arguments", null)
                } else {
                    handleRegisterPush(args, result)
                }
            }
            "unregisterPushToken" -> {
                handleUnregisterPush(result)
            }
            "getUnreadCount" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                handleGetUnreadCount(args, result)
            }
            "setDebugLogging" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid_args", "Missing arguments", null)
                } else {
                    handleSetDebugLogging(args, result)
                }
            }
            "reset" -> {
                handleReset(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(args: Map<*, *>, result: Result) {
        val ctx = applicationContext
        if (ctx == null) {
            result.error("no_context", "Application context is null", null)
            return
        }

        accountId = args["accountId"] as? String
        appId = args["appId"] as? String
        val monitoringEnabled = args["monitoringEnabled"] as? Boolean ?: false
        val appInstallId = args["appInstallationId"] as? String
        debugLogging = args["debugLogging"] as? Boolean ?: false

        if (accountId.isNullOrEmpty() || appId.isNullOrEmpty()) {
            result.error("invalid_args", "accountId and appId are required", null)
            return
        }

        if (initialized) {
            result.success(null)
            return
        }

        val monitoringParams = if (monitoringEnabled) {
            val installId = if (!appInstallId.isNullOrEmpty()) {
                appInstallId
            } else {
                "appInstallationId"
            }
            MonitoringInitParams(installId)
        } else {
            null
        }

        val initProps = InitLivePersonProperties(
            accountId,
            appId,
            monitoringParams,
            object : InitLivePersonCallBack {
                override fun onInitSucceed() {
                    initialized = true
                    runOnMain {
                        sendEvent(
                            mapOf(
                                "type" to "initialized",
                                "platform" to "android"
                            )
                        )
                        result.success(null)
                    }
                }

                override fun onInitFailed(e: Exception) {
                    runOnMain {
                        result.error("init_failed", e.message, null)
                    }
                }
            }
        )

        runOnMain {
            LivePerson.initialize(ctx, initProps)
        }
    }

    private fun handleShowConversation(args: Map<*, *>, result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("no_activity", "No foreground Activity", null)
            return
        }

        if (!initialized) {
            result.error("not_initialized", "LivePerson SDK not initialized", null)
            return
        }

        val authMap = args["auth"] as? Map<*, *>
        val lpAuth = LPAuthenticationParams()

        applyAuthParams(authMap, lpAuth)

        val viewParams = ConversationViewParams(false)
        runOnMain {
            LivePerson.showConversation(activity, lpAuth, viewParams)
            sendEvent(
                mapOf(
                    "type" to "conversation_shown",
                    "platform" to "android"
                )
            )
            result.success(null)
        }
    }

    private fun handleHideConversation(result: Result) {
        val activity = activity
        if (activity == null) {
            result.error("no_activity", "No foreground Activity", null)
            return
        }
        runOnMain {
            LivePerson.hideConversation(activity)
            sendEvent(
                mapOf(
                    "type" to "conversation_hidden",
                    "platform" to "android"
                )
            )
            result.success(null)
        }
    }

    private fun handleSetUserProfile(args: Map<*, *>, result: Result) {
        val firstName = args["firstName"] as? String
        val lastName = args["lastName"] as? String
        val phone = args["phoneNumber"] as? String
        val builder = ConsumerProfile.Builder()
        if (!firstName.isNullOrEmpty()) builder.setFirstName(firstName)
        if (!lastName.isNullOrEmpty()) builder.setLastName(lastName)
        if (!phone.isNullOrEmpty()) builder.setPhoneNumber(phone)

        runOnMain {
            LivePerson.setUserProfile(builder.build())
            sendEvent(
                mapOf(
                    "type" to "profile_set",
                    "platform" to "android"
                )
            )
            result.success(null)
        }
    }

    private fun handleRegisterPush(args: Map<*, *>, result: Result) {
        if (accountId.isNullOrEmpty() || appId.isNullOrEmpty()) {
            result.error("not_initialized", "LivePerson SDK not initialized", null)
            return
        }

        val token = args["token"] as? String
        if (token.isNullOrEmpty()) {
            result.error("invalid_args", "token is required", null)
            return
        }

        val authMap = args["auth"] as? Map<*, *>
        val lpAuth = LPAuthenticationParams()
        applyAuthParams(authMap, lpAuth)

        runOnMain {
            LivePerson.registerLPPusher(
                accountId,
                appId,
                token,
                lpAuth,
                object : ICallback<Void, Exception> {
                    override fun onSuccess(data: Void?) {
                        runOnMain {
                            sendEvent(
                                mapOf(
                                    "type" to "push_registered",
                                    "platform" to "android"
                                )
                            )
                            result.success(null)
                        }
                    }

                    override fun onError(e: Exception) {
                        runOnMain {
                            result.error("push_register_failed", e.message, null)
                        }
                    }
                }
            )
        }
    }

    private fun handleUnregisterPush(result: Result) {
        if (accountId.isNullOrEmpty() || appId.isNullOrEmpty()) {
            result.error("not_initialized", "LivePerson SDK not initialized", null)
            return
        }

        runOnMain {
            LivePerson.unregisterLPPusher(
                accountId,
                appId,
                object : ICallback<Void, Exception> {
                    override fun onSuccess(data: Void?) {
                        runOnMain {
                            sendEvent(
                                mapOf(
                                    "type" to "push_unregistered",
                                    "platform" to "android"
                                )
                            )
                            result.success(null)
                        }
                    }

                    override fun onError(e: Exception) {
                        runOnMain {
                            result.error("push_unregister_failed", e.message, null)
                        }
                    }
                }
            )
        }
    }

    private fun handleGetUnreadCount(args: Map<*, *>, result: Result) {
        if (appId.isNullOrEmpty()) {
            result.error("not_initialized", "LivePerson SDK not initialized", null)
            return
        }

        val authMap = args["auth"] as? Map<*, *>
        if (authMap == null) {
            runOnMain {
                LivePerson.getUnreadMessagesCount(
                    appId,
                    object : ICallback<Int, Exception> {
                        override fun onSuccess(data: Int?) {
                            runOnMain { result.success(data ?: 0) }
                        }

                        override fun onError(e: Exception) {
                            runOnMain { result.error("unread_count_failed", e.message, null) }
                        }
                    }
                )
            }
            return
        }

        val lpAuth = LPAuthenticationParams()
        applyAuthParams(authMap, lpAuth)

        runOnMain {
            LivePerson.getUnreadMessagesCount(
                appId,
                lpAuth,
                object : ICallback<Int, Exception> {
                    override fun onSuccess(data: Int?) {
                        runOnMain { result.success(data ?: 0) }
                    }

                    override fun onError(e: Exception) {
                        runOnMain { result.error("unread_count_failed", e.message, null) }
                    }
                }
            )
        }
    }

    private fun handleSetDebugLogging(args: Map<*, *>, result: Result) {
        val enabled = args["enabled"] as? Boolean ?: false
        debugLogging = enabled
        runOnMain { result.success(null) }
    }

    private fun handleReset(result: Result) {
        val currentActivity = activity
        runOnMain {
            try {
                if (currentActivity != null) {
                    LivePerson.hideConversation(currentActivity)
                }
            } catch (_: Exception) {
                // Best effort; reset still proceeds.
            }
            initialized = false
            accountId = null
            appId = null
            debugLogging = false
            result.success(null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendEvent(event: Map<String, Any>) {
        val sink = eventSink ?: return
        if (debugLogging) {
            Log.d("LpMessagingPlugin", "sendEvent: $event")
        }
        runOnMain {
            sink.success(event)
        }
    }

    private fun applyAuthParams(authMap: Map<*, *>?, lpAuth: LPAuthenticationParams) {
        if (authMap == null) return
        val jwt = authMap["jwt"] as? String
        val authCode = authMap["authCode"] as? String
        val performStepUp = authMap["performStepUp"] as? Boolean ?: false
        val authType = authMap["authType"] as? String

        if (!jwt.isNullOrEmpty()) {
            lpAuth.setHostAppJWT(jwt)
        } else if (!authCode.isNullOrEmpty()) {
            lpAuth.setAuthKey(authCode)
        }

        if (!authType.isNullOrEmpty()) {
            val authTypeValue = resolveAuthType(authType)
            if (authTypeValue != null) {
                maybeSetAuthType(lpAuth, authTypeValue)
            }
        }

        lpAuth.setPerformStepUp(performStepUp)
    }

    private fun maybeSetAuthType(
        lpAuth: LPAuthenticationParams,
        authType: LPAuthenticationType,
    ) {
        try {
            val method = lpAuth.javaClass.getMethod(
                "setAuthenticationType",
                LPAuthenticationType::class.java,
            )
            method.invoke(lpAuth, authType)
        } catch (_: Exception) {
            // Method not available in this SDK version; ignore.
        }
    }

    private fun resolveAuthType(authType: String): LPAuthenticationType? {
        val normalized = authType.trim().lowercase()
        val values = LPAuthenticationType.values()
        return when (normalized) {
            "implicit" -> values.firstOrNull { it.name.contains("IMPLICIT") }
            "code" -> values.firstOrNull { it.name.contains("CODE") }
            else -> null
        }
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post { block() }
        }
    }
}

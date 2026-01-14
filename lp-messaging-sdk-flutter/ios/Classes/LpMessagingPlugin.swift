import Flutter
import UIKit
import LPMessagingSDK

public class LpMessagingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, LPMessagingSDKNotificationDelegate {

    private var accountId: String?
    private var initialized = false
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "lp_messaging_sdk_flutter",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "lp_messaging_sdk_flutter/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = LpMessagingPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_args", message: "Missing arguments", details: nil))
                return
            }
            handleInitialize(args: args, result: result)

        case "showConversation":
            let args = call.arguments as? [String: Any] ?? [:]
            handleShowConversation(args: args, result: result)

        case "hideConversation":
            handleHideConversation(result: result)

        case "setUserProfile":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_args", message: "Missing arguments", details: nil))
                return
            }
            handleSetUserProfile(args: args, result: result)

        case "registerPushToken":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_args", message: "Missing arguments", details: nil))
                return
            }
            handleRegisterPush(args: args, result: result)

        case "unregisterPushToken":
            handleUnregisterPush(result: result)

        case "getUnreadCount":
            let args = call.arguments as? [String: Any] ?? [:]
            handleGetUnreadCount(args: args, result: result)

        case "reset":
            handleReset(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(args: [String: Any], result: @escaping FlutterResult) {
        guard let accountId = args["accountId"] as? String else {
            result(FlutterError(code: "invalid_args", message: "accountId is required", details: nil))
            return
        }

        self.accountId = accountId

        do {
            try LPMessagingSDK.instance.initialize(accountId)
            initialized = true
            sendEvent(["type": "initialized", "platform": "ios"])
            result(nil)
        } catch let error {
            result(FlutterError(code: "init_failed", message: error.localizedDescription, details: nil))
        }
    }

    private func handleShowConversation(args: [String: Any], result: @escaping FlutterResult) {
        guard initialized, let accountId = self.accountId else {
            result(FlutterError(code: "not_initialized", message: "SDK not initialized", details: nil))
            return
        }

        guard let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else {
            result(FlutterError(code: "no_root_vc", message: "No root view controller", details: nil))
            return
        }

        let authParams = buildAuthParams(args["auth"] as? [String: Any])
        let convQuery =
            LPMessagingSDK.instance.getConversationBrandQuery(accountId, campaignInfo: nil)

        let viewParams = LPConversationViewParams(
            conversationQuery: convQuery,
            containerViewController: rootVC,
            isViewOnly: false
        )

        LPMessagingSDK.instance.showConversation(
            viewParams,
            authenticationParams: authParams
        )
        sendEvent(["type": "conversation_shown", "platform": "ios"])
        result(nil)
    }

    private func handleHideConversation(result: @escaping FlutterResult) {
        LPMessagingSDK.instance.removeConversation()
        sendEvent(["type": "conversation_hidden", "platform": "ios"])
        result(nil)
    }

    private func handleSetUserProfile(args: [String: Any], result: @escaping FlutterResult) {
        _ = args
        sendEvent(["type": "profile_set", "platform": "ios"])
        result(nil)
    }

    private func handleRegisterPush(args: [String: Any], result: @escaping FlutterResult) {
        guard initialized else {
            result(FlutterError(code: "not_initialized", message: "SDK not initialized", details: nil))
            return
        }
        guard let token = args["token"] as? String, !token.isEmpty else {
            result(FlutterError(code: "invalid_args", message: "token is required", details: nil))
            return
        }

        let authParams = buildAuthParams(args["auth"] as? [String: Any])
        LPMessagingSDK.instance.registerPushNotifications(
            tokenString: token,
            notificationDelegate: self,
            authenticationParams: authParams
        )
        sendEvent(["type": "push_registered", "platform": "ios"])
        result(nil)
    }

    private func handleUnregisterPush(result: @escaping FlutterResult) {
        guard let accountId = self.accountId else {
            result(FlutterError(code: "not_initialized", message: "SDK not initialized", details: nil))
            return
        }

        LPMessagingSDK.instance.unregisterPusher(
            brandId: accountId,
            unregisterType: .all,
            completion: {
                self.sendEvent(["type": "push_unregistered", "platform": "ios"])
                result(nil)
            },
            failure: { error in
                result(FlutterError(code: "push_unregister_failed", message: error.localizedDescription, details: nil))
            }
        )
    }

    private func handleGetUnreadCount(args: [String: Any], result: @escaping FlutterResult) {
        guard let accountId = self.accountId else {
            result(FlutterError(code: "not_initialized", message: "SDK not initialized", details: nil))
            return
        }

        let authParams = buildAuthParams(args["auth"] as? [String: Any])
        let convQuery = LPMessagingSDK.instance.getConversationBrandQuery(accountId, campaignInfo: nil)

        LPMessagingSDK.instance.getUnreadMessagesCount(
            convQuery,
            authenticationParams: authParams,
            completion: { count in
                result(count)
            },
            failure: { error in
                result(FlutterError(code: "unread_count_failed", message: error.localizedDescription, details: nil))
            }
        )
    }

    private func handleReset(result: @escaping FlutterResult) {
        LPMessagingSDK.instance.removeConversation()
        accountId = nil
        initialized = false
        result(nil)
    }

    private func buildAuthParams(_ authDict: [String: Any]?) -> LPAuthenticationParams? {
        guard let authDict = authDict else { return nil }
        let jwt = authDict["jwt"] as? String
        let authCode = authDict["authCode"] as? String
        let performStepUp = (authDict["performStepUp"] as? Bool) ?? false
        let authType = authDict["authType"] as? String

        let authTypeValue: LPAuthenticationType
        switch authType {
        case "implicit":
            authTypeValue = .implicit
        case "code":
            authTypeValue = .code
        default:
            authTypeValue = .authenticated
        }

        let authParams = LPAuthenticationParams(
            authenticationCode: authCode,
            jwt: jwt,
            redirectURI: nil,
            certPinningPublicKeys: nil,
            authenticationType: authTypeValue
        )
        authParams.performStepUp = performStepUp
        return authParams
    }

    private func sendEvent(_ payload: [String: Any]) {
        eventSink?(payload)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - LPMessagingSDKNotificationDelegate

    public func LPMessagingSDKNotification(didReceivePushNotification notification: LPNotification) {
        sendEvent(["type": "push_received", "platform": "ios"])
    }

    public func LPMessagingSDKPushRegistrationDidFinish() {
        sendEvent(["type": "push_registration_finished", "platform": "ios"])
    }

    public func LPMessagingSDKPushRegistrationDidFail(_ error: NSError) {
        sendEvent(["type": "push_registration_failed", "platform": "ios", "message": error.localizedDescription])
    }
}

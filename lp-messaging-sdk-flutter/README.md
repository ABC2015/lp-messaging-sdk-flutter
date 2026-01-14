# LivePerson Messaging SDK Flutter Wrapper

Flutter plugin that wraps the official LivePerson native SDKs for iOS and
Android. This package provides a small, Flutter-friendly API surface while
delegating all runtime behavior to the native SDKs.

## What this plugin does

- Initializes the LivePerson native SDKs.
- Shows and hides the native conversation UI.
- Sets a basic consumer profile (Android only; iOS is currently a no-op).
- Registers and unregisters push tokens.
- Retrieves unread message counts.
- Streams lightweight SDK events to Flutter (EventChannel).
- Optional debug logging to trace Android event emissions.
- Reset helper to clear plugin state between sessions.

## What this plugin does not do (yet)

- No Dart networking. All messaging behavior is handled by the native SDKs.
- Event stream currently only emits high-level lifecycle events (init/show/hide/push).

## Architecture

```
Flutter App
  |
  v
lp_messaging_sdk_flutter (MethodChannel)
  |                     |
  v                     v
Android: LivePerson SDK  iOS: LPMessagingSDK
```

## Requirements

- Flutter SDK >= 3.0.0 (latest stable recommended)
- Dart SDK >= 3.0.0 < 4.0.0 (latest stable recommended)
- Android minSdk 21
- iOS 13.0+

## Native SDK versions

This plugin is designed to track the latest LivePerson native SDKs. Update
the versions in the platform files as needed:

- Android: `lp-messaging-sdk-flutter/android/build.gradle`
- iOS: `lp-messaging-sdk-flutter/ios/lp_messaging_sdk_flutter.podspec`

Current defaults in this repo:

- Android: `com.liveperson.android:lp_messaging_sdk:5.26.0`
- iOS: `LPMessagingSDK` `6.25.0`

To bump native SDK versions:

- Android: edit the dependency line in
  `lp-messaging-sdk-flutter/android/build.gradle`:

  ```gradle
  implementation "com.liveperson.android:lp_messaging_sdk:<NEW_VERSION>"
  ```

- iOS: edit the Podspec in
  `lp-messaging-sdk-flutter/ios/lp_messaging_sdk_flutter.podspec`:

  ```ruby
  s.dependency 'LPMessagingSDK', '<NEW_VERSION>'
  ```

## Install

In your Flutter app:

```yaml
dependencies:
  lp_messaging_sdk_flutter:
    version: 0.0.1-experimental.2
```

Then:

```bash
flutter pub get
```

## Usage

### Initialize

```dart
import 'package:lp_messaging_sdk_flutter/lp_messaging_sdk_flutter.dart';

await LpMessaging.initialize(
  const LpNativeInitConfig(
    accountId: 'YOUR_ACCOUNT_ID',
    appId: 'com.yourcompany.yourapp', // Android package name
    appInstallationId: 'optional-install-id',
    monitoringEnabled: false,
    debugLogging: false,
  ),
);
```

### Set user profile (Android only)

```dart
await LpMessaging.setUserProfile(
  const LpUserProfile(
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    phoneNumber: '+15551234567',
  ),
);
```

### Show / hide conversation

```dart
await LpMessaging.showConversation(
  auth: const LpAuthConfig(
    authType: LpAuthType.implicit,
    jwt: 'YOUR_JWT', // for implicit flow
  ),
);

// Later
await LpMessaging.hideConversation();
```

### Auth types (implicit vs code)

If your LP account is configured for OAuth code flow, pass the auth code
instead of a JWT:

```dart
await LpMessaging.showConversation(
  auth: const LpAuthConfig(
    authType: LpAuthType.code,
    authCode: 'YOUR_AUTH_CODE',
  ),
);
```

### Push registration

```dart
await LpMessaging.registerPushToken(
  const LpPushConfig(
    token: 'DEVICE_TOKEN',
    auth: LpAuthConfig(
      authType: LpAuthType.implicit,
      jwt: 'YOUR_JWT',
    ),
  ),
);

await LpMessaging.unregisterPushToken();
```

### Unread count

```dart
final count = await LpMessaging.getUnreadCount(
  auth: const LpAuthConfig(
    authType: LpAuthType.implicit,
    jwt: 'YOUR_JWT',
  ),
);
```

### Events

```dart
LpMessaging.events.listen((event) {
  debugPrint('LP event: $event');
});
```

If you want a convenience logger:

```dart
LpMessaging.eventsWithLogging(tag: 'LP', pretty: true).listen((event) {
  // Handle event...
});
```

### Reset / debug logging

```dart
await LpMessaging.setDebugLogging(true);
await LpMessaging.reset();
```

## Example app

The example app is in `lp-messaging-sdk-flutter/example`.

1. Update `YOUR_ACCOUNT_ID` and `appId` in `example/lib/main.dart`.
2. Open Settings in the app to choose auth type (implicit or code) and supply
   the matching JWT/auth code.
3. From `lp-messaging-sdk-flutter/example`:

```bash
flutter pub get
flutter run
```

## Android setup notes

- The plugin already declares the LivePerson SDK dependency.
- Your host app is responsible for required permissions and manifest settings
  per LivePerson docs (e.g., internet access, push, etc.).
- The `appId` in `LpNativeInitConfig` should match your Android application ID.
- Auth type hints are best-effort on Android; older SDK versions may ignore
  explicit auth type values.

## iOS setup notes

- The Podspec pins `LPMessagingSDK` to `6.25.0`.
- Run `pod install` from the iOS runner if needed.
- The plugin uses `LPMessagingSDK.instance.initialize(accountId)` and
  `showConversation` with `LPConversationViewParams`.

## Testing

```bash
cd lp-messaging-sdk-flutter
flutter test
```

The example app has a lightweight widget test. Integration tests are skipped
until native credentials are wired.

## Troubleshooting

- If Android build fails with "Namespace not specified", ensure the plugin
  `android/build.gradle` includes `namespace "com.liveperson.lp_messaging_sdk_flutter"`.
- If Kotlin JVM target errors appear, ensure the plugin sets
  `kotlinOptions { jvmTarget = '1.8' }`.

## Roadmap

Planned additions:

- Richer EventChannel payloads for native SDK callbacks.
- Push handling helpers (payload parsing + routing).

## License

See `LICENSE`.

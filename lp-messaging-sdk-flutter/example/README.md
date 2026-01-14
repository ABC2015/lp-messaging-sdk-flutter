# lp_messaging_sdk_flutter Example

Example Flutter app that uses the `lp-messaging-sdk-flutter` plugin to
initialize LivePerson and open the native conversation UI.

Note: the plugin is marked experimental; APIs may change.

## Prerequisites

- Flutter SDK installed
- LivePerson account ID
- Android package name (app ID)
- iOS bundle ID

## Configure

Edit `lib/main.dart` and replace placeholders:

- `accountId`: your LivePerson account/brand ID
- `appId`: Android package name (e.g. `com.yourcompany.yourapp`)
- Optional JWT: use a real token from your backend for authenticated sessions

## Run

From this directory:

```bash
flutter pub get
flutter run
```

## What this example does

- Initializes the LivePerson SDK
- Optionally sets a user profile
- Opens the native conversation screen

## Notes

- Configure Android/iOS permissions and push capabilities per LivePerson docs.
- This example focuses on the core initialize + show conversation flow.

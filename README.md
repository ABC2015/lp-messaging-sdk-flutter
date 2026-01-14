# LivePerson Flutter and Dart Messaging SDKs

![Flutter Plugin: Experimental](https://img.shields.io/badge/Flutter%20Plugin-Experimental-orange?style=flat-square)

This repository contains two LivePerson SDKs that serve different needs:

- `lp-messaging-sdk-flutter`: Flutter plugin that wraps the official LivePerson
  iOS and Android Messaging SDKs.
- `lp-messaging-sdk-dart`: Pure Dart messaging engine that talks directly to
  LivePerson APIs (WebSocket + REST) for web, desktop, server, and custom use.

## Choose the right SDK

| SDK | Best for | Runs on | Notes |
| --- | --- | --- | --- |
| `lp-messaging-sdk-flutter` | Mobile apps that want native parity | iOS/Android | Uses LivePerson native UI + behavior |
| `lp-messaging-sdk-dart` | Cross-platform + custom workflows | Web/Desktop/Server/CLI | Pure Dart, no native dependencies |

## What you get

### Flutter plugin

Experimental: API and behavior may change before a stable release.

- Native LivePerson Messaging SDK integration on iOS and Android
- Flutter method channel bridge and Dart API facade
- Example app for initialization + conversation UI

### Dart engine

- Messaging Window API over WebSocket (connect/send/receive/typing/receipts)
- Messaging REST API (list conversations, fetch history, close)
- Routing + Agent APIs (accept, resolve, queue position, CSAT)
- Push registration API (device token registration)
- Structured content helpers (rich cards, quick replies)
- Offline queue persistence (in-memory or Hive)
- Mock backend for local tests and demos
- Optional AI helpers (summaries, suggestions, moderation)

## Repository layout

```
lp-messaging-sdk-flutter/   # Flutter plugin (native iOS/Android bridge)
lp-messaging-sdk-dart/      # Pure Dart engine (WebSocket + REST)
tools/                      # Repo tooling
```

=======
This repository contains two LivePerson SDKs that serve different needs:

- `lp-messaging-sdk-flutter`: Flutter plugin that wraps the official LivePerson
  iOS and Android Messaging SDKs.
- `lp-messaging-sdk-dart`: Pure Dart messaging engine that talks directly to
  LivePerson APIs (WebSocket + REST) for web, desktop, server, and custom use.

## Choose the right SDK

| SDK | Best for | Runs on | Notes |
| --- | --- | --- | --- |
| `lp-messaging-sdk-flutter` | Mobile apps that want native parity | iOS/Android | Uses LivePerson native UI + behavior |
| `lp-messaging-sdk-dart` | Cross-platform + custom workflows | Web/Desktop/Server/CLI | Pure Dart, no native dependencies |

## What you get

### Flutter plugin

Experimental: API and behavior may change before a stable release.

- Native LivePerson Messaging SDK integration on iOS and Android
- Flutter method channel bridge and Dart API facade
- Example app for initialization + conversation UI

### Dart engine

- Messaging Window API over WebSocket (connect/send/receive/typing/receipts)
- Messaging REST API (list conversations, fetch history, close)
- Routing + Agent APIs (accept, resolve, queue position, CSAT)
- Push registration API (device token registration)
- Structured content helpers (rich cards, quick replies)
- Offline queue persistence (in-memory or Hive)
- Mock backend for local tests and demos
- Optional AI helpers (summaries, suggestions, moderation)

## Repository layout

```
lp-messaging-sdk-flutter/   # Flutter plugin (native iOS/Android bridge)
lp-messaging-sdk-dart/      # Pure Dart engine (WebSocket + REST)
tools/                      # Repo tooling
```

>>>>>>> main
## Getting started

### Flutter plugin

- Docs: `lp-messaging-sdk-flutter/README.md`
- Example: `lp-messaging-sdk-flutter/example`

```dart
await LpMessaging.initialize(
  const LpNativeInitConfig(
    accountId: 'YOUR_ACCOUNT_ID',
    appId: 'com.yourcompany.yourapp',
  ),
);
await LpMessaging.showConversation();
```

### Dart engine

- Docs: `lp-messaging-sdk-dart/README.md`
- Example: `lp-messaging-sdk-dart/example`

```dart
final config = LpConfig(
  accountId: 'YOUR_ACCOUNT_ID',
  jwtProvider: () async => 'YOUR_JWT',
);
final client = LpMessagingClient(
  config: config,
  persistence: InMemoryPersistence(),
);
await client.init();
await client.connect();
await client.startConversation();
await client.sendText('Hello from Dart');
```

## Status

- Flutter plugin: experimental (API and behavior may change)
- Dart engine: active development for multi-platform and automation use-cases

## Contributing

See `CONTRIBUTING.md`.

## License

See `LICENSE`.

# LivePerson Messaging SDK for Dart

Pure Dart client for LivePerson Messaging APIs. This package is a Dart-first
engine (no platform code) that can be used in Flutter apps, Dart CLIs, or server
apps that need to talk to LivePerson messaging services directly.

## What this SDK does

- Messaging Window API (WebSocket): connect, send, receive, typing, delivery/read
- Messaging REST API: list conversations, fetch history, close conversations
- Routing API: transfer, queue position, CSAT, agent availability
- Push registration API: register device tokens
- File upload + structured content helpers
- Offline queue persistence (in-memory or Hive)

## Requirements

- Dart SDK: >=3.0.0 <4.0.0
- Network access to LivePerson domains
- A JWT generator on your backend (consumer or agent tokens)

## Install

```bash
dart pub add lp_messaging_sdk_dart
```

If you are using this from a local checkout:

```yaml
dependencies:
  lp_messaging_sdk_dart:
    path: ../lp-messaging-sdk-dart
```

Then:

```bash
dart pub get
```

## Concepts and flow

High-level flow:

1. Create a config with your account ID and a JWT provider.
2. Create a persistence store (in-memory or Hive).
3. Create `LpMessagingClient` and call `init()`.
4. `connect()` to open the WebSocket session.
5. `startConversation()` and `sendText()`.
6. Listen to `client.events` for messages, state, and errors.

## Quick start (consumer)

```dart
import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';

Future<void> main() async {
  final config = LpConfig(
    accountId: 'YOUR_ACCOUNT_ID',
    jwtProvider: () async {
      // Call your backend to get a LivePerson JWT.
      return 'YOUR_JWT';
    },
    channelType: LpChannelType.consumer,
    logLevel: LpLogLevel.info,
  );

  final persistence = InMemoryPersistence();
  final client = LpMessagingClient(
    config: config,
    persistence: persistence,
  );

  await client.init();

  client.events.listen((event) {
    if (event is LpConnectionStateChanged) {
      print('State: ${event.state}');
    } else if (event is LpConversationUpdated) {
      print('Conversation: ${event.conversation.id}');
    } else if (event is LpMessageReceived) {
      print('Message: ${event.message.text}');
    } else if (event is LpErrorEvent) {
      print('Error: ${event.error}');
    }
  });

  await client.connect();
  await client.startConversation();
  await client.sendText('Hello from Dart');
}
```

## JWT provider

The SDK expects a function that returns a valid LivePerson JWT. The provider
should call your backend and return a short-lived token.

```dart
final config = LpConfig(
  accountId: 'YOUR_ACCOUNT_ID',
  jwtProvider: () async {
    // fetch from your server
    return await fetchJwtFromServer();
  },
);
```

For tests or local demos only:

```dart
final config = LpConfig(
  accountId: 'YOUR_ACCOUNT_ID',
  jwtProvider: staticJwtProvider('YOUR_JWT'),
);
```

## Events

Listen to `client.events` and handle these event types:

- `LpConnectionStateChanged`
- `LpConversationUpdated`
- `LpMessageReceived`
- `LpMessageStateChanged`
- `LpTypingIndicator`
- `LpErrorEvent`

## Messaging REST API

Use `LpMessagingRestApi` for history and conversation management:

```dart
final rest = LpMessagingRestApi(config: config, logger: LpLogger());
final conversations = await rest.listConversations();
final messages = await rest.getMessages(conversations.first.id);
await rest.closeConversation(conversations.first.id);
```

## Routing API

```dart
final routing = LpRoutingApi(config: config, logger: LpLogger());
await routing.transferToSkill(conversationId: convId, skill: 'billing');
final position = await routing.getQueuePosition(convId);
await routing.submitCSAT(conversationId: convId, score: 5, verbatim: 'Great');
```

## File upload and structured content

```dart
final files = LpFileUploadApi(config: config, logger: LpLogger());
final result = await files.uploadFile(
  conversationId: convId,
  file: File('path/to/file.png'),
  mimeType: 'image/png',
);

final content = LpStructuredContent(
  type: 'vertical',
  elements: [
    LpTextElement(text: 'Welcome'),
    LpButtonElement(
      title: 'Open',
      actions: [LpClickAction.link(name: 'Open', uri: 'https://example.com')],
    ),
  ],
);

final session = LpSession(config: config);
await session.connect();
session.commands.sendRichContent(
  dialogId: convId,
  content: content,
);
```

The structured content models are helpers to build valid payloads for a
RichContentEvent. To send them, use `LpMessagingCommands` or your own message
frame builder.

## Push registration

```dart
final push = LpPushApi(config: config, logger: LpLogger());
await push.registerToken(
  consumerId: 'CONSUMER_ID',
  token: 'DEVICE_TOKEN',
  platform: 'APNS',
);
```

## Agent mode

```dart
final agentConfig = LpConfig(
  accountId: 'YOUR_ACCOUNT_ID',
  jwtProvider: staticJwtProvider('AGENT_JWT'),
  channelType: LpChannelType.agent,
);

final agentApi = LpAgentApi(config: agentConfig, logger: LpLogger());
await agentApi.accept(convId);
await agentApi.markAsRead(convId, sequenceId);
await agentApi.resolve(convId);
```

## Offline persistence

Use `InMemoryPersistence` by default or `HivePersistence` to survive restarts.

```dart
final persistence = HivePersistence('lp_pending_messages');
await persistence.init();
```

Note: For Flutter, you would normally call `Hive.initFlutter()` in app startup.
This SDK is Dart-only; Flutter apps should initialize Hive themselves.

## Keep-alive

`LpSession` starts a keep-alive service (GetClock) after connect. You can
override behavior by creating your own session and wiring `LpKeepAliveService`.

## Demos

- Consumer demo: `example/bin/simple_console_chat.dart`
- Agent demo: `bin/agent_console.dart`

Run:

```bash
dart example/bin/simple_console_chat.dart <ACCOUNT_ID> <JWT>
# or
dart bin/agent_console.dart <ACCOUNT_ID> <JWT>
```

## Testing

Run full tests from the package root:

```bash
dart test
```

## Notes and limitations

- WebSocket endpoints and payloads are based on LivePerson public docs. If LP
  changes schemas, update the mapping in `lib/src/api/messaging_window_api.dart`.
- This SDK does not include UI components.
- For Flutter plugin bridging to native SDKs, use `lp-messaging-sdk-flutter`.

## License

See `LICENSE`.

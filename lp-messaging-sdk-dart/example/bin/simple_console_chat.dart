import 'dart:convert';
import 'dart:io';

import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('=== LivePerson Simple Console Chat ===');

  if (args.length < 2) {
    stdout.writeln(
      'Usage: dart example/bin/simple_console_chat.dart <ACCOUNT_ID> <JWT>',
    );
    exit(1);
  }

  final accountId = args[0];
  final jwt = args[1];

  final config = LpConfig(
    accountId: accountId,
    jwtProvider: staticJwtProvider(jwt),
    channelType: LpChannelType.consumer,
    logLevel: LpLogLevel.info,
  );

  final persistence = InMemoryPersistence();
  final client = LpMessagingClient(
    config: config,
    persistence: persistence,
  );

  await client.init();

  final sub = client.events.listen((event) {
    if (event is LpConnectionStateChanged) {
      stdout.writeln('[STATE] ${event.state.name}');
    } else if (event is LpConversationUpdated) {
      stdout.writeln('[CONV] ${event.conversation.id}');
    } else if (event is LpMessageReceived) {
      final msg = event.message;
      stdout.writeln('[MSG][${msg.sender.role.name}] ${msg.text}');
    } else if (event is LpErrorEvent) {
      stdout.writeln('[ERROR] ${event.error}');
    }
  });

  stdout.writeln('Connecting as CONSUMER to account $accountId...');
  try {
    await client.connect();
    await client.startConversation();
  } catch (e) {
    stdout.writeln('Failed to connect: $e');
    await sub.cancel();
    exit(1);
  }

  stdout.writeln('Connected. Type messages or /quit.');

  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync(encoding: utf8);
    if (line == null) break;
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed == '/quit') break;

    try {
      await client.sendText(trimmed);
    } catch (e) {
      stdout.writeln('Send failed: $e');
    }
  }

  stdout.writeln('Shutting down...');
  await sub.cancel();
  await client.disconnect();
  stdout.writeln('Bye.');
}

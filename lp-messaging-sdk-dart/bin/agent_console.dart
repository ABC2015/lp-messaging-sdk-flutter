import 'dart:convert';
import 'dart:io';

import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('=== LivePerson Agent Console ===');

  if (args.length < 2) {
    stdout.writeln('Usage: dart bin/agent_console.dart <ACCOUNT_ID> <JWT>');
    exit(1);
  }

  final accountId = args[0];
  final jwt = args[1];

  final config = LpConfig(
    accountId: accountId,
    jwtProvider: staticJwtProvider(jwt),
    channelType: LpChannelType.agent,
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
      stdout.writeln('[STATE] ${event.state.name.toUpperCase()}');
    } else if (event is LpConversationUpdated) {
      stdout.writeln(
        '[CONV] ${event.conversation.id} state=${event.conversation.state}',
      );
    } else if (event is LpMessageReceived) {
      final msg = event.message;
      final who = msg.sender.role == LpChannelType.agent ? 'ME' : 'CONSUMER';
      stdout.writeln('[MSG][$who][${msg.conversationId}] ${msg.text}');
    } else if (event is LpErrorEvent) {
      stdout.writeln('[ERROR] ${event.error}');
    }
  });

  stdout.writeln('Connecting as AGENT to account $accountId...');
  try {
    await client.connect();
  } catch (e) {
    stdout.writeln('Failed to connect: $e');
    await sub.cancel();
    exit(1);
  }

  stdout.writeln('Connected. Type commands:');
  stdout.writeln('  /quit                - exit');
  stdout.writeln('  /conv <id>           - select conversation');
  stdout.writeln('  text                 - send message to selected conversation');

  String? currentConvId;

  // Simple stdin loop
  while (true) {
    stdout.write(currentConvId == null ? '> ' : '[$currentConvId] > ');
    final line = stdin.readLineSync(encoding: utf8);
    if (line == null) break;
    final trimmed = line.trim();

    if (trimmed == '/quit') {
      break;
    }

    if (trimmed.startsWith('/conv ')) {
      final id = trimmed.substring(6).trim();
      if (id.isEmpty) {
        stdout.writeln('Conversation ID cannot be empty.');
        continue;
      }
      currentConvId = id;
      stdout.writeln('Selected conversation: $currentConvId');
      continue;
    }

    if (currentConvId == null) {
      stdout.writeln(
        'No conversation selected. Use: /conv <id> (watch logs for IDs)',
      );
      continue;
    }

    // Send message
    try {
      stdout.writeln(
        'NOTE: LpMessagingClient currently assumes one conversation; '
        'for production, extend it to select conv by ID.',
      );
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lp_messaging_sdk_dart/lp_messaging_sdk_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ConsumerDemoApp());
}

class ConsumerDemoApp extends StatelessWidget {
  const ConsumerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LP Dart SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const ConsumerChatScreen(),
    );
  }
}

class ConsumerChatScreen extends StatefulWidget {
  const ConsumerChatScreen({super.key});

  @override
  State<ConsumerChatScreen> createState() => _ConsumerChatScreenState();
}

class _ConsumerChatScreenState extends State<ConsumerChatScreen> {
  String _accountId = 'YOUR_ACCOUNT_ID';
  String _jwt = '';

  LpMessagingClient? _client;
  StreamSubscription<LpEvent>? _sub;
  String _status = 'Idle';

  final List<LpMessage> _messages = <LpMessage>[];
  final TextEditingController _inputController = TextEditingController();
  final List<String> _eventLog = <String>[];

  LpConnectionState _connectionState = LpConnectionState.idle;
  LpConversation? _conversation;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (_client != null) {
      unawaited(_client!.disconnect());
    }
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('lp_account_id') ?? _accountId;
    final jwt = prefs.getString('lp_jwt') ?? _jwt;

    setState(() {
      _accountId = accountId;
      _jwt = jwt;
    });

    await _rebuildClient();
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lp_account_id', _accountId);
    await prefs.setString('lp_jwt', _jwt);
  }

  Future<void> _rebuildClient() async {
    _sub?.cancel();
    if (_client != null) {
      await _client!.disconnect();
    }

    if (mounted) {
      setState(() {
        _ready = false;
      });
    }

    final config = LpConfig(
      accountId: _accountId,
      jwtProvider: () async => _jwt,
      channelType: LpChannelType.consumer,
      logLevel: LpLogLevel.info,
    );

    final persistence = InMemoryPersistence();
    _client = LpMessagingClient(
      config: config,
      persistence: persistence,
    );

    await _client!.init();
    _sub = _client!.events.listen(_onEvent);

    if (mounted) {
      setState(() {
        _ready = true;
        _status = 'Client ready';
      });
    }
  }

  void _onEvent(LpEvent event) {
    if (!mounted) return;

    if (event is LpConnectionStateChanged) {
      setState(() {
        _connectionState = event.state;
        _status = 'Connection: ${_connectionLabel(event.state)}';
      });
      _logEvent('Connection -> ${_connectionLabel(event.state)}');
      return;
    }

    if (event is LpConversationUpdated) {
      setState(() {
        _conversation = event.conversation;
      });
      _logEvent('Conversation updated: ${event.conversation.id}');
      return;
    }

    if (event is LpMessageReceived) {
      setState(() {
        _messages.add(event.message);
      });
      _logEvent('Message received: ${event.message.id}');
      return;
    }

    if (event is LpMessageStateChanged) {
      final idx = _messages.indexWhere(
        (m) =>
            m.id == event.message.id &&
            m.conversationId == event.message.conversationId,
      );
      if (idx != -1) {
        setState(() {
          _messages[idx] =
              _messages[idx].copyWith(state: event.message.state);
        });
      }
      _logEvent('Message state: ${event.message.state.name}');
      return;
    }

    if (event is LpErrorEvent) {
      _logEvent('Error: ${event.error.code}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${event.error.message}')),
      );
    }
  }

  void _logEvent(String message) {
    _eventLog.insert(0, message);
    if (_eventLog.length > 20) {
      _eventLog.removeLast();
    }
  }

  Future<void> _connect() async {
    try {
      if (!_ready) {
        throw StateError('Client not ready yet.');
      }
      if (_accountId.trim().isEmpty) {
        throw StateError('Set account ID in Settings.');
      }
      if (_jwt.trim().isEmpty) {
        throw StateError('JWT is required to connect. Set it in Settings.');
      }
      setState(() {
        _status = 'Connecting...';
      });
      await _client!.connect();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect failed: $e')),
      );
      setState(() {
        _status = 'Connect failed: $e';
      });
    }
  }

  Future<void> _startConversation() async {
    try {
      final conv = await _client!.startConversation();
      setState(() {
        _conversation = conv;
        _messages.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start conversation failed: $e')),
      );
      setState(() {
        _status = 'Start conversation failed: $e';
      });
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    try {
      await _client!.sendText(text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
      setState(() {
        _status = 'Send failed: $e';
      });
    }
  }

  String _connectionLabel(LpConnectionState state) {
    switch (state) {
      case LpConnectionState.idle:
        return 'Idle';
      case LpConnectionState.connecting:
        return 'Connecting...';
      case LpConnectionState.connected:
        return 'Connected';
      case LpConnectionState.reconnecting:
        return 'Reconnecting...';
      case LpConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<_SettingsResult>(
      MaterialPageRoute<_SettingsResult>(
        builder: (context) => SettingsScreen(
          accountId: _accountId,
          jwt: _jwt,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _accountId = result.accountId;
      _jwt = result.jwt;
    });
    await _persistSettings();
    await _rebuildClient();
  }

  Future<void> _resetClient() async {
    _sub?.cancel();
    if (_client != null) {
      await _client!.disconnect();
    }
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _conversation = null;
      _status = 'Client reset';
      _eventLog.clear();
      _ready = false;
    });
    await _rebuildClient();
  }

  Future<void> _checkNetwork() async {
    setState(() {
      _status = 'Checking network...';
    });
    try {
      final lookups = await InternetAddress.lookup('api.liveperson.net')
          .timeout(const Duration(seconds: 5));
      final hasResult =
          lookups.isNotEmpty && lookups.first.rawAddress.isNotEmpty;
      if (!hasResult) {
        throw const SocketException('DNS lookup returned empty result.');
      }
      setState(() {
        _status = 'Network OK: api.liveperson.net reachable';
      });
    } catch (e) {
      setState(() {
        _status = 'Network check failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connectionState == LpConnectionState.connected;
    final hasConv = _conversation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LP Dart SDK Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                _connectionLabel(_connectionState),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status'),
                    const SizedBox(height: 4),
                    Text(
                      'Account: ${_accountId.isEmpty ? 'unset' : _accountId}',
                    ),
                    Text('JWT: ${_jwt.isEmpty ? 'missing' : 'set'}'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: connected || !_ready ? null : _connect,
                  child: const Text('Connect'),
                ),
                ElevatedButton(
                  onPressed: connected && _ready ? _startConversation : null,
                  child: const Text('Start Conversation'),
                ),
                OutlinedButton(
                  onPressed: _checkNetwork,
                  child: const Text('Check Network'),
                ),
                OutlinedButton(
                  onPressed: _resetClient,
                  child: const Text('Reset Client'),
                ),
              ],
            ),
          ),
          if (_eventLog.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ExpansionTile(
                title: const Text('Event Log'),
                children: _eventLog
                    .take(8)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (hasConv)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text(
                    'Conversation ID:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _conversation!.id,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.sender.role == LpChannelType.consumer;
                final alignment =
                    isMe ? Alignment.centerRight : Alignment.centerLeft;
                final color =
                    isMe ? Colors.blueGrey.shade100 : Colors.grey.shade200;

                String statusSuffix = '';
                if (msg.state == LpMessageState.sending) {
                  statusSuffix = ' (sending)';
                } else if (msg.state == LpMessageState.sent) {
                  statusSuffix = ' (sent)';
                } else if (msg.state == LpMessageState.delivered) {
                  statusSuffix = ' (delivered)';
                } else if (msg.state == LpMessageState.read) {
                  statusSuffix = ' (read)';
                } else if (msg.state == LpMessageState.failed) {
                  statusSuffix = ' (failed)';
                }

                return Align(
                  alignment: alignment,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${msg.text}$statusSuffix'),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: connected && hasConv ? _send : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.accountId,
    required this.jwt,
  });

  final String accountId;
  final String jwt;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _accountController;
  late final TextEditingController _jwtController;

  static const List<_Preset> _presets = [
    _Preset(name: 'Dev', accountId: 'DEV_ACCOUNT_ID'),
    _Preset(name: 'Stage', accountId: 'STAGE_ACCOUNT_ID'),
    _Preset(name: 'Prod', accountId: 'PROD_ACCOUNT_ID'),
  ];

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController(text: widget.accountId);
    _jwtController = TextEditingController(text: widget.jwt);
  }

  @override
  void dispose() {
    _accountController.dispose();
    _jwtController.dispose();
    super.dispose();
  }

  void _save() {
    final accountId = _accountController.text.trim();
    final jwt = _jwtController.text.trim();
    Navigator.of(context).pop(_SettingsResult(accountId: accountId, jwt: jwt));
  }

  void _clear() {
    Navigator.of(context).pop(const _SettingsResult(accountId: '', jwt: ''));
  }

  void _applyPreset(_Preset preset) {
    _accountController.text = preset.accountId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: 'Account ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Presets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (preset) => OutlinedButton(
                    onPressed: () => _applyPreset(preset),
                    child: Text(preset.name),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jwtController,
            decoration: const InputDecoration(
              labelText: 'JWT (required to connect)',
              border: OutlineInputBorder(),
              helperText: 'Use your backend to mint a LivePerson JWT.',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsResult {
  const _SettingsResult({
    required this.accountId,
    required this.jwt,
  });

  final String accountId;
  final String jwt;
}

class _Preset {
  const _Preset({
    required this.name,
    required this.accountId,
  });

  final String name;
  final String accountId;
}

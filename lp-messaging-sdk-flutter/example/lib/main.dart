import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lp_messaging_sdk_flutter/lp_messaging_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LpExampleApp());
}

class LpExampleApp extends StatefulWidget {
  const LpExampleApp({super.key});

  @override
  State<LpExampleApp> createState() => _LpExampleAppState();
}

class _LpExampleAppState extends State<LpExampleApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _initialized = false;
  String _status = 'Not initialized';
  static const String _defaultAccountId = 'YOUR_ACCOUNT_ID';
  static const String _defaultAppId = 'com.yourcompany.yourapp';
  String _accountId = _defaultAccountId;
  String _appId = _defaultAppId;
  String _jwt = '';
  String _authCode = '';
  String _pushToken = '';
  String _appInstallId = '';
  LpAuthType _authType = LpAuthType.implicit;
  final List<String> _events = <String>[];
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  bool _profileSent = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _eventSub = LpMessaging.events.listen((event) {
      setState(() {
        _events.insert(0, event.toString());
      });
      final type = event['type'];
      if (type == 'initialized') {
        _markInitialized();
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accountId = prefs.getString('lp_account_id') ?? _accountId;
      _appId = prefs.getString('lp_app_id') ?? _appId;
      _jwt = prefs.getString('lp_jwt') ?? _jwt;
      _authCode = prefs.getString('lp_auth_code') ?? _authCode;
      _pushToken = prefs.getString('lp_push_token') ?? _pushToken;
      _appInstallId = prefs.getString('lp_app_install_id') ?? _appInstallId;
      final authTypeRaw = prefs.getString('lp_auth_type');
      _authType = authTypeRaw == 'code' ? LpAuthType.code : LpAuthType.implicit;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lp_account_id', _accountId);
    await prefs.setString('lp_app_id', _appId);
    await prefs.setString('lp_jwt', _jwt);
    await prefs.setString('lp_auth_code', _authCode);
    await prefs.setString('lp_push_token', _pushToken);
    await prefs.setString('lp_app_install_id', _appInstallId);
    await prefs.setString('lp_auth_type', _authType.name);
  }

  Future<void> _openSettings() async {
    final navigator = _navKey.currentState;
    if (navigator == null) return;
    final result = await navigator.push<_SettingsResult>(
      MaterialPageRoute<_SettingsResult>(
        builder: (context) => SettingsScreen(
          accountId: _accountId,
          appId: _appId,
          jwt: _jwt,
          authCode: _authCode,
          pushToken: _pushToken,
          appInstallId: _appInstallId,
          authType: _authType,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _accountId = result.accountId;
      _appId = result.appId;
      _jwt = result.jwt;
      _authCode = result.authCode;
      _pushToken = result.pushToken;
      _appInstallId = result.appInstallId;
      _authType = result.authType;
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LP Messaging Plugin Example',
      navigatorKey: _navKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LP Messaging Plugin Example'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _initialized || !_hasValidInitInput()
                        ? null
                        : _initSdk,
                    child: const Text('Initialize SDK'),
                  ),
                  OutlinedButton(
                    onPressed: _checkLpTagConnectivity,
                    child: const Text('Check Network'),
                  ),
                  OutlinedButton(
                    onPressed: _resetSdk,
                    child: const Text('Reset SDK'),
                  ),
                  ElevatedButton(
                    onPressed: _initialized && _hasValidAuthInput()
                        ? _openConversation
                        : null,
                    child: const Text('Open Conversation'),
                  ),
                  ElevatedButton(
                    onPressed: _initialized ? _hideConversation : null,
                    child: const Text('Hide'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed:
                        _initialized && _hasValidAuthInput() ? _registerPush : null,
                    child: const Text('Register Push'),
                  ),
                  OutlinedButton(
                    onPressed: _initialized ? _unregisterPush : null,
                    child: const Text('Unregister Push'),
                  ),
                  OutlinedButton(
                    onPressed: _initialized && _hasValidAuthInput()
                        ? _getUnreadCount
                        : null,
                    child: const Text('Unread Count'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Events',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _events[index],
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initSdk() async {
    final reachable = await _checkLpTagConnectivity();
    if (!reachable) {
      return;
    }
    setState(() {
      _status = 'Initializing...';
    });

    try {
      await LpMessaging.initialize(
        LpNativeInitConfig(
          accountId: _accountId,
          appId: _appId,
          monitoringEnabled: _appInstallId.isNotEmpty,
          appInstallationId: _appInstallId.isEmpty ? null : _appInstallId,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Init failed: $e';
      });
    }
  }

  Future<bool> _checkLpTagConnectivity() async {
    setState(() {
      _status = 'Checking network...';
    });
    try {
      final lookups = await InternetAddress.lookup('lptag.liveperson.net')
          .timeout(const Duration(seconds: 5));
      final hasResult =
          lookups.isNotEmpty && lookups.first.rawAddress.isNotEmpty;
      if (!hasResult) {
        throw const SocketException('DNS lookup returned empty result.');
      }
      setState(() {
        _status = 'Network OK: lptag.liveperson.net reachable';
      });
      return true;
    } catch (e) {
      setState(() {
        _status = 'Network check failed: $e';
      });
      return false;
    }
  }

  Future<void> _markInitialized() async {
    if (!mounted) return;
    if (!_initialized) {
      setState(() {
        _initialized = true;
        _status = 'Initialized';
      });
    }
    if (_profileSent) return;
    _profileSent = true;
    try {
      await LpMessaging.setUserProfile(
        const LpUserProfile(
          firstName: 'Flutter',
          lastName: 'Agent',
          email: 'agent@example.com',
        ),
      );
    } catch (_) {
      // Ignore profile errors so init state remains usable.
    }
  }

  Future<void> _openConversation() async {
    setState(() {
      _status = 'Opening conversation...';
    });

    try {
      await LpMessaging.showConversation(
        auth: _buildAuthConfig(),
      );

      setState(() {
        _status = 'Conversation opened';
      });
    } catch (e) {
      setState(() {
        _status = 'Open failed: $e';
      });
    }
  }

  Future<void> _hideConversation() async {
    try {
      await LpMessaging.hideConversation();
      setState(() {
        _status = 'Conversation hidden';
      });
    } catch (e) {
      setState(() {
        _status = 'Hide failed: $e';
      });
    }
  }

  Future<void> _registerPush() async {
    try {
      await LpMessaging.registerPushToken(
        LpPushConfig(
          token: _pushToken,
          auth: _buildAuthConfig(),
        ),
      );
      setState(() {
        _status = 'Push registered';
      });
    } catch (e) {
      setState(() {
        _status = 'Push register failed: $e';
      });
    }
  }

  Future<void> _unregisterPush() async {
    try {
      await LpMessaging.unregisterPushToken();
      setState(() {
        _status = 'Push unregistered';
      });
    } catch (e) {
      setState(() {
        _status = 'Push unregister failed: $e';
      });
    }
  }

  Future<void> _getUnreadCount() async {
    try {
      final count = await LpMessaging.getUnreadCount(
        auth: _buildAuthConfig(),
      );
      setState(() {
        _status = 'Unread count: $count';
      });
    } catch (e) {
      setState(() {
        _status = 'Unread count failed: $e';
      });
    }
  }

  Future<void> _resetSdk() async {
    try {
      await LpMessaging.reset();
      setState(() {
        _initialized = false;
        _profileSent = false;
        _events.clear();
        _status = 'SDK reset';
      });
    } catch (e) {
      setState(() {
        _status = 'Reset failed: $e';
      });
    }
  }

  LpAuthConfig? _buildAuthConfig() {
    switch (_authType) {
      case LpAuthType.implicit:
        if (_jwt.isEmpty) return null;
        return LpAuthConfig(authType: _authType, jwt: _jwt);
      case LpAuthType.code:
        if (_authCode.isEmpty) return null;
        return LpAuthConfig(authType: _authType, authCode: _authCode);
    }
  }

  bool _hasValidInitInput() {
    final accountId = _accountId.trim();
    final appId = _appId.trim();
    return accountId.isNotEmpty &&
        appId.isNotEmpty &&
        accountId != _defaultAccountId &&
        appId != _defaultAppId;
  }

  bool _hasValidAuthInput() {
    switch (_authType) {
      case LpAuthType.implicit:
        return _jwt.isNotEmpty;
      case LpAuthType.code:
        return _authCode.isNotEmpty;
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.accountId,
    required this.appId,
    required this.jwt,
    required this.authCode,
    required this.pushToken,
    required this.appInstallId,
    required this.authType,
  });

  final String accountId;
  final String appId;
  final String jwt;
  final String authCode;
  final String pushToken;
  final String appInstallId;
  final LpAuthType authType;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _accountController;
  late final TextEditingController _appIdController;
  late final TextEditingController _jwtController;
  late final TextEditingController _authCodeController;
  late final TextEditingController _pushTokenController;
  late final TextEditingController _appInstallIdController;
  late LpAuthType _authType;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController(text: widget.accountId);
    _appIdController = TextEditingController(text: widget.appId);
    _jwtController = TextEditingController(text: widget.jwt);
    _authCodeController = TextEditingController(text: widget.authCode);
    _pushTokenController = TextEditingController(text: widget.pushToken);
    _appInstallIdController =
        TextEditingController(text: widget.appInstallId);
    _authType = widget.authType;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _appIdController.dispose();
    _jwtController.dispose();
    _authCodeController.dispose();
    _pushTokenController.dispose();
    _appInstallIdController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      _SettingsResult(
        accountId: _accountController.text.trim(),
        appId: _appIdController.text.trim(),
        jwt: _jwtController.text.trim(),
        authCode: _authCodeController.text.trim(),
        pushToken: _pushTokenController.text.trim(),
        appInstallId: _appInstallIdController.text.trim(),
        authType: _authType,
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(
      const _SettingsResult(
        accountId: '',
        appId: '',
        jwt: '',
        authCode: '',
        pushToken: '',
        appInstallId: '',
        authType: LpAuthType.implicit,
      ),
    );
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
          TextField(
            controller: _appIdController,
            decoration: const InputDecoration(
              labelText: 'App ID (Android applicationId)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Auth Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Implicit'),
                selected: _authType == LpAuthType.implicit,
                onSelected: (_) {
                  setState(() {
                    _authType = LpAuthType.implicit;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Code'),
                selected: _authType == LpAuthType.code,
                onSelected: (_) {
                  setState(() {
                    _authType = LpAuthType.code;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jwtController,
            enabled: _authType == LpAuthType.implicit,
            decoration: InputDecoration(
              labelText: 'JWT (implicit flow)',
              border: const OutlineInputBorder(),
              helperText: _authType == LpAuthType.implicit
                  ? 'Required for implicit flow.'
                  : 'Disabled for code flow.',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authCodeController,
            enabled: _authType == LpAuthType.code,
            decoration: InputDecoration(
              labelText: 'Auth Code (code flow)',
              border: const OutlineInputBorder(),
              helperText: _authType == LpAuthType.code
                  ? 'Required for code flow.'
                  : 'Disabled for implicit flow.',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pushTokenController,
            decoration: const InputDecoration(
              labelText: 'Push Token (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _appInstallIdController,
            decoration: const InputDecoration(
              labelText: 'App Install ID (Monitoring)',
              border: OutlineInputBorder(),
            ),
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
    required this.appId,
    required this.jwt,
    required this.authCode,
    required this.pushToken,
    required this.appInstallId,
    required this.authType,
  });

  final String accountId;
  final String appId;
  final String jwt;
  final String authCode;
  final String pushToken;
  final String appInstallId;
  final LpAuthType authType;
}

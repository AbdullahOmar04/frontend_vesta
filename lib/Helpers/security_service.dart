import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:freerasp/freerasp.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip in debug mode for development
    if (kDebugMode) {
      debugPrint('SecurityService: Skipped in debug mode');
      _isInitialized = true;
      return;
    }

    // Skip on iOS until Apple Team ID is configured
    if (Platform.isIOS) {
      _isInitialized = true;
      return;
    }

    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.example.vesta',
        signingCertHashes: [
          '3XFYFijXYtSFYbVN0NYjPJQYubOxkmQCqJu1SZ8lFOI='
        ],
        supportedStores: ['com.android.vending'],
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.example.frontendVesta'],
        teamId: 'YOUR_TEAM_ID',
      ),
      watcherMail: 'abdullah.omar@vestaapp.co',
      isProd: true,
    );

    final callback = ThreatCallback(
      onAppIntegrity: () => _blockApp('App integrity compromised'),
      onDebug: () => debugPrint('SecurityService: Debugger detected'),
      onHooks: () => _blockApp('Hooking framework detected'),
      onDeviceBinding: () => debugPrint('SecurityService: Device binding failed'),
      onSimulator: () => debugPrint('SecurityService: Emulator detected'),
      onUnofficialStore: () => debugPrint('SecurityService: Unofficial store'),
      onPrivilegedAccess: () => _blockApp('Rooted/jailbroken device'),
      onSecureHardwareNotAvailable: () => debugPrint('SecurityService: No secure hardware'),
      onSystemVPN: () => debugPrint('SecurityService: VPN detected'),
      onDevMode: () => debugPrint('SecurityService: Dev mode enabled'),
      onADBEnabled: () => debugPrint('SecurityService: ADB enabled'),
      onObfuscationIssues: () => debugPrint('SecurityService: Obfuscation issues'),
    );

    try {
      Talsec.instance.attachListener(callback);
      await Talsec.instance.start(config);
      _isInitialized = true;
      debugPrint('SecurityService: Initialized successfully');
    } catch (e) {
      debugPrint('SecurityService: Failed to initialize - $e');
    }
  }

  void _blockApp(String reason) {
    debugPrint('SecurityService: BLOCKING APP - $reason');
    SystemNavigator.pop();
  }
}

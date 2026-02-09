import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = canCheck;
        _biometricEnabled = isEnabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (value) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      await _biometricService.enableBiometricLogin(user.uid);
    } else {
      await _biometricService.disableBiometricLogin();
    }

    if (mounted) {
      setState(() => _biometricEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_biometricAvailable)
            SwitchListTile(
              title: const Text('Biometric Login'),
              subtitle: Text(
                _biometricEnabled
                    ? 'Use fingerprint or face to login'
                    : 'Enable quick login with biometrics',
              ),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
              secondary: const Icon(Icons.fingerprint),
            )
          else
            const ListTile(
              leading: Icon(Icons.fingerprint, color: Colors.grey),
              title: Text('Biometric Login'),
              subtitle: Text('Not available on this device'),
            ),
        ],
      ),
    );
  }
}

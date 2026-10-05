import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

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
            SnackBar(
              content: const Text('Biometric authentication failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: const VestaAppBar(title: 'Settings'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: VestaSpace.sm),
              child: Text(
                'Security',
                style: TextStyle(fontSize: 13, color: context.vesta.muted),
              ),
            ),
            VestaCard(
              padding: EdgeInsets.zero,
              radius: VestaRadius.lg,
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(VestaSpace.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _biometricAvailable
                  ? ToggleRow(
                      icon: PhosphorIconsRegular.fingerprint,
                      title: 'Biometric login',
                      subtitle: _biometricEnabled
                          ? 'Use fingerprint or face to log in'
                          : 'Enable quick login with biometrics',
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    )
                  : const ToggleRow(
                      icon: PhosphorIconsRegular.fingerprint,
                      title: 'Biometric login',
                      subtitle: 'Not available on this device',
                      value: false,
                      onChanged: null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

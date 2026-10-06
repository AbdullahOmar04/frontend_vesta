import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/secure_storage.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/login.dart';
import 'package:frontend_vesta/Screens/Onboarding/splash.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';

enum _GateState { checking, signedOut, locked, open }

/// The app's first screen. Firebase keeps the session between launches, so
/// a signed-in user goes straight to Home; when they turned on biometric
/// login, they unlock with it first. Everyone else sees Welcome.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _biometrics = BiometricService();
  _GateState _state = _GateState.checking;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _state = _GateState.signedOut);
      return;
    }

    var useBiometrics = false;
    try {
      useBiometrics =
          await _biometrics.isBiometricLoginEnabled() &&
          await _biometrics.canCheckBiometrics() &&
          await _biometrics.getLastUserId() == user.uid;
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }
    if (!mounted) return;

    if (useBiometrics) {
      setState(() => _state = _GateState.locked);
      _unlock();
    } else {
      _open();
    }
  }

  void _open() {
    // Same start-of-session work a password or biometric login does
    handleBudgetCycleOnLogin();
    setState(() => _state = _GateState.open);
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final ok = await _biometrics.authenticate(reason: 'Unlock Vesta');
    if (!mounted) return;
    setState(() => _unlocking = false);
    if (ok) _open();
  }

  /// Signs out the way Log out in Profile does, then shows Welcome, where
  /// they can log in as someone else or sign up.
  Future<void> _useAnotherAccount() async {
    await SecureStorage().deleteAll();
    await FirebaseAuth.instance.signOut();
    if (mounted) setState(() => _state = _GateState.signedOut);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GateState.checking => const Scaffold(body: VestaBackground(child: SizedBox.expand())),
      _GateState.signedOut => const OnboardingSplash(),
      _GateState.open => const MainScreen(),
      _GateState.locked => _lockScreen(),
    };
  }

  Widget _lockScreen() {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = FirebaseAuth.instance.currentUser?.displayName;

    return Scaffold(
      body: VestaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VestaSpace.xl),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  'assets/images/vesta_head.png',
                  height: 112,
                  color: dark ? scheme.onSurface : v.accentInk,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: VestaSpace.lg),
                Text(
                  name == null || name.isEmpty
                      ? 'Welcome back'
                      : 'Welcome back, $name',
                  textAlign: TextAlign.center,
                  style: headingStyle(24),
                ),
                const SizedBox(height: VestaSpace.sm),
                Text(
                  'Unlock to see your money.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: v.muted),
                ),
                const SizedBox(height: VestaSpace.xl),
                PrimaryButton(
                  label: 'Unlock',
                  loading: _unlocking,
                  onPressed: _unlock,
                ),
                const SizedBox(height: 10),
                OutlineButton(
                  label: 'Log in with password',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  ),
                ),
                const Spacer(flex: 4),
                Icon(PhosphorIconsRegular.fingerprint, color: v.muted),
                const SizedBox(height: VestaSpace.sm),
                TextButton(
                  onPressed: _unlocking ? null : _useAnotherAccount,
                  child: const Text(
                    'Not you? Use another account or sign up',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: VestaSpace.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

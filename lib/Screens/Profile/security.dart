import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// Password and security: change the password, fingerprint unlock, and the
/// pages the prototype has for later.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _biometrics = BiometricService();
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final available = await _biometrics.canCheckBiometrics();
    final enabled = await _biometrics.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (value) {
      final ok = await _biometrics.authenticate(
        reason: 'Authenticate to turn on fingerprint unlock',
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Couldn't confirm your fingerprint"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      await _biometrics.enableBiometricLogin(user.uid);
    } else {
      await _biometrics.disableBiometricLogin();
    }
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'Password and security'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            MenuCard([
              MenuRow(
                icon: PhosphorIconsRegular.password,
                title: 'Password',
                subtitle: 'Change or reset your password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PasswordPage()),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(VestaSpace.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ToggleRow(
                  icon: PhosphorIconsRegular.fingerprint,
                  title: 'Fingerprint unlock',
                  subtitle: !_available
                      ? 'Not available on this phone'
                      : _enabled
                      ? 'Unlock Vesta with your fingerprint or face'
                      : 'Unlock quickly instead of typing your password',
                  value: _available && _enabled,
                  onChanged: _available ? _toggleBiometrics : null,
                ),
              const MenuRow(
                icon: PhosphorIconsRegular.database,
                title: 'Data consent',
                subtitle: 'What we read from your bank accounts',
                tag: 'Coming soon',
              ),
              const MenuRow(
                icon: PhosphorIconsRegular.shieldCheck,
                title: 'Privacy policy',
                tag: 'Coming soon',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// The same rules as sign-up: 6 or more characters with an uppercase
/// letter, a lowercase letter, and a number.
String? passwordProblem(String password) {
  if (password.length < 6 ||
      !password.contains(RegExp(r'[A-Z]')) ||
      !password.contains(RegExp(r'[a-z]')) ||
      !password.contains(RegExp(r'[0-9]'))) {
    return 'Use 6 or more characters with an uppercase letter, a lowercase '
        'letter, and a number.';
  }
  return null;
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    final problem = _current.text.isEmpty
        ? 'Enter your current password.'
        : passwordProblem(_next.text) ??
              (_next.text != _confirm.text
                  ? "The new passwords don't match."
                  : _next.text == _current.text
                  ? 'Pick a password you are not using now.'
                  : null);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: _current.text),
      );
      await user.updatePassword(_next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _saving = false;
        _error = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? "Your current password isn't right."
            : e.code == 'weak-password'
            ? 'That password is too weak.'
            : e.code == 'too-many-requests'
            ? 'Too many tries. Wait a little, then try again.'
            : 'Something went wrong (${e.code}).';
      });
    }
  }

  Future<void> _forgot() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        SnackBar(content: Text('We sent a reset link to $email.')),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't send the link (${e.code}).")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: v.muted)),
    );
    Widget field(TextEditingController c) => TextField(
      controller: c,
      obscureText: true,
      onChanged: (_) => setState(() => _error = null),
    );

    return Scaffold(
      appBar: const VestaAppBar(title: 'Password'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            VestaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Change password', style: headingStyle(16)),
                  const SizedBox(height: VestaSpace.md),
                  label('Current password'),
                  field(_current),
                  const SizedBox(height: VestaSpace.md),
                  label('New password'),
                  field(_next),
                  const SizedBox(height: VestaSpace.md),
                  label('Confirm new password'),
                  field(_confirm),
                  const SizedBox(height: VestaSpace.sm),
                  Text(
                    'At least 6 characters, with an uppercase letter, a '
                    'lowercase letter, and a number.',
                    style: TextStyle(fontSize: 11, color: v.muted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: VestaSpace.sm),
                    Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
                  ],
                  const SizedBox(height: VestaSpace.lg),
                  PrimaryButton(
                    label: 'Update password',
                    loading: _saving,
                    onPressed: _update,
                  ),
                  const SizedBox(height: VestaSpace.sm),
                  Center(
                    child: TextButton(
                      onPressed: _forgot,
                      child: const Text('Forgot my password'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.md),
            VestaCard(
              padding: EdgeInsets.zero,
              child: ToggleRow(
                icon: PhosphorIconsRegular.shieldCheck,
                title: 'Two-factor authentication',
                subtitle: 'Coming soon: a code by SMS when you sign in',
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

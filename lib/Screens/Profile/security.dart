import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/links.dart';
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
        reason: context.l10n.fingerprintReason,
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.fingerprintFailed),
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
      appBar: VestaAppBar(title: context.l10n.profileSecurity),
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
                title: context.l10n.password,
                subtitle: context.l10n.changeOrResetPassword,
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
                  title: context.l10n.fingerprintUnlock,
                  subtitle: !_available
                      ? context.l10n.notAvailableOnPhone
                      : _enabled
                      ? context.l10n.unlockWithBiometrics
                      : context.l10n.unlockQuickly,
                  value: _available && _enabled,
                  onChanged: _available ? _toggleBiometrics : null,
                ),
              MenuRow(
                icon: PhosphorIconsRegular.database,
                title: context.l10n.dataConsent,
                subtitle: context.l10n.dataConsentSubtitle,
                tag: context.l10n.comingSoon,
              ),
              MenuRow(
                icon: PhosphorIconsRegular.shieldCheck,
                title: context.l10n.privacyPolicy,
                onTap: () => openWebPage(context, privacyPolicyUrl),
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
    return l10nNow.passwordRule;
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
        ? context.l10n.enterCurrentPassword
        : passwordProblem(_next.text) ??
              (_next.text != _confirm.text
                  ? context.l10n.newPasswordsDontMatch
                  : _next.text == _current.text
                  ? context.l10n.pickDifferentPassword
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.passwordUpdated)));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? context.l10n.currentPasswordWrong
            : e.code == 'weak-password'
            ? context.l10n.passwordTooWeak
            : e.code == 'too-many-requests'
            ? context.l10n.tooManyTries
            : context.l10n.somethingWentWrongCode(e.code);
      });
    }
  }

  Future<void> _forgot() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.resetLinkSent('\u2066$email\u2069')),
        ),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.linkSendFailed(e.code))),
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
      appBar: VestaAppBar(title: context.l10n.password),
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
                  Text(context.l10n.changePassword, style: headingStyle(16)),
                  const SizedBox(height: VestaSpace.md),
                  label(context.l10n.currentPassword),
                  field(_current),
                  const SizedBox(height: VestaSpace.md),
                  label(context.l10n.newPassword),
                  field(_next),
                  const SizedBox(height: VestaSpace.md),
                  label(context.l10n.confirmNewPassword),
                  field(_confirm),
                  const SizedBox(height: VestaSpace.sm),
                  Text(
                    context.l10n.passwordHint,
                    style: TextStyle(fontSize: 11, color: v.muted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: VestaSpace.sm),
                    Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
                  ],
                  const SizedBox(height: VestaSpace.lg),
                  PrimaryButton(
                    label: context.l10n.updatePassword,
                    loading: _saving,
                    onPressed: _update,
                  ),
                  const SizedBox(height: VestaSpace.sm),
                  Center(
                    child: TextButton(
                      onPressed: _forgot,
                      child: Text(context.l10n.forgotMyPassword),
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
                title: context.l10n.twoFactor,
                subtitle: context.l10n.twoFactorSoon,
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

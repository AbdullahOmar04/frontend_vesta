import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/referral_codes.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/onboarding_questions.dart';
import 'package:frontend_vesta/Screens/Onboarding/phone_number.dart';

class Register extends StatefulWidget {
  const Register({super.key, this.answers});

  /// Answers from the questions before sign-up, including the username.
  final OnboardingAnswers? answers;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();
  final _referral = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  /// Hidden when the questions already chose a username; shown again if
  /// that name was taken in the meantime.
  late bool _showUsername = widget.answers == null;

  // Password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_validatePassword);
    _username.text = widget.answers?.username ?? '';
    // Opened from a friend's vestaapp.co/r/<code> link
    _fillReferral();
    pendingReferralCode.addListener(_fillReferral);
  }

  void _fillReferral() {
    final code = pendingReferralCode.value;
    if (code != null && _referral.text.isEmpty) _referral.text = code;
  }

  @override
  void dispose() {
    pendingReferralCode.removeListener(_fillReferral);
    _password.removeListener(_validatePassword);
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    _referral.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _password.text;
    setState(() {
      _hasMinLength = password.length >= 6;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet
                ? PhosphorIconsRegular.checkCircle
                : PhosphorIconsRegular.circle,
            size: 15,
            color: isMet ? context.vesta.pos : context.vesta.muted,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? context.vesta.pos : context.vesta.muted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPhoneStep() async {
    final username = _username.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    final pass2 = _repeatPassword.text;

    if (username.isEmpty || email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.fillAllFields),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordsDontMatch),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate password requirements
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordRequirementsNotMet),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate username format (alphanumeric and underscore only)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.usernameRules),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterValidEmail),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final usernameDoc = await FirebaseFirestore.instance
          .collection("usernames")
          .doc(username.toLowerCase())
          .get();
      final usernameExists = usernameDoc.exists;

      if (usernameExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.usernameTaken),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _loading = false;
          _showUsername = true;
        });
        return;
      }

      final emailDoc = await FirebaseFirestore.instance
          .collection("emails")
          .doc(email.toLowerCase())
          .get();
      final emailExists = emailDoc.exists;

      if (emailExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.emailRegistered),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // An optional friend's code, checked now so a typo isn't found out
      // only after the phone step
      String? referral;
      if (_referral.text.trim().isNotEmpty) {
        referral = normalizeReferralCode(_referral.text);
        if (await referralCodeOwner(referral) == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.referralNotFound,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() => _loading = false);
          return;
        }
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PhoneNumberPage(
                username: username,
                email: email,
                password: pass,
                answers: widget.answers,
                referralCode: referral,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.checkUsernameError('$e')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;

    Widget eye(bool obscured, VoidCallback onTap) => IconButton(
      icon: Icon(
        obscured ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
        color: v.muted,
      ),
      onPressed: onTap,
    );

    return Scaffold(
      appBar: VestaAppBar(title: context.l10n.signUp),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.xl,
            VestaSpace.sm,
            VestaSpace.xl,
            VestaSpace.xl,
          ),
          children: [
            Text(context.l10n.createAccountTitle, style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              _showUsername
                  ? context.l10n.nextVerifyPhone : context.l10n.useTheseToLogIn(_username.text.trim()),
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            if (_showUsername) ...[
              TextField(
                controller: _username,
                decoration: InputDecoration(labelText: context.l10n.username),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: context.l10n.email),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                suffixIcon: eye(_obscurePassword, () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                }),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: VestaSpace.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: v.raised,
                borderRadius: BorderRadius.circular(VestaRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.passwordNeeds,
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
                  const SizedBox(height: VestaSpace.xs),
                  _buildPasswordRequirement(
                    context.l10n.pwMinLength,
                    _hasMinLength,
                  ),
                  _buildPasswordRequirement(
                    context.l10n.pwUppercase,
                    _hasUppercase,
                  ),
                  _buildPasswordRequirement(
                    context.l10n.pwLowercase,
                    _hasLowercase,
                  ),
                  _buildPasswordRequirement(
                    context.l10n.pwNumber,
                    _hasNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _repeatPassword,
              obscureText: _obscureRepeatPassword,
              decoration: InputDecoration(
                labelText: context.l10n.repeatPassword,
                suffixIcon: eye(_obscureRepeatPassword, () {
                  setState(() {
                    _obscureRepeatPassword = !_obscureRepeatPassword;
                  });
                }),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _referral,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: context.l10n.referralCode,
                hintText: context.l10n.referralHint,
              ),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: context.l10n.continueLabel,
              loading: _loading,
              onPressed: _goToPhoneStep,
            ),
          ],
        ),
      ),
    );
  }
}

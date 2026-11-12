import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/onboarding_questions.dart';
import 'package:frontend_vesta/Screens/Onboarding/otp.dart';

class PhoneNumberPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final OnboardingAnswers? answers;

  /// A friend's code entered at sign-up, already checked.
  final String? referralCode;

  const PhoneNumberPage({
    super.key,
    required this.username,
    required this.email,
    required this.password,
    this.answers,
    this.referralCode,
  });

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isBlockedError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('too-many-requests') ||
        errorString.contains('blocked') ||
        errorString.contains('unusual activity') ||
        errorString.contains('too many attempts');
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VestaDialog(
        title: context.l10n.blockedTitle,
        icon: PhosphorIconsRegular.warningCircle,
        iconColor: context.vesta.neg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.blockedVerifyBody,
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.blockedDuration,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              context.l10n.blockedRegain,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(context.l10n.blockedStep1),
            Text(context.l10n.blockedStep2),
            Text(context.l10n.blockedStep3Later),
          ],
        ),
        cancelLabel: null,
        confirmLabel: context.l10n.ok,
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _goToOtp() async {
    final local = _phoneController.text.trim();
    final valid = RegExp(r'^(7\d{8})$').hasMatch(local);

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.phoneInvalid,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final fullPhone = '+962$local'; 

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          if (_isBlockedError(e)) {
            _showBlockedDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? context.l10n.phoneVerifyFailed),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _loading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationPage(
                username: widget.username,
                email: widget.email,
                password: widget.password,
                phoneNumber: fullPhone,
                answers: widget.answers,
                referralCode: widget.referralCode,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _loading = false);
      if (_isBlockedError(e)) {
        _showBlockedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.phoneVerifyStartError('$e')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;

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
            Text(context.l10n.phoneTitle, style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              context.l10n.phoneSubtitle,
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              style: amountStyle(16),
              decoration: InputDecoration(
                labelText: context.l10n.phoneLabel,
                prefixText: '+962 ',
                hintText: '7XXXXXXX',
              ),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: context.l10n.sendCode,
              loading: _loading,
              onPressed: _goToOtp,
            ),
          ],
        ),
      ),
    );
  }
}

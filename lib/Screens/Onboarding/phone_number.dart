import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/otp.dart';

class PhoneNumberPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const PhoneNumberPage({
    super.key,
    required this.username,
    required this.email,
    required this.password,
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(PhosphorIconsRegular.warningCircle, color: context.vesta.neg),
            const SizedBox(width: 8),
            const Text('Phone Number Blocked'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your phone number has been temporarily blocked due to multiple verification attempts.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Text(
              'Block Duration: 30 minutes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'To regain access:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('1. Wait for the block period to expire (up to 30 minutes)'),
            Text('2. Ensure you have access to the phone number'),
            Text('3. Try again after the waiting period'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
            "Enter a valid Jordan number starting with 7 (e.g. 79xxxxxxx)",
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
                content: Text(e.message ?? "Phone verification failed"),
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
            content: Text("Error starting phone verification: $e"),
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
      appBar: const VestaAppBar(title: 'Sign up'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.xl,
            VestaSpace.sm,
            VestaSpace.xl,
            VestaSpace.xl,
          ),
          children: [
            Text('Your phone number', style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              "We'll send you a verification code to the provided number.",
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              style: amountStyle(16),
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixText: '+962 ',
                hintText: '7XXXXXXX',
              ),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: 'Send code',
              loading: _loading,
              onPressed: _goToOtp,
            ),
          ],
        ),
      ),
    );
  }
}

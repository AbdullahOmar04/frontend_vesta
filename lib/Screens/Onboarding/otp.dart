import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Onboarding/choose_bank.dart';

class OTPVerificationPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;

  final String verificationId;
  final int? resendToken;

  const OTPVerificationPage({
    super.key,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> initializeDefaultCategories(String uid) async {
    final categories = [
      {"label": "Food And Drinks", "total": 0.0, "type": "expense"},
      {"label": "Groceries", "total": 0.0, "type": "expense"},
      {"label": "Entertainment", "total": 0.0, "type": "expense"},
      {"label": "Others", "total": 0.0, "type": "expense"},
    ];

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    for (final cat in categories) {
      final label = cat['label'] as String;
      final catRef = userRef.collection('categories').doc(label);
      batch.set(catRef, {"total": cat['total'], "type": cat['type']});
    }

    await batch.commit();
  }

  Future<void> _finishSignup() async {
    final smsCode = _otpController.text.trim();

    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a 6-digit OTP"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final phoneCred = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final phoneUserCred = await FirebaseAuth.instance.signInWithCredential(
        phoneCred,
      );
      final phoneUser = phoneUserCred.user;
      if (phoneUser == null) {
        throw Exception('Phone verification failed');
      }

      final emailCred = EmailAuthProvider.credential(
        email: widget.email,
        password: widget.password,
      );

      await phoneUser.linkWithCredential(emailCred);

      // Optional: set display name
      await phoneUser.updateDisplayName(widget.username);

      final uid = phoneUser.uid;

      // 4) Create Firestore user doc
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "username": widget.username,
        "email": widget.email,
        "phoneNumber": widget.phoneNumber,
        "createdAt": FieldValue.serverTimestamp(),
        "currency": "JOD",
        "totalBalance": 0.0,
        "totalIncome": 0.0,
        "totalExpense": 0.0,
        "dayOfMonth": 28,
        "householdIds": [],
      });

      await initializeDefaultCategories(uid);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChooseBankSplash()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Verification failed"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: widget.resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? "Failed to resend OTP"),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          // Just update the verificationId used for next attempt
          setState(() {
            _loading = false;
            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            (widget as dynamic).verificationId = verificationId;
            (widget as dynamic).resendToken = resendToken;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP resent"),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error resending OTP: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        title: Text('Sign Up', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        backgroundColor: scheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Enter OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit OTP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const CircularProgressIndicator()
                        : largeButton(
                            context,
                            "Verify & Create Account",
                            scheme.secondary,
                            _finishSignup,
                          ),
                    const SizedBox(height: 16),
                    Text(
                      "We texted you a code to verify your phone number (+962) ${widget.phoneNumber.substring(4)}.",
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        text: "Didn't receive the code? ",
                        style: TextStyle(color: Colors.grey.shade700),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _loading ? null : _resendOtp,
                              child: Text(
                                "Resend OTP",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/onboarding_questions.dart';

const int otpValidityDurationSeconds = 120; // 2 minutes
const int resendCooldownSeconds = 60; // 60 seconds cooldown before resend

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

  // Store these in state so they can be updated on resend
  late String _currentVerificationId;
  int? _currentResendToken;

  Timer? _countdownTimer;
  int _remainingSeconds = otpValidityDurationSeconds;
  bool _otpExpired = false;

  Timer? _resendCooldownTimer;
  int _resendCooldownRemaining = resendCooldownSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentResendToken = widget.resendToken;
    _startCountdownTimer();
    _startResendCooldown();
  }

  void _startCountdownTimer() {
    _remainingSeconds = otpValidityDurationSeconds;
    _otpExpired = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _otpExpired = true;
        });
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    _resendCooldownRemaining = resendCooldownSeconds;
    _canResend = false;
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownRemaining > 0) {
        setState(() {
          _resendCooldownRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
              'Your phone number has been temporarily blocked due to multiple failed attempts.',
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
            Text('3. Try again with the correct OTP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isBlockedError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('too-many-requests') ||
        errorString.contains('blocked') ||
        errorString.contains('unusual activity') ||
        errorString.contains('too many attempts');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resendCooldownTimer?.cancel();
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

    if (_otpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP has expired. Please request a new code."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a 6-digit OTP"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final phoneCred = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
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

      // CRITICAL: Do a final uniqueness check before creating account
      // This must happen AFTER phone auth but BEFORE creating Firestore docs
      final usernameDocRef = FirebaseFirestore.instance
          .collection("usernames")
          .doc(widget.username.toLowerCase());

      final emailDocRef = FirebaseFirestore.instance
          .collection("emails")
          .doc(widget.email.toLowerCase());

      // Check if username already exists
      final usernameCheck = await usernameDocRef.get();
      if (usernameCheck.exists) {
        await phoneUser.delete();
        throw Exception("Username is already taken. Please try registering again with a different username.");
      }

      // Check if email already exists
      final emailCheck = await emailDocRef.get();
      if (emailCheck.exists) {
        await phoneUser.delete();
        throw Exception("Email is already registered. Please try logging in or use a different email.");
      }

      // Use batched writes to atomically create user doc, reserve username, and reserve email
      // This prevents race conditions and ensures uniqueness at database level
      final batch = FirebaseFirestore.instance.batch();

      // Reserve username in usernames collection
      batch.set(usernameDocRef, {
        "uid": uid,
        "originalUsername": widget.username,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Reserve email in emails collection
      batch.set(emailDocRef, {
        "uid": uid,
        "originalEmail": widget.email,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Create user document
      final userDocRef = FirebaseFirestore.instance.collection("users").doc(uid);
      batch.set(userDocRef, {
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

      try {
        // Commit all writes atomically
        await batch.commit();
      } catch (e) {
        // If batch fails, delete the Firebase Auth user and throw error
        await phoneUser.delete();

        // Check if it's a permission error (likely duplicate username/email)
        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('permission-denied')) {
          throw Exception("Username or email is already taken. Please try registering again with different credentials.");
        }

        throw Exception("Failed to create account: $e");
      }

      await initializeDefaultCategories(uid);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingQuestions(username: widget.username),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (_isBlockedError(e)) {
        _showBlockedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Verification failed"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (_isBlockedError(e)) {
        _showBlockedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || !_canResend) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _currentResendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          if (_isBlockedError(e)) {
            _showBlockedDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? "Failed to resend OTP"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // Update state with new verification credentials
          setState(() {
            _loading = false;
            _currentVerificationId = verificationId;
            _currentResendToken = resendToken;
          });
          // Clear the old OTP input
          _otpController.clear();
          // Reset timers for the new OTP
          _startCountdownTimer();
          _startResendCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("New OTP sent successfully"),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Update verification ID on timeout as well
          setState(() {
            _currentVerificationId = verificationId;
          });
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      if (_isBlockedError(e)) {
        _showBlockedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error resending OTP: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final urgent = _remainingSeconds <= 30;
    final small = TextStyle(fontSize: 13, color: v.muted);

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
            Text('Enter the code', style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              "We texted a code to (+962) ${widget.phoneNumber.substring(4)} to verify your number.",
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: _otpController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: amountStyle(24).copyWith(letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '••••••',
                counterText: '',
              ),
            ),
            const SizedBox(height: VestaSpace.md),
            if (_otpExpired)
              Text(
                "This code has expired. Request a new one below.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: v.neg),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsRegular.alarm,
                    size: 16,
                    color: urgent ? v.neg : v.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Code expires in ${_formatTime(_remainingSeconds)}",
                    style: small.copyWith(color: urgent ? v.neg : v.muted),
                  ),
                ],
              ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: 'Verify & create account',
              loading: _loading,
              onPressed: _finishSignup,
            ),
            const SizedBox(height: VestaSpace.md),
            if (_canResend)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't get it? ", style: small),
                  GestureDetector(
                    onTap: _loading ? null : _resendOtp,
                    child: Text(
                      "Resend code",
                      style: TextStyle(fontSize: 13, color: v.accentInk),
                    ),
                  ),
                ],
              )
            else
              Text(
                "You can resend the code in ${_resendCooldownRemaining}s",
                textAlign: TextAlign.center,
                style: small,
              ),
          ],
        ),
      ),
    );
  }
}

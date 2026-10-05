import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/register.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final BiometricService _biometricService = BiometricService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = canCheck;
        _biometricEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter your email address'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                        return;
                      }

                      // Validate email format
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid email address'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset email sent. Please check your inbox.',
                              ),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        debugPrint('Password reset Firebase error: ${e.code}');
                        // Show user-friendly message without exposing internal details
                        String message =
                            'Failed to send reset email. Please try again.';
                        if (e.code == 'too-many-requests') {
                          message =
                              'Too many attempts. Please try again later.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        debugPrint('Password reset error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'An error occurred. Please try again later.',
                            ),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      String identifier = identifierController.text.trim();
      String password = passwordController.text.trim();
      String email;

      // Check if identifier looks like an email
      if (identifier.contains("@")) {
        email = identifier;
      } else {
        // Lookup username → get email from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection("users")
            .where("username", isEqualTo: identifier)
            .get();

        if (snapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: "invalid-credentials",
            message: "Invalid username or password",
          );
        }

        // Security check: Detect duplicate usernames
        if (snapshot.docs.length > 1) {
          throw FirebaseAuthException(
            code: "duplicate-username",
            message:
                "Critical error: Multiple accounts with this username detected. Please contact support.",
          );
        }

        email = snapshot.docs.first["email"];
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enable biometric login if device supports it
      if (_biometricAvailable && userCredential.user != null) {
        await _biometricService.enableBiometricLogin(userCredential.user!.uid);
      }

      handleBudgetCycleOnLogin();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code}');
      // Use generic message to prevent account enumeration (V09)
      String message = 'Invalid username or password';
      if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your connection.';
      } else if (e.code == 'duplicate-username') {
        message = 'Account error. Please contact support.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login is not available or not enabled'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Get stored user ID and sign in
      final userId = await _biometricService.getLastUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No stored credentials. Please login with password first.'),
            ),
          );
        }
        return;
      }

      // Verify user still exists in Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        handleBudgetCycleOnLogin();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        // Try to restore session - user needs to login with password
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login with password.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: 'Log in'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.xl,
            VestaSpace.sm,
            VestaSpace.xl,
            VestaSpace.xl,
          ),
          children: [
            Text('Welcome back', style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              'Log in with your username or email.',
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: identifierController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Username or email',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
                    color: v.muted,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: VestaSpace.sm),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Log in',
                    loading: _loading,
                    onPressed: _login,
                  ),
                ),
                if (_biometricAvailable)
                  Padding(
                    padding: const EdgeInsets.only(left: VestaSpace.sm),
                    child: IconButton(
                      onPressed: _biometricEnabled && !_loading
                          ? _biometricLogin
                          : null,
                      icon: Icon(
                        PhosphorIconsRegular.fingerprint,
                        size: 26,
                        color: _biometricEnabled ? v.accentInk : v.muted,
                      ),
                      tooltip: _biometricEnabled
                          ? 'Log in with biometrics'
                          : 'Enable biometrics in settings after logging in',
                      style: IconButton.styleFrom(
                        fixedSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            VestaRadius.button,
                          ),
                          side: BorderSide(color: v.divider),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VestaSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Register(),
                      ),
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(fontSize: 13, color: v.accentInk),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

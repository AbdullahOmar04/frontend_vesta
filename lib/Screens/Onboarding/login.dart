import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/language.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/onboarding_questions.dart';
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
        builder: (context, setDialogState) => VestaDialog(
          title: context.l10n.resetPasswordTitle,
          message: context.l10n.resetPasswordMessage,
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.l10n.email,
              hintText: 'example@email.com',
            ),
          ),
          confirmLabel: context.l10n.sendResetLink,
          onConfirm: isLoading
              ? null
              : () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.enterEmail),
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
                        content: Text(context.l10n.enterValidEmail),
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
                        SnackBar(
                          content: Text(
                            context.l10n.resetEmailSent,
                          ),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    setDialogState(() => isLoading = false);
                    debugPrint('Password reset Firebase error: ${e.code}');
                    // Show user-friendly message without exposing internal details
                    String message =
                        context.l10n.resetEmailFailed;
                    if (e.code == 'too-many-requests') {
                      message =
                          context.l10n.tooManyAttempts;
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
                          context.l10n.genericErrorLater,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
          loading: isLoading,
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
        // Username → email through the public usernames doc. User docs are
        // private, so they can't be searched before signing in.
        final lookup = await FirebaseFirestore.instance
            .collection("usernames")
            .doc(identifier.toLowerCase())
            .get();
        final storedEmail = lookup.data()?["email"];
        if (storedEmail is! String || storedEmail.isEmpty) {
          throw FirebaseAuthException(
            code: "invalid-credentials",
            message: "Invalid username or password",
          );
        }
        email = storedEmail;
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
        // Clear Welcome and Login so back doesn't return to them
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code}');
      // Use generic message to prevent account enumeration (V09)
      String message = context.l10n.invalidLogin;
      if (e.code == 'too-many-requests') {
        message = context.l10n.tooManyAttempts;
      } else if (e.code == 'network-request-failed') {
        message = context.l10n.networkError;
      } else if (e.code == 'duplicate-username') {
        message = context.l10n.accountError;
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
        SnackBar(
          content: Text(context.l10n.biometricUnavailable),
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
              content: Text(context.l10n.biometricFailed),
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
            SnackBar(
              content: Text(context.l10n.noStoredCredentials),
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (_) => false,
          );
        }
      } else {
        // Try to restore session - user needs to login with password
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.sessionExpired),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.genericErrorAgain),
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
      appBar: VestaAppBar(title: context.l10n.logIn),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.xl,
            VestaSpace.sm,
            VestaSpace.xl,
            VestaSpace.xl,
          ),
          children: [
            Text(context.l10n.welcomeBack, style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              context.l10n.loginSubtitle,
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: identifierController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.usernameOrEmail,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: context.l10n.password,
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
                child: Text(context.l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: VestaSpace.sm),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: context.l10n.logIn,
                    loading: _loading,
                    onPressed: _login,
                  ),
                ),
                if (_biometricAvailable)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: VestaSpace.sm),
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
                          ? context.l10n.logInWithBiometrics : context.l10n.enableBiometricsLater,
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
                  context.l10n.noAccount,
                  style: TextStyle(fontSize: 13, color: v.muted),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingQuestions(),
                      ),
                    );
                  },
                  child: Text(
                    context.l10n.signUp,
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

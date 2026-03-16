import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/biometric_service.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
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
          title: const Text('Reset Password'),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                          const SnackBar(
                            content: Text('Please enter your email address'),
                            backgroundColor: Colors.red,
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
                          const SnackBar(
                            content: Text('Please enter a valid email address'),
                            backgroundColor: Colors.red,
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
                              backgroundColor: Colors.green,
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
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        debugPrint('Password reset error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'An error occurred. Please try again later.',
                            ),
                            backgroundColor: Colors.red,
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
                  : const Text('Send Reset Link'),
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
          backgroundColor: Colors.orange,
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
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Colors.red,
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
              backgroundColor: Colors.orange,
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
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 26),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Login with your username or email',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                    ),
                    SizedBox(
                      height: 160,
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: 400,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/Dark.png',
                          width: 400,
                          height: 400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: identifierController,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const CircularProgressIndicator()
                        : Row(
                            children: [
                              Expanded(
                                child: largeButton(
                                  context,
                                  "Login",
                                  Theme.of(context).colorScheme.secondary,
                                  _login,
                                ),
                              ),
                              if (_biometricAvailable)
                                IconButton(
                                  onPressed: _biometricEnabled ? _biometricLogin : null,
                                  icon: Icon(
                                    Icons.fingerprint,
                                    color: _biometricEnabled
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    size: 32,
                                  ),
                                  tooltip: _biometricEnabled
                                      ? 'Login with biometrics'
                                      : 'Enable biometrics in settings after login',
                                ),
                            ],
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
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
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

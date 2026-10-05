import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/phone_number.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  // Password validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _password.removeListener(_validatePassword);
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
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
          content: Text("Please fill all fields"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate password requirements
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please ensure your password meets all requirements"),
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
          content: Text("Username can only contain letters, numbers, and underscores"),
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
          content: Text("Please enter a valid email address"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Try to check username in new usernames collection first
      // If that fails (collection doesn't exist yet), fall back to users collection
      bool usernameExists = false;
      bool emailExists = false;

      try {
        final usernameDoc = await FirebaseFirestore.instance
            .collection("usernames")
            .doc(username.toLowerCase())
            .get();
        usernameExists = usernameDoc.exists;
      } catch (e) {
        // Fallback: Check in users collection if usernames collection doesn't exist
        final usernameQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("username", isEqualTo: username)
            .limit(1)
            .get();
        usernameExists = usernameQuery.docs.isNotEmpty;
      }

      if (usernameExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Username already taken. Please choose another one."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      try {
        final emailDoc = await FirebaseFirestore.instance
            .collection("emails")
            .doc(email.toLowerCase())
            .get();
        emailExists = emailDoc.exists;
      } catch (e) {
        // Fallback: Check in users collection if emails collection doesn't exist
        final emailQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: email)
            .limit(1)
            .get();
        emailExists = emailQuery.docs.isNotEmpty;
      }

      if (emailExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Email already registered. Please use another email or login."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PhoneNumberPage(username: username, email: email, password: pass),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error checking username/email: $e"),
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
            Text('Create your account', style: headingStyle(24)),
            const SizedBox(height: VestaSpace.xs),
            Text(
              'Next we will verify your phone number.',
              style: TextStyle(fontSize: 14, color: v.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
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
                    'Password needs',
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
                  const SizedBox(height: VestaSpace.xs),
                  _buildPasswordRequirement(
                    'At least 6 characters',
                    _hasMinLength,
                  ),
                  _buildPasswordRequirement(
                    'At least one uppercase letter (A-Z)',
                    _hasUppercase,
                  ),
                  _buildPasswordRequirement(
                    'At least one lowercase letter (a-z)',
                    _hasLowercase,
                  ),
                  _buildPasswordRequirement(
                    'At least one number (0-9)',
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
                labelText: 'Repeat password',
                suffixIcon: eye(_obscureRepeatPassword, () {
                  setState(() {
                    _obscureRepeatPassword = !_obscureRepeatPassword;
                  });
                }),
              ),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: 'Continue',
              loading: _loading,
              onPressed: _goToPhoneStep,
            ),
          ],
        ),
      ),
    );
  }
}

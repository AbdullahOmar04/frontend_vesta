import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChooseBank extends StatefulWidget {
  const ChooseBank({super.key});

  @override
  State<ChooseBank> createState() => _ChooseBankState();
}

class _ChooseBankState extends State<ChooseBank> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Choose Your Bank',
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  BankCard(
                    context,
                    'Bank of JoPACC LTD.',
                    'assets/images/jopacc.png',
                    Colors.white,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Jopacc()),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  BankCard(
                    context,
                    'Ahli Bank',
                    'assets/images/ahli.jpeg',
                    Colors.white,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AhliLinkScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  BankCard(
                    context,
                    'Capital Bank',
                    'assets/images/cboj.png',
                    Colors.white,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CapitalLinkScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: largeButton(
                context,
                'Not Right Now',
                Theme.of(context).colorScheme.primary,
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChooseBankSplash extends StatelessWidget {
  const ChooseBankSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Image.asset(
              'assets/images/choose_bank.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            Text(
              'Link Your Bank Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 50),
            Text(
              'Securely connect your bank account to manage your finances all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: largeButton(
                context,
                'Continue',
                Theme.of(context).colorScheme.secondary,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChooseBank()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Jopacc extends StatelessWidget {
  const Jopacc({super.key});

  @override
  Widget build(BuildContext context) => const JopaccLinkScreen();
}

class JopaccLinkScreen extends StatefulWidget {
  const JopaccLinkScreen({super.key});

  @override
  State<JopaccLinkScreen> createState() => _JopaccLinkScreenState();
}

class _JopaccLinkScreenState extends State<JopaccLinkScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loggedIn = false;
  bool _syncing = false;
  String? _lastUsername;
  final Set<String> _selected = {};
  bool _consentGiven = false;

  @override
  void initState() {
    super.initState();
    _loadStoredUsername();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Only pre-fill the username field, do NOT auto-login
  /// User must always go through login -> consent -> account selection flow
  Future<void> _loadStoredUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final stored = doc.data()?['providers']?['jopacc']?['username'];
    if (stored is String && stored.trim().isNotEmpty && mounted) {
      setState(() {
        _username.text = stored;
      });
    }
  }

  String _fmt(num amount, String currency) {
    final f = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return f.format(amount);
  }

  Future<void> _mockLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final entered = _username.text.trim();

    // Check if user already has linked accounts from a DIFFERENT username
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final existingUsername = userDoc
        .data()?['providers']?['jopacc']?['username'];

    // Check for existing linked accounts
    final linkedAccountsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .where('linked', isEqualTo: true)
        .limit(1)
        .get();

    final hasLinkedAccounts = linkedAccountsSnap.docs.isNotEmpty;
    final isDifferentUsername =
        existingUsername != null &&
        existingUsername.toString().trim().isNotEmpty &&
        existingUsername != entered;

    if (hasLinkedAccounts && isDifferentUsername) {
      if (!mounted) return;
      await _showDifferentUsernameWarning(existingUsername);
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'providers': {
        'jopacc': {
          'username': entered,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));

    setState(() {
      _loggedIn = true;
      _consentGiven = false;
      _lastUsername = entered;
      _selected.clear();
    });
  }

  Future<void> _showDifferentUsernameWarning(String existingUsername) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Different Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have linked accounts from "$existingUsername".',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'To link accounts from a different JoPACC user, please unlink your existing accounts first.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Go to My Accounts and hold on an account card to unlink it.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentScreen() {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share your data with Vesta?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'By continuing, you allow Vesta to securely access:',
                ),
                const SizedBox(height: 8),
                const Text('• Your account list and balances'),
                const Text('• Your transactions history'),
                const Text('• Standing orders & scheduled payments'),
                const SizedBox(height: 12),
                const Text(
                  'Access is read-only and you can stop sharing at any time from your bank.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _loggedIn = false;
                            _consentGiven = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('No, cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.surface,
                        ),
                        onPressed: _onConsentApproved,
                        child: const Text('Allow & continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onConsentApproved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _syncing = true;
    });

    try {
      await syncAccounts(_lastUsername ?? '');
      await _pollAccountsOnce();

      if (!mounted) return;
      setState(() {
        _consentGiven = true;
      });
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _pollAccountsOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (int i = 0; i < 6; i++) {
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) break;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _resync() async {
    setState(() => _syncing = true);
    try {
      await syncAccounts(''); // will read stored username
      await _pollAccountsOnce();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _linkSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selected.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final col = userRef.collection('accounts');

    for (final id in _selected) {
      batch.set(col.doc(id), {
        'linked': true,
        'linkedAt': FieldValue.serverTimestamp(),
        if (_lastUsername != null) 'linkedByUsername': _lastUsername,
        'provider': 'JoPACC',
      }, SetOptions(merge: true));
    }

    // Also store linked account IDs on user document for persistence
    batch.set(userRef, {
      'linkedAccountIds': FieldValue.arrayUnion(_selected.toList()),
    }, SetOptions(merge: true));

    await batch.commit();
    await calcTotalBalance();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Accounts linked')));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        title: Text(
          'Bank of JoPACC LTD.',
          style: TextStyle(color: scheme.surface),
        ),
        iconTheme: IconThemeData(color: scheme.surface),
        actions: [
          if (_loggedIn)
            IconButton(
              onPressed: _syncing ? null : _resync,
              icon: Icon(Icons.sync, color: scheme.surface),
              tooltip: 'Re-sync',
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: !_loggedIn
            ? _buildLoginForm() // STEP 1: bank login
            : (!_consentGiven
                  ? _buildConsentScreen() // STEP 2: consent
                  : _buildAccountSelection()), // STEP 3: accounts in Vesta
      ),

      floatingActionButton: (_loggedIn && _consentGiven)
          ? FloatingActionButton.extended(
              onPressed: _selected.isEmpty ? null : _linkSelected,
              backgroundColor: _selected.isEmpty ? Colors.grey : scheme.primary,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Link Selected',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildLoginForm() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login to JoPACC',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a username'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  largeButton(context, 'Login', scheme.secondary, () {
                    _mockLogin();
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final scheme = Theme.of(context).colorScheme;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_syncing) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.account_balance),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Select accounts to link',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (_) => false,
                );
              },
              child: Text('Skip', style: TextStyle(color: scheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('accounts')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text('No accounts available'));
              }

              final docs = snap.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final id = doc.id;
                  final acc = doc.data() as Map<String, dynamic>? ?? {};
                  final linked = (acc['linked'] ?? false) == true;

                  final bankName =
                      (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
                      ? acc["bankName"].toString()
                      : "Unknown Bank";
                  final accountType =
                      acc["accountTypeName"]?.toString() ?? "Unknown Type";
                  num balance = 0;
                  final dynamic balRaw = acc["balanceAmount"];
                  if (balRaw is num) {
                    balance = balRaw;
                  } else if (balRaw is String) {
                    balance = num.tryParse(balRaw) ?? 0;
                  }
                  final currency =
                      acc["currency"]?.toString().trim().isNotEmpty == true
                      ? acc["currency"].toString()
                      : "JOD";
                  final iban = acc["iban"]?.toString().trim().isNotEmpty == true
                      ? acc["iban"].toString()
                      : "No IBAN available";

                  final checked = _selected.contains(id) || linked;

                  return InkWell(
                    onTap: linked
                        ? null
                        : () {
                            setState(() {
                              if (checked) {
                                _selected.remove(id);
                              } else {
                                _selected.add(id);
                              }
                            });
                          },
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: linked
                                  ? null
                                  : (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(id);
                                        } else {
                                          _selected.remove(id);
                                        }
                                      });
                                    },
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.green;
                                  }
                                  return Colors.white;
                                },
                              ),
                              checkColor: Colors.black,
                            ),

                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bankName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _fmt(balance, currency),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    accountType,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "IBAN: $iban",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (linked) ...[
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Linked',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


// ─── Capital Bank (CBOJ) ───

class CapitalLinkScreen extends StatefulWidget {
  const CapitalLinkScreen({super.key});

  @override
  State<CapitalLinkScreen> createState() => _CapitalLinkScreenState();
}

class _CapitalLinkScreenState extends State<CapitalLinkScreen> {
  bool _loading = true;
  bool _oauthComplete = false;
  bool _syncing = false;
  String? _error;
  String? _authUrl;
  WebViewController? _webViewController;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _startLink();
  }

  String _fmt(num amount, String currency) {
    final f = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return f.format(amount);
  }

  Future<void> _startLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      return;
    }

    final result = await startCapitalLink();
    if (result == null || result['authUrl'] == null) {
      setState(() {
        _error = 'Failed to start Capital Bank link. Please try again.';
        _loading = false;
      });
      return;
    }

    final authUrl = result['authUrl'] as String;
    final backendHost = Uri.parse(baseUrl).host;

    late final WebViewController controller;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage msg) {
          print("JS: ${msg.message}");
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.navigate;

            final isCallback =
                uri.host == backendHost &&
                uri.path == '/banks/capital/callback';

            if (isCallback) {
              _handleCallback(req.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {
            try {
              await controller.runJavaScript("""
            (function() {
              try {
                Print.postMessage("href=" + window.location.href);
                Print.postMessage("title=" + document.title);
                Print.postMessage("text=" + document.body.innerText.slice(0, 400));
              } catch(e) {
                Print.postMessage("js_error=" + e.toString());
              }
            })();
          """);
            } catch (e) {
              print("onPageFinished error: $e");
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() => _error = 'WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    setState(() {
      _authUrl = authUrl;
      _webViewController = controller;
      _loading = false;
    });
  }

  Future<void> _handleCallback(String callbackUrl) async {
    if (_oauthComplete) return;
    setState(() {
      _oauthComplete = true;
      _syncing = true;
    });

    try {
      final resp = await http.get(Uri.parse(callbackUrl));
      print("Capital callback response: ${resp.statusCode}");

      if (resp.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = 'Capital Bank link failed. Please try again.';
            _syncing = false;
          });
        }
        return;
      }

      await _pollCapitalAccounts();
    } catch (e) {
      print("Error during Capital callback: $e");
      if (mounted) {
        setState(() {
          _error = 'Error linking Capital Bank: $e';
          _syncing = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _syncing = false);
    }
  }

  Future<void> _pollCapitalAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    for (int i = 0; i < 20; i++) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userSnap.data() ?? {};
      final providers = (data['providers'] as Map?) ?? {};
      final capital = (providers['capital'] as Map?) ?? {};
      final tokens = (capital['tokens'] as Map?) ?? {};
      final hasToken =
          (tokens['access_token']?.toString().trim().isNotEmpty ?? false);

      if (hasToken) {
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('accounts')
            .where('provider', isEqualTo: 'Capital')
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) return;
      }

      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('provider', isEqualTo: 'Capital')
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) return;

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _resync() async {
    setState(() => _syncing = true);
    try {
      await syncCapitalAccounts();
      await _pollCapitalAccounts();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _linkSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selected.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final col = userRef.collection('accounts');

    for (final id in _selected) {
      batch.set(col.doc(id), {
        'linked': true,
        'linkedAt': FieldValue.serverTimestamp(),
        'provider': 'Capital',
      }, SetOptions(merge: true));
    }

    batch.set(userRef, {
      'linkedAccountIds': FieldValue.arrayUnion(_selected.toList()),
    }, SetOptions(merge: true));

    await batch.commit();
    await calcTotalBalance();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Capital Bank accounts linked')));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        title: Text('Capital Bank', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        actions: [
          if (_oauthComplete)
            IconButton(
              onPressed: _syncing ? null : _resync,
              icon: Icon(Icons.sync, color: scheme.surface),
              tooltip: 'Re-sync',
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _buildBody(),
      ),
      floatingActionButton: _oauthComplete
          ? FloatingActionButton.extended(
              onPressed: _selected.isEmpty ? null : _linkSelected,
              backgroundColor: _selected.isEmpty ? Colors.grey : scheme.primary,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Link Selected',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _startLink();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_oauthComplete) {
      return _buildAccountSelection();
    }

    if (_webViewController != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: WebViewWidget(controller: _webViewController!),
      );
    }

    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final scheme = Theme.of(context).colorScheme;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_syncing) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_balance),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Select accounts to link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false,
                  );
                },
                child: Text('Skip', style: TextStyle(color: scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('accounts')
                  .where('provider', isEqualTo: 'Capital')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No accounts available'));
                }

                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final id = doc.id;
                    final acc = doc.data() as Map<String, dynamic>? ?? {};
                    final linked = (acc['linked'] ?? false) == true;

                    final bankName =
                        (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
                        ? acc["bankName"].toString()
                        : "Capital Bank";
                    final accountType =
                        acc["accountTypeName"]?.toString() ?? "Account";

                    num balance = 0;
                    final dynamic balRaw = acc["balanceAmount"];
                    if (balRaw is num) {
                      balance = balRaw;
                    } else if (balRaw is String) {
                      balance = num.tryParse(balRaw) ?? 0;
                    }
                    final currency =
                        acc["currency"]?.toString().trim().isNotEmpty == true
                        ? acc["currency"].toString()
                        : "JOD";
                    final iban =
                        acc["iban"]?.toString().trim().isNotEmpty == true
                        ? acc["iban"].toString()
                        : "No IBAN available";

                    final checked = _selected.contains(id) || linked;

                    return InkWell(
                      onTap: linked
                          ? null
                          : () {
                              setState(() {
                                if (checked) {
                                  _selected.remove(id);
                                } else {
                                  _selected.add(id);
                                }
                              });
                            },
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: linked
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selected.add(id);
                                          } else {
                                            _selected.remove(id);
                                          }
                                        });
                                      },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.disabled,
                                      )) {
                                        return Colors.green;
                                      }
                                      return Colors.white;
                                    }),
                                checkColor: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bankName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _fmt(balance, currency),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      accountType,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "IBAN: $iban",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (linked) ...[
                                      const SizedBox(height: 6),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Linked',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ahli Bank (Comply / finX) ───

class AhliLinkScreen extends StatefulWidget {
  const AhliLinkScreen({super.key});

  @override
  State<AhliLinkScreen> createState() => _AhliLinkScreenState();
}

class _AhliLinkScreenState extends State<AhliLinkScreen> {
  bool _loading = true;
  bool _oauthComplete = false;
  bool _syncing = false;
  String? _error;
  String? _authUrl;
  WebViewController? _webViewController;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _startLink();
  }

  String _fmt(num amount, String currency) {
    final f = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return f.format(amount);
  }

  Future<void> _startLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      return;
    }

    final result = await startAhliLink();
    if (result == null || result['authUrl'] == null) {
      setState(() {
        _error = 'Failed to start Ahli link. Please try again.';
        _loading = false;
      });
      return;
    }

    final authUrl = result['authUrl'] as String;

    final backendHost = Uri.parse(baseUrl).host; 

    late final WebViewController controller;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage msg) {
          print("JS: ${msg.message}");
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.navigate;

            print("WebView nav: ${req.url}");

            // Detect ANY callback to our backend (success or error)
            final isCallback =
                uri.host == backendHost &&
                uri.path == '/banks/ahli/callback';

            if (isCallback) {
              // Prevent WebView from navigating — we'll call the
              // backend ourselves so the code exchange happens
              // without showing the HTML response page.
              _handleCallback(req.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },

          // ✅ ADD THIS HERE
          onPageFinished: (url) async {
            print("WebView finished: $url");

            try {
              final title = await controller.getTitle();
              print("WebView title: $title");

              await controller.runJavaScript("""
            (function() {
              try {
                Print.postMessage("href=" + window.location.href);
                Print.postMessage("title=" + document.title);
                Print.postMessage("text=" + document.body.innerText.slice(0, 400));
              } catch(e) {
                Print.postMessage("js_error=" + e.toString());
              }
            })();
          """);
            } catch (e) {
              print("onPageFinished error: $e");
            }
          },

          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() => _error = 'WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    setState(() {
      _authUrl = authUrl;
      _webViewController = controller;
      _loading = false;
    });
  }

  Future<void> _handleCallback(String callbackUrl) async {
    if (_oauthComplete) return;
    setState(() {
      _oauthComplete = true;
      _syncing = true;
    });

    try {
      // Call the backend callback ourselves so it can exchange the
      // authorization code for tokens and sync accounts.
      final resp = await http.get(Uri.parse(callbackUrl));
      print("Callback response: ${resp.statusCode}");

      if (resp.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = 'Ahli link failed. Please try again.';
            _syncing = false;
          });
        }
        return;
      }

      // Backend processed the code — now poll for synced accounts
      await _pollAhliAccounts();
    } catch (e) {
      print("Error during callback: $e");
      if (mounted) {
        setState(() {
          _error = 'Error linking Ahli: $e';
          _syncing = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _syncing = false);
    }
  }

  Future<void> _pollAhliAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    for (int i = 0; i < 20; i++) {
      // 1) Check if Ahli tokens exist (link succeeded)
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userSnap.data() ?? {};
      final providers = (data['providers'] as Map?) ?? {};
      final ahli = (providers['ahli'] as Map?) ?? {};
      final tokens = (ahli['tokens'] as Map?) ?? {};
      final hasToken =
          (tokens['access_token']?.toString().trim().isNotEmpty ?? false);

      if (hasToken) {
        // Now wait for accounts to appear (usually quick)
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('accounts')
            .where('provider', isEqualTo: 'Ahli')
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) return;
      }

      // 2) Fallback: accounts check
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('provider', isEqualTo: 'Ahli')
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) return;

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _resync() async {
    setState(() => _syncing = true);
    try {
      await syncAhliAccounts();
      await _pollAhliAccounts();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _linkSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selected.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final col = userRef.collection('accounts');

    for (final id in _selected) {
      batch.set(col.doc(id), {
        'linked': true,
        'linkedAt': FieldValue.serverTimestamp(),
        'provider': 'Ahli',
      }, SetOptions(merge: true));
    }

    batch.set(userRef, {
      'linkedAccountIds': FieldValue.arrayUnion(_selected.toList()),
    }, SetOptions(merge: true));

    await batch.commit();
    await calcTotalBalance();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ahli accounts linked')));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        title: Text('Ahli Bank', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        actions: [
          if (_oauthComplete)
            IconButton(
              onPressed: _syncing ? null : _resync,
              icon: Icon(Icons.sync, color: scheme.surface),
              tooltip: 'Re-sync',
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _buildBody(),
      ),
      floatingActionButton: _oauthComplete
          ? FloatingActionButton.extended(
              onPressed: _selected.isEmpty ? null : _linkSelected,
              backgroundColor: _selected.isEmpty ? Colors.grey : scheme.primary,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Link Selected',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _startLink();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_oauthComplete) {
      return _buildAccountSelection();
    }

    // Show WebView for OAuth
    if (_webViewController != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: WebViewWidget(controller: _webViewController!),
      );
    }

    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final scheme = Theme.of(context).colorScheme;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_syncing) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_balance),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Select accounts to link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false,
                  );
                },
                child: Text('Skip', style: TextStyle(color: scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('accounts')
                  .where('provider', isEqualTo: 'Ahli')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No accounts available'));
                }

                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final id = doc.id;
                    final acc = doc.data() as Map<String, dynamic>? ?? {};
                    final linked = (acc['linked'] ?? false) == true;

                    final bankName =
                        (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
                        ? acc["bankName"].toString()
                        : "Ahli Bank";
                    final accountType =
                        acc["accountTypeName"]?.toString() ?? "Account";

                    num balance = 0;
                    final dynamic balRaw = acc["balanceAmount"];
                    if (balRaw is num) {
                      balance = balRaw;
                    } else if (balRaw is String) {
                      balance = num.tryParse(balRaw) ?? 0;
                    }
                    final currency =
                        acc["currency"]?.toString().trim().isNotEmpty == true
                        ? acc["currency"].toString()
                        : "JOD";
                    final iban =
                        acc["iban"]?.toString().trim().isNotEmpty == true
                        ? acc["iban"].toString()
                        : "No IBAN available";

                    final checked = _selected.contains(id) || linked;

                    return InkWell(
                      onTap: linked
                          ? null
                          : () {
                              setState(() {
                                if (checked) {
                                  _selected.remove(id);
                                } else {
                                  _selected.add(id);
                                }
                              });
                            },
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: linked
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selected.add(id);
                                          } else {
                                            _selected.remove(id);
                                          }
                                        });
                                      },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      Set<WidgetState> states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.disabled,
                                      )) {
                                        return Colors.green;
                                      }
                                      return Colors.white;
                                    }),
                                checkColor: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bankName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _fmt(balance, currency),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      accountType,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "IBAN: $iban",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (linked) ...[
                                      const SizedBox(height: 6),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Linked',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
                  const SizedBox(height: 4),
                  BankCard(
                    context,
                    'Bank Al Etihad',
                    'assets/images/etihad.jpg',
                    Colors.white,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EtihadLinkScreen(),
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
  bool _loading = false;
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

    setState(() => _loading = true);
    try {

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

    if (!mounted) return;
    setState(() {
      _loggedIn = true;
      _consentGiven = false;
      _lastUsername = entered;
      _selected.clear();
    });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () async { await _mockLogin(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
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
    if (!mounted) return;
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

    if (!mounted) return;
    setState(() {
      _authUrl = authUrl;
      _webViewController = controller;
      _loading = false;
    });
  }

  Future<void> _handleCallback(String callbackUrl) async {
    if (_oauthComplete) return;
    if (!mounted) return;
    setState(() {
      _oauthComplete = true;
      _syncing = true;
    });

    try {
      // Race: backend callback (slow — does token exchange + account sync)
      // vs Firestore poll (fast — returns as soon as accounts appear).
      // Whichever finishes first unblocks the UI.
      await Future.any([
        http.get(Uri.parse(callbackUrl)).then((resp) {
          print("Capital callback response: ${resp.statusCode}");
          if (resp.statusCode != 200) {
            throw Exception('Capital Bank link failed (${resp.statusCode})');
          }
        }),
        _pollCapitalAccounts(),
      ]);
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
                if (snap.connectionState == ConnectionState.waiting || (_syncing && (!snap.hasData || snap.data!.docs.isEmpty))) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Retrieving your accounts...'),
                      ],
                    ),
                  );
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

// ─── Etihad Bank (Bank Al Etihad) ───

class EtihadLinkScreen extends StatefulWidget {
  const EtihadLinkScreen({super.key});

  @override
  State<EtihadLinkScreen> createState() => _EtihadLinkScreenState();
}

class _EtihadLinkScreenState extends State<EtihadLinkScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Flow states
  bool _loading = false;
  bool _otpSent = false;
  bool _authenticated = false;
  bool _syncing = false;
  String? _error;
  String? _customerId;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _fmt(num amount, String currency) {
    final f = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return f.format(amount);
  }

  /// Step 1: Send credentials → triggers OTP
  Future<void> _loginInit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await etihadLoginInit(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Failed to connect to Etihad Bank. Please try again.';
          _loading = false;
        });
        return;
      }

      final status = result['status'] as String?;
      if (status == 'authenticated') {
        // No 2FA required — go straight to syncing accounts
        setState(() {
          _otpSent = false;
          _loading = false;
        });
        await _onLoginSuccess();
      } else if (status == 'otp_sent') {
        setState(() {
          _otpSent = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Unexpected response';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  /// Step 2: Verify OTP
  Future<void> _loginComplete() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await etihadLoginComplete(otp);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'OTP verification failed. Please try again.';
          _loading = false;
        });
        return;
      }

      setState(() => _loading = false);
      await _onLoginSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  /// After login: fetch customers → sync accounts → show account selection
  Future<void> _onLoginSuccess() async {
    if (!mounted) return;
    setState(() {
      _syncing = true;
      _error = null;
    });

    try {
      // 1) Get customers
      final custResult = await etihadGetCustomers();
      if (!mounted) return;

      if (custResult == null || custResult['data'] == null) {
        setState(() {
          _error = 'Failed to fetch customer data.';
          _syncing = false;
        });
        return;
      }

      // Extract first customer ID
      // Response shape: [{"User": "<uuid>", "Customer": null, "Accounts": [...]}]
      final rawData = custResult['data'];
      String? customerId;
      if (rawData is List && rawData.isNotEmpty) {
        final first = Map<String, dynamic>.from(rawData[0] as Map);
        customerId = (first['User'] ?? first['Id'] ?? first['id'])?.toString();
      } else if (rawData is Map) {
        final first = Map<String, dynamic>.from(rawData);
        customerId = (first['User'] ?? first['Id'] ?? first['id'])?.toString();
      }

      if (customerId == null || customerId.isEmpty) {
        setState(() {
          _error = 'No customer found for this account.';
          _syncing = false;
        });
        return;
      }

      _customerId = customerId;

      // 2) Sync accounts to Firestore
      final syncResult = await etihadSyncAccounts(customerId);
      if (!mounted) return;

      if (syncResult == null) {
        setState(() {
          _error = 'Failed to sync accounts.';
          _syncing = false;
        });
        return;
      }

      setState(() {
        _authenticated = true;
        _syncing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error syncing accounts: $e';
          _syncing = false;
        });
      }
    }
  }

  Future<void> _resync() async {
    if (_customerId == null) return;
    setState(() => _syncing = true);
    try {
      await etihadSyncAccounts(_customerId!);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _showCreateAccountDialog() async {
    if (_customerId == null) return;
    final nameC = TextEditingController();
    final currencyC = TextEditingController(text: 'JOD');
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool creating = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Create Test Account'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currencyC,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: creating
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            creating = true;
                            dialogError = null;
                          });
                          final nav = Navigator.of(ctx);
                          final resp = await etihadCreateAccount(
                            _customerId!,
                            nameC.text.trim(),
                            currency: currencyC.text.trim(),
                          );
                          if (resp != null && resp['status'] == 'success') {
                            nav.pop(true);
                          } else {
                            final detail = resp?['detail']?.toString() ??
                                'Failed to create account';
                            setDialogState(() {
                              creating = false;
                              dialogError = detail;
                            });
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await _resync();
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
        'provider': 'Etihad',
      }, SetOptions(merge: true));
    }

    batch.set(userRef, {
      'linkedAccountIds': FieldValue.arrayUnion(_selected.toList()),
    }, SetOptions(merge: true));

    await batch.commit();
    await calcTotalBalance();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etihad Bank accounts linked')),
    );

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
        title: Text('Etihad Bank', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        actions: [
          if (_authenticated)
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
      floatingActionButton: _authenticated
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
    if (_syncing && !_authenticated) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Syncing accounts...'),
          ],
        ),
      );
    }

    if (_error != null && !_authenticated) {
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
                    _otpSent = false;
                    _authenticated = false;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_authenticated) {
      return _buildAccountSelection();
    }

    if (_otpSent) {
      return _buildOtpForm();
    }

    return _buildLoginForm();
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Login to your Etihad Bank account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your online banking credentials to securely link your account.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _loginInit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _loading ? null : _showCreateUserDialog,
                child: Text(
                  'Create Sandbox Account',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final usernameC = TextEditingController();
    final passwordC = TextEditingController();
    final emailC = TextEditingController();
    final firstNameC = TextEditingController();
    final lastNameC = TextEditingController();
    final phoneC = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool creating = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Create Sandbox User'),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create a test account on the Etihad Bank sandbox.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: usernameC,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordC,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: firstNameC,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameC,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: creating
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            creating = true;
                            dialogError = null;
                          });

                          // Capture navigator before the await so we don't
                          // look up a deactivated context afterwards.
                          final nav = Navigator.of(ctx);

                          final resp = await etihadCreateUser(
                            username: usernameC.text.trim(),
                            password: passwordC.text.trim(),
                            email: emailC.text.trim(),
                            firstName: firstNameC.text.trim(),
                            lastName: lastNameC.text.trim(),
                            phoneNumber: phoneC.text.trim(),
                          );

                          if (resp != null && resp['status'] == 'success') {
                            nav.pop(true);
                          } else {
                            final detail = resp?['detail']?.toString() ?? 'Failed to create user';
                            setDialogState(() {
                              creating = false;
                              dialogError = detail;
                            });
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sandbox user created! You can now login.')),
      );
    }
  }

  Widget _buildOtpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Enter OTP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'An OTP has been sent to your registered phone number. Enter it below to complete the login.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'OTP Code',
              prefixIcon: Icon(Icons.sms),
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _loginComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
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
                  .where('provider', isEqualTo: 'Etihad')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_outlined,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'No accounts found',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a sandbox test account to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                _syncing ? null : _showCreateAccountDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Test Account'),
                          ),
                        ],
                      ),
                    ),
                  );
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
                            : (acc["name"]?.toString().trim().isNotEmpty ?? false)
                                ? acc["name"].toString()
                                : "Etihad Bank";

                    final customerName =
                        acc["customerName"]?.toString() ?? "Account";

                    num balance = 0;
                    final dynamic balRaw =
                        acc["availableBalance"] ?? acc["currentBalance"];
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
                                  if (states.contains(WidgetState.disabled)) {
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
                                      customerName,
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
    if (!mounted) return;
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

    if (!mounted) return;
    setState(() {
      _authUrl = authUrl;
      _webViewController = controller;
      _loading = false;
    });
  }

  Future<void> _handleCallback(String callbackUrl) async {
    if (_oauthComplete) return;
    if (!mounted) return;
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

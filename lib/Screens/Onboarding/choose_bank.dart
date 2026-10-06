import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/bank_link_ui.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChooseBank extends StatefulWidget {
  const ChooseBank({super.key});

  @override
  State<ChooseBank> createState() => _ChooseBankState();
}

class _ChooseBankState extends State<ChooseBank> {
  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    // (name, name for the badge, screen)
    final banks = <(String, String, Widget Function())>[
      ('Bank of JoPACC LTD.', 'JoPACC', () => const Jopacc()),
      ('Ahli Bank', 'Ahli Bank', () => const AhliLinkScreen()),
      ('Capital Bank', 'Capital Bank', () => const CapitalLinkScreen()),
      ('Bank Al Etihad', 'Bank Al Etihad', () => const EtihadLinkScreen()),
      ('Housing Bank', 'Housing Bank', () => const HbtfLinkScreen()),
    ];

    return Scaffold(
      appBar: const VestaAppBar(title: 'Link a bank account'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: VestaSpace.md),
              child: Text(
                'Pick your bank. You will sign in with the bank and choose which accounts to share.',
                style: TextStyle(fontSize: 13, color: v.muted),
              ),
            ),
            VestaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: VestaSpace.lg,
                vertical: 4,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < banks.length; i++)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => banks[i].$3()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(top: BorderSide(color: v.divider)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            BankBadge(banks[i].$2),
                            const SizedBox(width: VestaSpace.md),
                            Expanded(child: Text(banks[i].$1)),
                            Icon(
                              PhosphorIconsRegular.caretRight,
                              size: 16,
                              color: v.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.xl),
            OutlineButton(
              label: 'Not right now',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
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
      appBar: const VestaAppBar(title: ''),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.all(VestaSpace.xl),
          children: [
            Image.asset(
              'assets/images/choose_bank.png',
              width: 220,
              height: 220,
            ),
            const SizedBox(height: VestaSpace.xl),
            Text(
              'Link your bank account',
              textAlign: TextAlign.center,
              style: headingStyle(24),
            ),
            const SizedBox(height: VestaSpace.md),
            Text(
              'Securely connect your bank account to manage your finances all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.vesta.muted),
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChooseBank()),
                );
              },
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
    final v = context.vesta;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(PhosphorIconsRegular.warningCircle, color: v.neg),
            const SizedBox(width: 8),
            const Expanded(child: Text('Different account')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have linked accounts from "$existingUsername".',
            ),
            const SizedBox(height: 12),
            const Text(
              'To link accounts from a different JoPACC user, please unlink your existing accounts first.',
            ),
            const SizedBox(height: 12),
            Text(
              'Go to Wallet and hold an account to unlink it.',
              style: TextStyle(fontSize: 13, color: v.muted),
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
    return BankConsentCard(
      bankName: 'JoPACC',
      message: 'Share your JoPACC data with Vesta?',
      scopes: const [
        (PhosphorIconsRegular.wallet, 'Your account list and balances'),
        (PhosphorIconsRegular.receipt, 'Your transaction history'),
        (PhosphorIconsRegular.calendarDots, 'Standing orders & scheduled payments'),
      ],
      note:
          'Access is read-only and you can stop sharing at any time from your bank.',
      cancelLabel: 'No, cancel',
      onCancel: () {
        Navigator.of(context).pop();
      },
      onAllow: _syncing ? null : _onConsentApproved,
      busy: _syncing,
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
    return BankLinkScaffold(
      title: 'Bank of JoPACC LTD.',
      syncing: _syncing,
      onResync: _loggedIn ? _resync : null,
      showLinkBar: _loggedIn && _consentGiven,
      selectedCount: _selected.length,
      onLink: _linkSelected,
      body: !_loggedIn
          ? _buildLoginForm() // STEP 1: bank login
          : (!_consentGiven
                ? _buildConsentScreen() // STEP 2: consent
                : _buildAccountSelection()), // STEP 3: accounts in Vesta
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: BankLoginCard(
        bankName: 'JoPACC',
        title: 'Log in to JoPACC',
        fields: [
          TextFormField(
            controller: _username,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a username' : null,
          ),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
        submitLabel: 'Log in',
        loading: _loading,
        onSubmit: () async {
          await _mockLogin();
        },
      ),
    );
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankSelectHeader(
          syncing: _syncing,
          onSkip: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('accounts')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const BankLoadingState();
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const BankEmptyState(title: 'No accounts available');
              }

              final docs = snap.data!.docs;
              return LinkableAccountList(
                children: [
                  for (final doc in docs) _jopaccRow(doc),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _jopaccRow(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final acc = doc.data() as Map<String, dynamic>? ?? {};
    final linked = (acc['linked'] ?? false) == true;

    final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
        ? acc["bankName"].toString()
        : "Unknown Bank";
    final accountType = acc["accountTypeName"]?.toString() ?? "Unknown Type";
    num balance = 0;
    final dynamic balRaw = acc["balanceAmount"];
    if (balRaw is num) {
      balance = balRaw;
    } else if (balRaw is String) {
      balance = num.tryParse(balRaw) ?? 0;
    }

    final currency = acc["currency"]?.toString().trim().isNotEmpty == true
        ? acc["currency"].toString()
        : "JOD";


    final checked = _selected.contains(id) || linked;

    return LinkableAccountTile(
      title: bankName,
      lines: [accountType, ibanLine(acc["iban"], shorten: true)],
      balance: balance,
      currency: currency,
      checked: checked,
      linked: linked,
      onToggle: () {
        setState(() {
          if (checked) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
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
    return BankLinkScaffold(
      title: 'Capital Bank',
      syncing: _syncing,
      onResync: _oauthComplete ? _resync : null,
      showLinkBar: _oauthComplete,
      selectedCount: _selected.length,
      onLink: _linkSelected,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const BankLoadingState();
    }

    if (_error != null) {
      return BankErrorState(
        message: _error!,
        actionLabel: 'Retry',
        onAction: () {
          setState(() {
            _error = null;
            _loading = true;
          });
          _startLink();
        },
      );
    }

    if (_oauthComplete) {
      return _buildAccountSelection();
    }

    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankSelectHeader(
          syncing: _syncing,
          onSkip: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
        ),
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
                return const BankLoadingState(
                  message: 'Retrieving your accounts...',
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const BankEmptyState(title: 'No accounts available');
              }

              final docs = snap.data!.docs;
              return LinkableAccountList(
                children: [
                  for (final doc in docs) _capitalRow(doc),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _capitalRow(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final acc = doc.data() as Map<String, dynamic>? ?? {};
    final linked = (acc['linked'] ?? false) == true;

    final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
        ? acc["bankName"].toString()
        : "Capital Bank";
    final accountType = acc["accountTypeName"]?.toString() ?? "Account";

    num balance = 0;
    final dynamic balRaw = acc["balanceAmount"];
    if (balRaw is num) {
      balance = balRaw;
    } else if (balRaw is String) {
      balance = num.tryParse(balRaw) ?? 0;
    }
    final currency = acc["currency"]?.toString().trim().isNotEmpty == true
        ? acc["currency"].toString()
        : "JOD";

    final checked = _selected.contains(id) || linked;

    return LinkableAccountTile(
      title: bankName,
      lines: [accountType, ibanLine(acc["iban"])],
      balance: balance,
      currency: currency,
      checked: checked,
      linked: linked,
      onToggle: () {
        setState(() {
          if (checked) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
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
              title: const Text('Create test account'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currencyC,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(color: ctx.vesta.neg, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
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
    return BankLinkScaffold(
      title: 'Etihad Bank',
      syncing: _syncing,
      onResync: _authenticated ? _resync : null,
      showLinkBar: _authenticated,
      selectedCount: _selected.length,
      onLink: _linkSelected,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_syncing && !_authenticated) {
      return const BankLoadingState(message: 'Syncing accounts...');
    }

    if (_error != null && !_authenticated) {
      return BankErrorState(
        message: _error!,
        actionLabel: 'Try again',
        onAction: () {
          setState(() {
            _error = null;
            _otpSent = false;
            _authenticated = false;
          });
        },
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
    return Form(
      key: _formKey,
      child: BankLoginCard(
        bankName: 'Bank Al Etihad',
        title: 'Log in to Etihad Bank',
        subtitle:
            'Enter your online banking credentials to securely link your account.',
        fields: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(PhosphorIconsRegular.user),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(PhosphorIconsRegular.lockSimple),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Password is required' : null,
          ),
        ],
        submitLabel: 'Log in',
        loading: _loading,
        onSubmit: _loginInit,
        footer: TextButton(
          onPressed: _loading ? null : _showCreateUserDialog,
          child: const Text('Create sandbox account'),
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
              title: const Text('Create sandbox user'),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create a test account on the Etihad Bank sandbox.',
                        style: TextStyle(fontSize: 13, color: ctx.vesta.muted),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: usernameC,
                        decoration: const InputDecoration(
                          labelText: 'Username',
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
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: firstNameC,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameC,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
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
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: TextStyle(color: ctx.vesta.neg, fontSize: 13),
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
                FilledButton(
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
    return BankLoginCard(
      bankName: 'Bank Al Etihad',
      title: 'Enter the code',
      subtitle:
          'An OTP has been sent to your registered phone number. Enter it below to complete the login.',
      fields: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: amountStyle(18).copyWith(letterSpacing: 4),
          decoration: const InputDecoration(
            labelText: 'OTP code',
            prefixIcon: Icon(PhosphorIconsRegular.chatText),
            counterText: '',
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(fontSize: 13, color: context.vesta.neg)),
      ],
      submitLabel: 'Verify',
      loading: _loading,
      onSubmit: _loginComplete,
    );
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankSelectHeader(
          syncing: _syncing,
          onSkip: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
        ),
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
                return const BankLoadingState();
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return BankEmptyState(
                  title: 'No accounts found',
                  message: 'Create a sandbox test account to continue.',
                  action: PrimaryButton(
                    label: 'Create test account',
                    onPressed: _syncing ? null : _showCreateAccountDialog,
                  ),
                );
              }

              final docs = snap.data!.docs;
              return LinkableAccountList(
                children: [
                  for (final doc in docs) _etihadRow(doc),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _etihadRow(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final acc = doc.data() as Map<String, dynamic>? ?? {};
    final linked = (acc['linked'] ?? false) == true;

    final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
        ? acc["bankName"].toString()
        : (acc["name"]?.toString().trim().isNotEmpty ?? false)
        ? acc["name"].toString()
        : "Etihad Bank";

    final customerName = acc["customerName"]?.toString() ?? "Account";

    num balance = 0;
    final dynamic balRaw = acc["availableBalance"] ?? acc["currentBalance"];
    if (balRaw is num) {
      balance = balRaw;
    } else if (balRaw is String) {
      balance = num.tryParse(balRaw) ?? 0;
    }
    final currency = acc["currency"]?.toString().trim().isNotEmpty == true
        ? acc["currency"].toString()
        : "JOD";

    final checked = _selected.contains(id) || linked;

    return LinkableAccountTile(
      title: bankName,
      badgeName: 'Bank Al Etihad',
      lines: [customerName, ibanLine(acc["iban"])],
      balance: balance,
      currency: currency,
      checked: checked,
      linked: linked,
      onToggle: () {
        setState(() {
          if (checked) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
    );
  }
}

// ─── Housing Bank (HBTF) ───

/// Loan accounts carry an amount owed, not spendable money.
bool hbtfIsLoan(Map<String, dynamic> acc) {
  final code = acc['accountTypeCode']?.toString().toUpperCase();
  final name = acc['accountTypeName']?.toString().toUpperCase();
  return code == 'LAA' || name == 'LOAN';
}

/// The account status to call out (DORMANT, CLOSED, ...), or null when active.
String? hbtfInactiveStatus(Map<String, dynamic> acc) {
  final status = acc['accountStatus']?.toString().trim().toUpperCase() ?? '';
  return (status.isEmpty || status == 'ACTIVE') ? null : status;
}

/// "IBAN: ..." when the bank gave one, otherwise the masked account number.
String hbtfAccountRef(Map<String, dynamic> acc) {
  final iban = acc['iban']?.toString().trim() ?? '';
  if (iban.isNotEmpty) return 'IBAN: $iban';
  final number = acc['accountNumber']?.toString().trim() ?? '';
  if (number.length > 4) {
    return 'Account •••• ${number.substring(number.length - 4)}';
  }
  return number.isEmpty ? 'No IBAN available' : 'Account $number';
}

/// Loan and non-active status chips for a Housing Bank account card.
class HbtfAccountTags extends StatelessWidget {
  const HbtfAccountTags({super.key, required this.account});

  final Map<String, dynamic> account;

  @override
  Widget build(BuildContext context) {
    final status = hbtfInactiveStatus(account);
    final isLoan = hbtfIsLoan(account);
    if (status == null && !isLoan) return const SizedBox.shrink();

    final v = context.vesta;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isLoan) TagChip.pill('Loan · not in total balance', color: v.muted),
        if (status == 'DORMANT') TagChip.pill('Dormant', color: v.neg),
        if (status != null && status != 'DORMANT')
          TagChip.pill(
            '${status[0]}${status.substring(1).toLowerCase()}',
            color: v.muted,
          ),
      ],
    );
  }
}

/// "Connected" / "Access expired" line driven by `providers.hbtf` on the user doc.
class HbtfConnectionStatus extends StatelessWidget {
  const HbtfConnectionStatus({super.key, this.onReconnect});

  /// Defaults to opening [HbtfLinkScreen].
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final v = context.vesta;
        final userData = snap.data!.data();
        final state = hbtfLinkState(userData);

        if (state == HbtfLinkState.connected) {
          final expiresAt = DateTime.tryParse(
            userData?['providers']?['hbtf']?['tokens']?['expires_at']
                    ?.toString() ??
                '',
          );
          return Row(
            children: [
              Icon(PhosphorIconsFill.checkCircle, color: v.pos, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  expiresAt == null
                      ? 'Connected'
                      : 'Connected · until ${DateFormat('d MMM yyyy').format(expiresAt.toLocal())}',
                  style: TextStyle(fontSize: 12, color: v.pos),
                ),
              ),
            ],
          );
        }

        final reconnect =
            onReconnect ??
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HbtfLinkScreen()),
            );

        return InkWell(
          onTap: reconnect,
          borderRadius: BorderRadius.circular(VestaRadius.sm),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.linkSimple, color: v.accentInk, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  state == HbtfLinkState.expired
                      ? 'Access expired · Reconnect'
                      : 'Not connected · Link Housing Bank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: v.accentInk,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HbtfLinkScreen extends StatefulWidget {
  const HbtfLinkScreen({super.key});

  @override
  State<HbtfLinkScreen> createState() => _HbtfLinkScreenState();
}

class _HbtfLinkScreenState extends State<HbtfLinkScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String _loadingMessage = 'Connecting to Housing Bank...';
  bool _awaitingApproval = false;
  bool _checkingApproval = false;
  bool _tokenObtained = false;
  bool _linked = false;
  bool _syncing = false;
  String? _error;
  HbtfErrorKind? _errorKind;
  String? _approvalUrl;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // There is no callback from Iskan, so check again whenever the user comes back
    if (state == AppLifecycleState.resumed && _awaitingApproval) {
      _checkApproval(fromResume: true);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Skips a new consent while the current one is still valid, since initiating
  /// one would mark the bank unlinked until it is approved again.
  Future<void> _open() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      return;
    }

    HbtfLinkState state = HbtfLinkState.notLinked;
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      state = hbtfLinkState(userSnap.data());
    } catch (e) {
      print("Error reading Housing Bank link state: $e");
    }
    if (!mounted) return;

    if (state == HbtfLinkState.connected) {
      _tokenObtained = true;
      await _syncAccounts();
    } else {
      await _startLink();
    }
  }

  /// Step 1: start a consent, then either exchange it right away or send the
  /// customer to Iskan to approve it.
  Future<void> _startLink() async {
    setState(() {
      _loading = true;
      _loadingMessage = 'Connecting to Housing Bank...';
      _error = null;
      _errorKind = null;
      _awaitingApproval = false;
      _tokenObtained = false;
      _linked = false;
      _approvalUrl = null;
    });

    try {
      final consent = await hbtfInitiateConsent();
      if (!mounted) return;
      _approvalUrl = hbtfConsentLink(consent['links']);

      if (consent['consent_status'] == 'Authorised') {
        await _checkApproval();
        return;
      }

      if (_approvalUrl == null) {
        setState(() {
          _error =
              'Housing Bank did not return an approval link. Please try again later.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _awaitingApproval = true;
        _loading = false;
      });
      await _openApprovalLink();
    } on HbtfException catch (e) {
      _showError(e);
    }
  }

  Future<void> _openApprovalLink() async {
    final url = _approvalUrl;
    if (url == null) return;
    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print("Error opening Housing Bank approval link: $e");
    }
    if (!opened) {
      _snack("Couldn't open the Iskan app or your browser. Please try again.");
    }
  }

  /// Step 3. HBTF has no consent-status endpoint, so the token exchange is
  /// also how we find out whether the customer has approved.
  Future<void> _checkApproval({bool fromResume = false}) async {
    if (_checkingApproval || _tokenObtained) return;
    setState(() => _checkingApproval = true);

    try {
      await hbtfExchangeConsentToken();
      _tokenObtained = true;
    } on HbtfException catch (e) {
      if (!mounted) return;
      final keepWaiting =
          _approvalUrl != null &&
          (e.kind == HbtfErrorKind.pendingApproval ||
              e.kind == HbtfErrorKind.unavailable);
      if (keepWaiting) {
        setState(() {
          _awaitingApproval = true;
          _loading = false;
        });
        // Returning to the app before approving is normal, so only nag on a tap
        if (!fromResume || e.kind == HbtfErrorKind.unavailable) {
          _snack(e.userMessage);
        }
      } else {
        _showError(e);
      }
      return;
    } finally {
      if (mounted) setState(() => _checkingApproval = false);
    }

    await _syncAccounts();
  }

  /// Step 4: pull accounts and transactions into Firestore.
  Future<void> _syncAccounts() async {
    if (!mounted) return;
    setState(() {
      _awaitingApproval = false;
      _error = null;
      _errorKind = null;
      _loading = true;
      _loadingMessage = 'Retrieving your accounts...';
    });

    try {
      final failed = await hbtfSyncAll();
      if (!mounted) return;
      setState(() {
        _linked = true;
        _loading = false;
      });
      if (failed > 0) {
        _snack(
          "Some Housing Bank transactions couldn't be synced. Tap re-sync to try again.",
        );
      }
    } on HbtfException catch (e) {
      _showError(e);
    }
  }

  Future<void> _resync() async {
    setState(() => _syncing = true);
    try {
      final failed = await hbtfSyncAll();
      if (failed > 0) {
        _snack("Some Housing Bank transactions couldn't be synced.");
      }
    } on HbtfException catch (e) {
      if (e.kind == HbtfErrorKind.unavailable ||
          e.kind == HbtfErrorKind.unknown) {
        _snack(e.userMessage);
      } else {
        _showError(e);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showError(HbtfException e) {
    if (!mounted) return;
    // Outages can be retried in place; anything else needs a fresh consent
    if (e.kind != HbtfErrorKind.unavailable &&
        e.kind != HbtfErrorKind.unknown) {
      _tokenObtained = false;
    }
    setState(() {
      _error = e.userMessage;
      _errorKind = e.kind;
      _loading = false;
      _awaitingApproval = false;
      _linked = false;
    });
  }

  void _retry() {
    if (_tokenObtained) {
      _syncAccounts();
    } else {
      _startLink();
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
        'provider': hbtfProviderLabel,
      }, SetOptions(merge: true));
    }

    batch.set(userRef, {
      'linkedAccountIds': FieldValue.arrayUnion(_selected.toList()),
    }, SetOptions(merge: true));

    await batch.commit();
    await calcTotalBalance();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Housing Bank accounts linked')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BankLinkScaffold(
      title: 'Housing Bank',
      syncing: _syncing,
      onResync: _linked ? _resync : null,
      showLinkBar: _linked,
      selectedCount: _selected.length,
      onLink: _linkSelected,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return BankLoadingState(message: _loadingMessage);
    }

    if (_error != null) {
      final reconnect =
          _errorKind == HbtfErrorKind.consentExpired ||
          _errorKind == HbtfErrorKind.notLinked ||
          _errorKind == HbtfErrorKind.noConsent;
      return BankErrorState(
        message: _error!,
        reconnect: reconnect,
        actionLabel: reconnect ? 'Link Housing Bank' : 'Retry',
        onAction: _retry,
      );
    }

    if (_linked) {
      return _buildAccountSelection();
    }

    if (_awaitingApproval) {
      return _buildAwaitingApproval();
    }

    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildAwaitingApproval() {
    return BankConsentCard(
      bankName: hbtfProviderLabel,
      title: 'Approve in the Iskan app',
      message:
          "We've opened Housing Bank's Iskan app (or your browser). "
          'Approve the request to share your accounts with Vesta, then come back here.',
      scopes: const [
        (PhosphorIconsRegular.wallet, 'Your account list and balances'),
        (PhosphorIconsRegular.receipt, 'Your transaction history'),
      ],
      note: 'Access is read-only.',
      cancelLabel: 'Start over',
      onCancel: _checkingApproval ? null : _startLink,
      allowLabel: "I've approved it",
      onAllow: _checkingApproval ? null : _checkApproval,
      busy: _checkingApproval,
      extraActions: [
        TextButton(
          onPressed: _checkingApproval ? null : _openApprovalLink,
          child: const Text('Open Iskan again'),
        ),
      ],
    );
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankSelectHeader(
          syncing: _syncing,
          onSkip: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
          below: HbtfConnectionStatus(onReconnect: _startLink),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('accounts')
                .where('provider', isEqualTo: hbtfProviderLabel)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const BankLoadingState();
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const BankEmptyState(
                  title: 'No Housing Bank accounts found',
                );
              }

              final docs = snap.data!.docs;
              return LinkableAccountList(
                children: [
                  for (final doc in docs) _hbtfRow(doc),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hbtfRow(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final acc = doc.data() as Map<String, dynamic>? ?? {};
    final linked = (acc['linked'] ?? false) == true;
    final isLoan = hbtfIsLoan(acc);

    final accountType =
        acc["accountTypeName"]?.toString().trim().isNotEmpty == true
        ? acc["accountTypeName"].toString()
        : "Account";

    num balance = 0;
    final dynamic balRaw = acc["balanceAmount"];
    if (balRaw is num) {
      balance = balRaw;
    } else if (balRaw is String) {
      balance = num.tryParse(balRaw) ?? 0;
    }
    final currency = acc["currency"]?.toString().trim().isNotEmpty == true
        ? acc["currency"].toString()
        : "JOD";

    final checked = _selected.contains(id) || linked;
    final showTags = isLoan || hbtfInactiveStatus(acc) != null;

    return LinkableAccountTile(
      title: hbtfProviderLabel,
      lines: [accountType, hbtfAccountRef(acc)],
      balance: balance,
      currency: currency,
      neutralBalance: isLoan,
      checked: checked,
      linked: linked,
      extra: showTags ? HbtfAccountTags(account: acc) : null,
      onToggle: () {
        setState(() {
          if (checked) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
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
    return BankLinkScaffold(
      title: 'Ahli Bank',
      syncing: _syncing,
      onResync: _oauthComplete ? _resync : null,
      showLinkBar: _oauthComplete,
      selectedCount: _selected.length,
      onLink: _linkSelected,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const BankLoadingState();
    }

    if (_error != null) {
      return BankErrorState(
        message: _error!,
        actionLabel: 'Retry',
        onAction: () {
          setState(() {
            _error = null;
            _loading = true;
          });
          _startLink();
        },
      );
    }

    if (_oauthComplete) {
      return _buildAccountSelection();
    }

    // Show WebView for OAuth
    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    return const Center(child: Text('Something went wrong'));
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankSelectHeader(
          syncing: _syncing,
          onSkip: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
        ),
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
                return const BankLoadingState();
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const BankEmptyState(title: 'No accounts available');
              }

              final docs = snap.data!.docs;
              return LinkableAccountList(
                children: [
                  for (final doc in docs) _ahliRow(doc),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _ahliRow(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final acc = doc.data() as Map<String, dynamic>? ?? {};
    final linked = (acc['linked'] ?? false) == true;

    final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
        ? acc["bankName"].toString()
        : "Ahli Bank";
    final accountType = acc["accountTypeName"]?.toString() ?? "Account";

    num balance = 0;
    final dynamic balRaw = acc["balanceAmount"];
    if (balRaw is num) {
      balance = balRaw;
    } else if (balRaw is String) {
      balance = num.tryParse(balRaw) ?? 0;
    }
    final currency = acc["currency"]?.toString().trim().isNotEmpty == true
        ? acc["currency"].toString()
        : "JOD";

    final checked = _selected.contains(id) || linked;

    return LinkableAccountTile(
      title: bankName,
      lines: [accountType, ibanLine(acc["iban"])],
      balance: balance,
      currency: currency,
      checked: checked,
      linked: linked,
      onToggle: () {
        setState(() {
          if (checked) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
    );
  }
}

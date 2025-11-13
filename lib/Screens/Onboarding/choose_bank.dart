import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/pages/home.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';
import 'package:intl/intl.dart';

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
        child: Padding(
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
            ],
          ),
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

  @override
  void initState() {
    super.initState();
    _tryAutoLoadStoredUsername();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _tryAutoLoadStoredUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final stored = doc.data()?['providers']?['jopacc']?['username'];
    if (stored is String && stored.trim().isNotEmpty) {
      _username.text = stored;
      _lastUsername = stored;
      setState(() { _loggedIn = true; _syncing = true; });
      try {
        await syncAccounts(''); // will read stored username
        await _pollAccountsOnce();
      } finally {
        if (mounted) setState(() => _syncing = false);
      }
    }
  }

  String _fmt(num amount, String currency) {
    final f = NumberFormat.currency(locale: 'en_US', symbol: "$currency ", decimalDigits: 2);
    return f.format(amount);
  }

  Future<void> _mockLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final entered = _username.text.trim();

    // Save username to Firestore for future syncs
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'providers': {
        'jopacc': {
          'username': entered,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));

    setState(() {
      _loggedIn = true;
      _syncing = true;
      _lastUsername = entered;
      _selected.clear();
    });

    try {
      await syncAccounts(entered);
      await _pollAccountsOnce();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _pollAccountsOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (int i = 0; i < 6; i++) {
      final qs = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('accounts').limit(1).get();
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
    final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('accounts');

    for (final id in _selected) {
      batch.set(
        col.doc(id),
        {
          'linked': true,
          'linkedAt': FieldValue.serverTimestamp(),
          if (_lastUsername != null) 'linkedByUsername': _lastUsername,
          'provider': 'JoPACC',
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accounts linked')),
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
        title: Text('Bank of JoPACC LTD.', style: TextStyle(color: scheme.surface)),
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
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(16),
        child: _loggedIn ? _buildAccountSelection() : _buildLoginForm(),
      ),
      floatingActionButton: _loggedIn
          ? FloatingActionButton.extended(
              onPressed: _selected.isEmpty ? null : _linkSelected,
              backgroundColor: _selected.isEmpty ? Colors.grey : scheme.primary,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text('Link Selected', style: TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Mock Bank Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.primary)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username (saved to Firestore)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a username' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (ignored)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _mockLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Login & Fetch Accounts'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a mock login. Password is not sent or stored.\nWe call the get-accounts API with your saved username.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_syncing) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.account_balance),
            SizedBox(width: 8),
            Text('Select accounts to link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final id = doc.id;
                  final acc = doc.data() as Map<String, dynamic>? ?? {};
                  final linked = (acc['linked'] ?? false) == true;

                  final bankName =
                      acc["institutionBasicInfo"]?["name"]?["enName"] ??
                      acc["institutionName"] ??
                      "Unknown Bank";
                  final accountType =
                      acc["accountType"]?["name"] ??
                      acc["type"] ??
                      "Unknown Type";
                  final balance =
                      acc["availableBalance"]?["balanceAmount"] ??
                      acc["balance"] ?? 0;
                  final currency =
                      acc["accountCurrency"]?.toString() ??
                      acc["raw"]?["accountCurrency"]?.toString() ?? "JOD";
                  final iban =
                      acc["mainRoute"]?["address"] ??
                      acc["iban"] ??
                      acc["raw"]?["mainRoute"]?["address"] ??
                      "No IBAN available";

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
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        _fmt((balance is num) ? balance : 0, currency),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(accountType, style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text("IBAN: $iban", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  if (linked) ...[
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                                        SizedBox(width: 6),
                                        Text('Linked', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
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

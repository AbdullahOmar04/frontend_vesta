// lib/Screens/Banking/ahli_link_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Screens/pages/main_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AhliLinkScreen extends StatefulWidget {
  const AhliLinkScreen({super.key});

  @override
  State<AhliLinkScreen> createState() => _AhliLinkScreenState();
}

class _AhliLinkScreenState extends State<AhliLinkScreen> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _syncing = false;
  bool _authed = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _listenForCallback();
    _checkIfAlreadyHasAccounts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _checkIfAlreadyHasAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .where('provider', isEqualTo: 'ahli')
        .limit(1)
        .get();

    if (!mounted) return;
    setState(() => _authed = qs.docs.isNotEmpty);
  }

  void _listenForCallback() {
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      // Expect redirect like: vesta://auth/ahli?code=...&state=...
      if (uri.host != "auth") return;
      if (!uri.path.contains("ahli")) return;

      final code = uri.queryParameters["code"];
      final state = uri.queryParameters["state"];
      final error = uri.queryParameters["error"];

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ahli auth error: $error")),
        );
        return;
      }

      if (code == null || state == null) return;

      await _handleAuthCallback(code: code, state: state);
    });
  }

  Future<void> _startConnect() async {
    setState(() => _syncing = true);
    try {
      final authUrl = await ahliStartAuth();
      if (authUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to start Ahli authorization")),
        );
        return;
      }

      final uri = Uri.parse(authUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Ahli login page")),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _handleAuthCallback({required String code, required String state}) async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final ok = await ahliFinishAuth(code: code, state: state);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ahli auth exchange failed")),
        );
        return;
      }

      await ahliSyncAccounts();
      await _pollAccountsOnce();

      if (!mounted) return;
      setState(() => _authed = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ahli connected. Select accounts to link.")),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _pollAccountsOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    for (int i = 0; i < 8; i++) {
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('provider', isEqualTo: 'ahli')
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) break;
      await Future.delayed(const Duration(seconds: 1));
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

  Future<void> _linkSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selected.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts');

    for (final id in _selected) {
      batch.set(col.doc(id), {
        'linked': true,
        'linkedAt': FieldValue.serverTimestamp(),
        'provider': 'ahli',
      }, SetOptions(merge: true));
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
        title: Text("Ahli Bank", style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        actions: [
          if (_authed)
            IconButton(
              onPressed: _syncing
                  ? null
                  : () async {
                      setState(() => _syncing = true);
                      try {
                        await ahliSyncAccounts();
                        await _pollAccountsOnce();
                      } finally {
                        if (mounted) setState(() => _syncing = false);
                      }
                    },
              icon: Icon(Icons.sync, color: scheme.surface),
              tooltip: "Re-sync",
            )
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
        child: !_authed ? _buildConnectCard() : _buildAccountSelection(),
      ),
      floatingActionButton: _authed
          ? FloatingActionButton.extended(
              onPressed: _selected.isEmpty ? null : _linkSelected,
              backgroundColor: _selected.isEmpty ? Colors.grey : scheme.primary,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text('Link Selected', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildConnectCard() {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Connect Ahli Bank",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("You’ll be redirected to Ahli to login and approve read-only access to:"),
                const SizedBox(height: 8),
                const Text("• Accounts & balances"),
                const Text("• Transactions"),
                const Text("• Standing orders / scheduled payments"),
                const SizedBox(height: 18),
                if (_syncing) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _syncing ? null : _startConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Continue to Ahli Login"),
                  ),
                ),
                const SizedBox(height: 6),
              ],
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
                .where('provider', isEqualTo: 'ahli')
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
                      "Ahli Bank";
                  final accountType =
                      acc["accountType"]?["name"] ??
                      acc["type"] ??
                      "Unknown Type";
                  final balance =
                      acc["availableBalance"]?["balanceAmount"] ??
                      acc["availableBalance"]?["amount"] ??
                      acc["balance"] ??
                      0;
                  final currency =
                      acc["accountCurrency"]?.toString() ??
                      "JOD";
                  final iban =
                      acc["mainRoute"]?["address"] ??
                      acc["iban"] ??
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
                      color: Colors.white,
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green[700],
                                        ),
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

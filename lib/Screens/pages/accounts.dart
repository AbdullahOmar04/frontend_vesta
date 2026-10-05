// AccountsPage.dart — rewritten to use trimmed flat fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/add_account.dart';

class AccountsPage extends StatefulWidget {
  final bool showBack;
  const AccountsPage({super.key, this.showBack = true});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool _unlinking = false;
  bool _removing = false;

  Future<void> _showDeleteDialog(String accountId, String bankName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$bankName"?'),
            const SizedBox(height: 12),
            Text(
              'This will also delete all transactions associated with this account.',
              style: TextStyle(color: context.vesta.neg, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.vesta.neg),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(accountId);
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _unlinking = true);

    try {
      await deleteAccountAndTransactions(uid: uid, accountId: accountId);

      await calcTotalBalance();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _unlinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: widget.showBack
          ? const VestaAppBar(title: 'Wallet')
          : const VestaAppBar.large(title: 'Wallet'),
      body: VestaBackground(
        child: uid == null
            ? const Center(child: Text("Not logged in"))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("accounts")
                    .where('linked', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final accounts = snapshot.hasData
                      ? snapshot.data!.docs
                      : <QueryDocumentSnapshot>[];

                  num total = 0;
                  final currencies = <String>{};
                  for (final doc in accounts) {
                    final acc = doc.data() as Map<String, dynamic>;
                    total += _balanceOf(acc);
                    currencies.add(_currencyOf(acc));
                  }
                  final totalCurrency =
                      currencies.length == 1 ? currencies.first : "JOD";

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VestaSpace.gutter,
                      10,
                      VestaSpace.gutter,
                      VestaSpace.xl,
                    ),
                    children: [
                      _netWorth(total, totalCurrency, accounts.length),
                      const SizedBox(height: VestaSpace.gutter),
                      SectionHeader(
                        title: 'Accounts',
                        trailing: [
                          OutlineIconButton(
                            icon: PhosphorIconsRegular.plus,
                            tooltip: 'Add account',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddAccountPage(),
                                ),
                              );
                            },
                          ),
                          if (accounts.isNotEmpty)
                            OutlineIconButton(
                              icon: _removing
                                  ? PhosphorIconsRegular.check
                                  : PhosphorIconsRegular.minus,
                              color: _removing ? null : context.vesta.neg,
                              tooltip: _removing ? 'Done' : 'Remove an account',
                              onPressed: () {
                                setState(() => _removing = !_removing);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            "No accounts yet. Tap + to add one.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.vesta.muted,
                            ),
                          ),
                        ),
                      for (final doc in accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _accountRow(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  num _balanceOf(Map<String, dynamic> acc) {
    final dynamic balRaw = acc["balanceAmount"];
    if (balRaw is num) return balRaw;
    if (balRaw is String) return num.tryParse(balRaw) ?? 0;
    return 0;
  }

  String _currencyOf(Map<String, dynamic> acc) =>
      acc["currency"]?.toString().trim().isNotEmpty == true
          ? acc["currency"].toString()
          : "JOD";

  Widget _netWorth(num total, String currency, int count) {
    final muted = TextStyle(fontSize: 13, color: context.vesta.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Net worth', style: muted),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyText(total, currency: currency, size: 36),
        ),
        Text(
          count == 1 ? 'Across 1 account' : 'Across $count accounts',
          style: muted,
        ),
      ],
    );
  }

  Widget _accountRow(String accountId, Map<String, dynamic> acc) {
    final v = context.vesta;

    final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
        ? acc["bankName"].toString()
        : "Unknown Bank";

    final accountType = acc["accountTypeName"]?.toString() ?? "Unknown Type";

    // Manually added accounts have no IBAN, so only the type is shown
    final iban = acc["iban"]?.toString().trim() ?? "";
    final subtitle = iban.length >= 4
        ? "$accountType · •••• ${iban.substring(iban.length - 4)}"
        : accountType;

    final balance = _balanceOf(acc);

    return GestureDetector(
      onLongPress: _unlinking
          ? null
          : () => _showDeleteDialog(accountId, bankName),
      child: VestaCard(
        radius: VestaRadius.lg,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (_removing) ...[
              Material(
                color: v.neg.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _unlinking
                      ? null
                      : () => _showDeleteDialog(accountId, bankName),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Icon(
                      PhosphorIconsRegular.minus,
                      size: 14,
                      color: v.neg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: VestaSpace.md),
            ],
            BankBadge(bankName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          bankName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: VestaSpace.sm),
                      MoneyText(
                        balance,
                        currency: _currencyOf(acc),
                        color: balance < 0 ? v.neg : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> calcTotalBalance() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final accountsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('accounts')
      .where('linked', isEqualTo: true)
      .get();

  num totalBalance = 0;

  for (final doc in accountsSnap.docs) {
    final acc = doc.data();
    final dynamic balanceRaw = acc['balanceAmount'] ?? 0;

    if (balanceRaw is num) {
      totalBalance += balanceRaw;
    } else if (balanceRaw is String) {
      totalBalance += num.tryParse(balanceRaw) ?? 0;
    }
  }

  await updateIfChanged(FirebaseFirestore.instance.collection('users').doc(uid), {
    'totalBalance': totalBalance,
    'totalBalanceUpdatedAt': FieldValue.serverTimestamp(),
  });
}

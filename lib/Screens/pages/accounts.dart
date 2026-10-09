// AccountsPage.dart — rewritten to use trimmed flat fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/api_calls.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/choose_bank.dart';
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
                  var counted = 0;
                  for (final doc in accounts) {
                    final acc = doc.data() as Map<String, dynamic>;
                    // A Housing Bank loan balance is money owed, not money the user has
                    if (_isHbtfLoan(acc)) continue;
                    total += _balanceOf(acc);
                    currencies.add(_currencyOf(acc));
                    counted++;
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
                      _netWorth(total, totalCurrency, counted),
                      const SizedBox(height: VestaSpace.gutter),
                      SectionHeader(
                        title: 'Accounts',
                        trailing: [
                          OutlineIconButton(
                            icon: PhosphorIconsRegular.bank,
                            tooltip: 'Link a bank',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChooseBank(),
                                ),
                              );
                            },
                          ),
                          AddRemoveButtons(
                            onAdd: () => showAddAccountSheet(context),
                            addTooltip: 'Add account',
                            removing: _removing,
                            canRemove: accounts.isNotEmpty,
                            removeTooltip: 'Remove an account',
                            onToggleRemove: () {
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

  bool _isHbtfLoan(Map<String, dynamic> acc) =>
      acc["provider"] == hbtfProviderLabel && hbtfIsLoan(acc);

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

    // Bank accounts end in their IBAN; manual ones in the last 4 digits
    // the user gave, if any
    final iban = acc["iban"]?.toString().trim() ?? "";
    final mask = acc["mask"]?.toString().trim() ?? "";
    final last4 = iban.length >= 4 ? iban.substring(iban.length - 4) : mask;
    final subtitle = last4.isNotEmpty ? "$accountType · •••• $last4" : accountType;

    final balance = _balanceOf(acc);

    // No unlink/revoke endpoint exists for Housing Bank yet
    final isHbtf = acc["provider"] == hbtfProviderLabel;
    final isLoan = _isHbtfLoan(acc);

    return GestureDetector(
      onLongPress: _unlinking || isHbtf
          ? null
          : () => _showDeleteDialog(accountId, bankName),
      child: VestaCard(
        radius: VestaRadius.lg,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (_removing && isHbtf)
              const SizedBox(width: 26 + VestaSpace.md)
            else if (_removing) ...[
              RemoveBadge(
                onTap: _unlinking
                    ? null
                    : () => _showDeleteDialog(accountId, bankName),
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
                        color: balance < 0 && !isLoan ? v.neg : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isHbtf ? hbtfAccountRef(acc) : subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isHbtf) ...[
                    const SizedBox(height: VestaSpace.sm),
                    HbtfAccountTags(account: acc),
                    const SizedBox(height: VestaSpace.sm),
                    const HbtfConnectionStatus(),
                  ],
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
    // A Housing Bank loan balance is money owed, not money the user has
    if (acc['provider'] == hbtfProviderLabel && hbtfIsLoan(acc)) continue;

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

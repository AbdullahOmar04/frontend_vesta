// AccountsPage.dart — rewritten to use trimmed flat fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/Onboarding/choose_bank.dart';
import 'package:intl/intl.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool _unlinking = false;

  String _formatCurrency(num amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Future<void> _showUnlinkDialog(String accountId, String bankName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to unlink "$bankName"?'),
            const SizedBox(height: 12),
            const Text(
              'This will also delete all transactions associated with this account.',
              style: TextStyle(color: Colors.red, fontSize: 13),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _unlinkAccount(accountId);
    }
  }

  Future<void> _unlinkAccount(String accountId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _unlinking = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final accountRef = userRef.collection('accounts').doc(accountId);

      // Delete all transactions for this account
      final txSnap = await accountRef.collection('transactions').get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in txSnap.docs) {
        batch.delete(doc.reference);
      }

      // Remove from linkedAccountIds array (if you still use it)
      batch.set(userRef, {
        'linkedAccountIds': FieldValue.arrayRemove([accountId]),
      }, SetOptions(merge: true));

      // Mark account unlinked
      batch.set(accountRef, {
        'linked': false,
        'unlinkedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      await calcTotalBalance();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account unlinked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlink account: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "My Accounts",
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChooseBank()),
          );
        },
        tooltip: 'Add Account',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
      ),
      body: uid == null
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
                  return Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "No linked accounts.\nGo to “Link Your Bank” to add some.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                final accounts = snapshot.data!.docs;

                return Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final accountId = accounts[index].id;
                      final acc = accounts[index].data() as Map<String, dynamic>;

                      final bankName = (acc["bankName"]?.toString().trim().isNotEmpty ?? false)
                          ? acc["bankName"].toString()
                          : "Unknown Bank";

                      final accountType =
                          acc["accountTypeName"]?.toString() ?? "Unknown Type";

                      final currency =
                          acc["currency"]?.toString().trim().isNotEmpty == true
                              ? acc["currency"].toString()
                              : "JOD";

                      final iban = acc["iban"]?.toString().trim().isNotEmpty == true
                          ? acc["iban"].toString()
                          : "No IBAN available";

                      final ibanDisplay = iban.length > 16
                          ? "${iban.substring(0, 6)}...${iban.substring(iban.length - 4)}"
                          : iban;

                      num balance = 0;
                      final dynamic balRaw = acc["balanceAmount"];
                      if (balRaw is num) {
                        balance = balRaw;
                      } else if (balRaw is String) {
                        balance = num.tryParse(balRaw) ?? 0;
                      }

                      return GestureDetector(
                        onLongPress: _unlinking
                            ? null
                            : () => _showUnlinkDialog(accountId, bankName),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      child: const Icon(
                                        Icons.account_balance,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        bankName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(balance, currency),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  accountType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "IBAN: $ibanDisplay",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Hold to unlink",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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

  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'totalBalance': totalBalance,
    'totalBalanceUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

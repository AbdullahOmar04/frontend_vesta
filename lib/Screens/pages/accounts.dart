import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  String _formatCurrency(num amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: "$currency ",
      decimalDigits: 2,
    );
    return formatter.format(amount);
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
      // Floating action button (UI only, no action)
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // void: UI only
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No accounts available",
                      style: TextStyle(fontSize: 16),
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
                      final acc =
                          accounts[index].data() as Map<String, dynamic>;

                      final bankName =
                          acc["institutionBasicInfo"]?["name"]?["enName"] ??
                          "Unknown Bank";
                      final accountType =
                          acc["accountType"]?["name"] ?? "Unknown Type";
                      final balance =
                          acc["availableBalance"]?["balanceAmount"] ?? 0;
                      final currency =
                          acc["accountCurrency"]?.toString() ?? "JOD";
                      final iban =
                          acc["mainRoute"]?["address"] ?? "No IBAN available";

                      return Card(
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
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                "IBAN: $iban",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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

  try {
    final accountsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .get();

    num totalBalance = 0;

    for (final doc in accountsSnap.docs) {
      final acc = doc.data();
      final dynamic balanceRaw = acc['availableBalance']?['balanceAmount'] ?? 0;
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
  } catch (_) {
    rethrow;
  }
}
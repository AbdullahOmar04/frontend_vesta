// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';
import 'package:frontend_vesta/Screens/pages/settings.dart' as app_settings;

import 'dart:async';

Future<void> fetchCurrentCycleData() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final fire = FirebaseFirestore.instance;
  final userRef = fire.collection('users').doc(uid);

  final String monthId =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  // 1. Fetch budget data
  final budgetDoc = await fire
      .collection("users")
      .doc(uid)
      .collection("budget")
      .doc(monthId)
      .get();

  final budgetData = budgetDoc.data() ?? {};
  final budgetResetDay = (budgetData['budgetResetDay'] ?? 28) as int;

  // 2. Fetch category buckets
  final categoriesSnap = await userRef.collection('categories').get();
  final categoryBuckets = <String, String>{};
  for (var doc in categoriesSnap.docs) {
    final data = doc.data();
    final bucketRaw = (data['bucket'] ?? '') as String;
    final bucket = bucketRaw.isEmpty
        ? inferBucketFromCategoryName(doc.id)
        : bucketRaw;
    categoryBuckets[doc.id] = bucket;
  }

  // 3. Calculate current cycle dates
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  if (now.day >= budgetResetDay) {
    startDate = DateTime(now.year, now.month, budgetResetDay);
    final nextMonth = DateTime(now.year, now.month + 1, budgetResetDay);
    endDate = nextMonth.subtract(const Duration(days: 1));
  } else {
    startDate = DateTime(now.year, now.month - 1, budgetResetDay);
    final thisMonth = DateTime(now.year, now.month, budgetResetDay);
    endDate = thisMonth.subtract(const Duration(days: 1));
  }
  endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

  // 4. Calculate current spending from all accounts
  double currentSpending = 0;
  double totalSavings = 0;
  final accountsSnap = await userRef.collection('accounts').get();

  for (var account in accountsSnap.docs) {
    final accountData = account.data();

    // Check if this is a savings account and add its balance to totalSavings
    final accountTypeCode = (accountData['accountTypeCode'] ?? '').toString();
    final isLinked = accountData['linked'] == true;
    if (isLinked && accountTypeCode == 'SAV.IND') {
      final balance = (accountData['balanceAmount'] ?? 0).toDouble();
      totalSavings += balance;
    }

    final txSnap = await userRef
        .collection('accounts')
        .doc(account.id)
        .collection('transactions')
        .get();

    for (var doc in txSnap.docs) {
      final data = doc.data();

      // Only count debit transactions
      final transactionType = (data['type'] ?? '').toString().toLowerCase();
      if (transactionType != 'debit') continue;

      // Parse date
      DateTime? transactionDate;
      if (data.containsKey('date') && data['date'] != null) {
        transactionDate = DateTime.tryParse(data['date'] as String);
      }
      if (transactionDate == null) continue;

      // Check if within cycle
      if (transactionDate.isBefore(startDate) ||
          transactionDate.isAfter(endDate)) {
        continue;
      }

      // Check category
      final category = data['category'] as String?;
      if (category == null || category.isEmpty) continue;

      final bucket =
          categoryBuckets[category] ?? inferBucketFromCategoryName(category);

      // Only count essential and luxury buckets for spending
      if (bucket != 'essential' && bucket != 'luxury') continue;

      // Parse amount
      double amount = 0;
      if (data.containsKey('amount') && data['amount'] != null) {
        amount = double.tryParse(data['amount'].toString()) ?? 0.0;
      }
      currentSpending += amount;
    }
  }

  // 5. Update Firestore with total expense and savings
  await updateIfChanged(userRef, {
    'totalExpense': currentSpending,
    'totalSavings': totalSavings,
  });
}

String inferBucketFromCategoryName(String name) {
  final n = name.toLowerCase().trim();

  if (n.contains('saving')) return 'savings';

  // food-ish defaults
  if (n.contains('grocery') || n.contains('supermarket')) {
    return 'essential';
  }
  if (n.contains('food') || n.contains('drink') || n.contains('restaurant')) {
    return 'essential'; // you can change to luxury if you want
  }

  if (n.contains('rent') ||
      n.contains('bill') ||
      n.contains('electric') ||
      n.contains('water') ||
      n.contains('internet') ||
      n.contains('fuel') ||
      n.contains('transport')) {
    return 'essential';
  }

  if (n.contains('entertainment') ||
      n.contains('cinema') ||
      n.contains('netflix') ||
      n.contains('spotify') ||
      n.contains('travel') ||
      n.contains('luxury')) {
    return 'luxury';
  }

  if (n.contains('salary') ||
      n.contains('income') ||
      n.contains('wage') ||
      n.contains('payroll')) {
    return 'income';
  }

  // Default: treat as essential so it still counts in spending
  return 'essential';
}

final ValueNotifier<List<String>> categoryLabelsNotifier =
    ValueNotifier<List<String>>([
      'Food And Drinks',
      'Groceries',
      'Entertainment',
      'Savings',
      'Others',
    ]);

List<String> get categoryLabels => categoryLabelsNotifier.value;

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categorySub;

/// Starts a listener on the current user's `categories` collection and updates
/// `categoryLabelsNotifier`. This is invoked once when this file is loaded.
void startCategoryListener() {
  // cancel previous if any
  _categorySub?.cancel();

  FirebaseAuth.instance.authStateChanges().listen((user) {
    _categorySub?.cancel();

    if (user == null) {
      categoryLabelsNotifier.value = [];
      return;
    }

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (obj, _) => obj,
        );

    _categorySub = col.snapshots().listen(
      (snap) {
        var labels = snap.docs.map((d) {
          final data = d.data();
          if (data['name'] is String &&
              (data['name'] as String).trim().isNotEmpty) {
            return (data['name'] as String).trim();
          }
          return d.id;
        }).toList();

        // keep some defaults if collection is empty (optional)
        if (labels.isEmpty) {
          labels = [
            'Food And Drinks',
            'Groceries',
            'Entertainment',
            'Savings',
            'Others',
          ];
        }

        categoryLabelsNotifier.value = labels;
      },
      onError: (_) {
        // on error keep existing labels or fallback
      },
    );
  });
}

Future<bool> _checkForHouseholds() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final userDocRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  try {
    final doc = await userDocRef.get();
    final data = doc.data();
    if (data == null || data['householdIds'] == null) {
      return false;
    } else {
      final householdIds = List<String>.from(data['householdIds']);
      return householdIds.isNotEmpty;
    }
  } catch (_) {
    return false;
  }
}

Widget largeButton(
  BuildContext context,
  String text,
  Color color,
  VoidCallback onPressed,
) {
  return SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}

Widget splashSmallButton(
  BuildContext context,
  String text,
  Color color,
  VoidCallback onPressed,
) {
  return SizedBox(
    width: 120,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ignore: non_constant_identifier_names
Widget BankCard(
  BuildContext context,
  String bankName,
  String logoPath,
  Color color,
  VoidCallback onPressed,
) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: SizedBox(
      height: 100,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(logoPath, width: 60, height: 60),
            const SizedBox(width: 20),
            Text(
              bankName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget drawer(BuildContext context, String username) {
  final user = FirebaseAuth.instance.currentUser;
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            'Menu',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => app_settings.Settings()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text('Change Day of Month'),
          onTap: () {
            inputDayOfMonth(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        ListTile(
          leading: const Icon(Icons.developer_mode),
          title: const Text('GET UID'),
          onTap: () {
            print(user?.uid);
          },
        ),
      ],
    ),
  );
}

Widget squareButton(
  BuildContext context,
  String text,
  IconData icon,
  Color color,
  VoidCallback onPressed,
) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: SizedBox(
      height: 140,
      width: 180,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Icon(icon, color: Colors.white, size: 30)]),
            SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> inputDayOfMonth(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .get();
  final userData = userDoc.data();
  if (userData == null) return;

  final int dayOfMonth = userData["dayOfMonth"] ?? 28;
  final controller = TextEditingController(text: dayOfMonth.toString());

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 55, 54, 67),
                          const Color.fromARGB(
                            255,
                            55,
                            54,
                            67,
                          ).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Update Day of Month",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Enter the day of month for your cycle",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Day of Month",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter day (1-31)",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.normal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 55, 54, 67),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 218, 75, 92),
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 218, 75, 92),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a day';
                              }
                              final day = int.tryParse(value.trim());
                              if (day == null) {
                                return 'Please enter a valid number';
                              }
                              if (day < 1 || day > 31) {
                                return 'Day must be between 1 and 31';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Current: Day $dayOfMonth",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      final newDay = int.tryParse(
                                        controller.text.trim(),
                                      );
                                      if (newDay != null) {
                                        final uid = FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid;
                                        await FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(uid)
                                            .update({"dayOfMonth": newDay});

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Day of month updated to $newDay",
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setState(() {
                                        isLoading = false;
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  "Failed to update day. Try again.",
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  218,
                                                  75,
                                                  92,
                                                ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                55,
                                54,
                                67,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> inputIncome(BuildContext context, dynamic currentIncome) async {
  final controller = TextEditingController(
    text: currentIncome == null ? '' : currentIncome.toString(),
  );
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final v = context.vesta;
          return AlertDialog(
            title: Row(
              children: [
                Icon(PhosphorIconsRegular.handCoins, color: v.accentInk),
                const SizedBox(width: VestaSpace.sm),
                const Text("Monthly income"),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your budget plan splits this amount each cycle.",
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: amountStyle(16),
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixText: "JOD ",
                      hintText: "Enter amount",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount < 0) {
                        return 'Amount must be 0 or greater';
                      }
                      if (amount > 999999) {
                        return 'Amount is too large';
                      }
                      return null;
                    },
                  ),
                  if (currentIncome is num && currentIncome > 0) ...[
                    const SizedBox(height: VestaSpace.sm),
                    Text(
                      "Current: JOD ${currentIncome.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final newValue = double.tryParse(
                            controller.text.trim(),
                          );
                          if (newValue != null) {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(uid)
                                .update({"totalIncome": newValue});

                            if (context.mounted) {
                              Navigator.pop(context);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Income updated to JOD ${newValue.toStringAsFixed(0)}",
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Failed to update income. Try again.",
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<double?> inputHouseholBudget(
  BuildContext context,
  String householdId,
  double currentBudget,
) async {
  final controller = TextEditingController(text: currentBudget.toString());
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  double? result;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final v = dialogContext.vesta;
          return AlertDialog(
            title: Row(
              children: [
                Icon(PhosphorIconsRegular.wallet, color: v.accentInk),
                const SizedBox(width: VestaSpace.sm),
                const Text("Household budget"),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "How much the household plans to spend this month.",
                    style: TextStyle(fontSize: 13, color: v.muted),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: amountStyle(16),
                    decoration: const InputDecoration(
                      labelText: "Budget",
                      prefixText: "JOD ",
                      hintText: "Enter amount",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null) return 'Invalid number';
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      if (amount > 999999) {
                        return 'Amount is too large';
                      }
                      return null;
                    },
                  ),
                  if (currentBudget > 0) ...[
                    const SizedBox(height: VestaSpace.sm),
                    Text(
                      "Current: JOD ${currentBudget.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final newValue = double.tryParse(
                            controller.text.trim(),
                          );
                          if (newValue != null) {
                            await FirebaseFirestore.instance
                                .collection("households")
                                .doc(householdId)
                                .update({"budget": newValue});

                            result = newValue;
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Failed to update budget. Try again.",
                              ),
                              backgroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );

  return result;
}

// ==================== Filter Dropdown ====================
class AccountFilterDropdown extends StatelessWidget {
  const AccountFilterDropdown({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final List<AccountInfo> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterDropdownShell<String?>(
      value: selectedAccountId,
      hintIcon: PhosphorIconsRegular.wallet,
      hintText: 'All accounts',
      items: [
        const _FilterItem(null, 'All accounts', PhosphorIconsRegular.wallet),
        ...accounts.map(
          (acc) => _FilterItem(acc.id, acc.label, PhosphorIconsRegular.bank),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class CategoryFilterDropdown extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategoryFilterDropdown({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FilterDropdownShell<String?>(
      value: selectedCategory,
      hintIcon: PhosphorIconsRegular.funnelSimple,
      hintText: 'All categories',
      items: [
        const _FilterItem(
          null,
          'All categories',
          PhosphorIconsRegular.funnelSimple,
        ),
        ...categories.map((cat) => _FilterItem(cat, cat, categoryIcon(cat))),
      ],
      onChanged: onChanged,
    );
  }
}

class _FilterItem<T> {
  const _FilterItem(this.value, this.label, this.icon);

  final T value;
  final String label;
  final IconData icon;
}

/// Outlined dropdown used by the transaction filters.
class _FilterDropdownShell<T> extends StatelessWidget {
  const _FilterDropdownShell({
    required this.value,
    required this.hintIcon,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final IconData hintIcon;
  final String hintText;
  final List<_FilterItem<T>> items;
  final ValueChanged<T> onChanged;

  Widget _row(BuildContext context, IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: v.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          // Wider than the half-width button so labels like
          // "Arab Bank · Savings" aren't cut off in the open menu.
          menuWidth: 260,
          borderRadius: BorderRadius.circular(VestaRadius.button),
          dropdownColor: scheme.surfaceContainer,
          hint: _row(context, hintIcon, hintText, v.muted),
          icon: Icon(PhosphorIconsRegular.caretDown, size: 14, color: v.muted),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item.value,
                child: _row(context, item.icon, item.label, scheme.onSurface),
              ),
          ],
          onChanged: (picked) => onChanged(picked as T),
        ),
      ),
    );
  }
}

// ==================== Transaction Card ====================

class TransactionCard extends StatefulWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onCategoryChanged,
    this.onDeleted,
    this.accountName,
    this.showDate = true,
  });

  final TransactionModel transaction;
  final VoidCallback? onCategoryChanged;
  final VoidCallback? onDeleted;

  /// Display name of the transaction's account, when the caller has it.
  final String? accountName;

  /// False when the list already groups transactions under date headings.
  final bool showDate;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isUpdating = false;

  String get _title {
    final t = widget.transaction;
    for (final s in [t.merchantName, t.description, t.category]) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return t.isDebit ? 'Expense' : 'Income';
  }

  String? get _accountText {
    final name = widget.accountName ?? widget.transaction.accountLabel;
    return name != null && name.isNotEmpty ? name : null;
  }

  String get _subtitle {
    final t = widget.transaction;
    final category = t.category != null && t.category!.isNotEmpty
        ? t.category!
        : 'Uncategorized';
    return widget.showDate ? '$category · ${shortDateLabel(t.date)}' : category;
  }

  num get _signedAmount =>
      widget.transaction.isDebit ? -widget.transaction.amount : widget.transaction.amount;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return InkWell(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(categoryIcon(t.category)),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_accountText != null)
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.bank,
                          size: 12,
                          color: context.vesta.muted,
                        ),
                        const SizedBox(width: VestaSpace.xs),
                        Flexible(
                          child: Text(
                            _accountText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: VestaSpace.sm),
            _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : MoneyText(
                    _signedAmount,
                    currency: t.currency,
                    showPlus: true,
                    color: t.isDebit ? null : context.vesta.pos,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCategoryChanged(String? value) async {
    if (value == null) return;
    setState(() => _isUpdating = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user logged in");

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final txnRef = userRef
          .collection('accounts')
          .doc(widget.transaction.accountId)
          .collection('transactions')
          .doc(widget.transaction.id);

      final batch = FirebaseFirestore.instance.batch();
      final oldCategory = widget.transaction.category;
      final amount = widget.transaction.amount;

      if (value == "Unassign") {
        // remove from old category total
        if (oldCategory != null && oldCategory.isNotEmpty) {
          final oldRef = userRef.collection('categories').doc(oldCategory);
          final oldSnap = await oldRef.get();
          if (oldSnap.exists) {
            final total = (oldSnap.data()?['total'] ?? 0).toDouble();
            batch.update(oldRef, {'total': total - amount});
          }
        }

        // remove category field from transaction
        batch.update(txnRef, {'category': FieldValue.delete()});
        // local state
        setState(() => widget.transaction.category = null);
      } else {
        // update category on transaction
        batch.update(txnRef, {'category': value});

        final newRef = userRef.collection('categories').doc(value);
        final newSnap = await newRef.get();
        if (newSnap.exists) {
          final total = (newSnap.data()?['total'] ?? 0).toDouble();
          batch.update(newRef, {'total': total + amount});
        } else {
          final inferredBucket = inferBucketFromCategoryName(value);
          batch.set(newRef, {
            'total': amount,
            'type': widget.transaction.isDebit ? 'expense' : 'income',
            'bucket': inferredBucket,
            'name': value,
          });
        }

        // local state
        setState(() => widget.transaction.category = value);
      }

      // ❗ actually write to Firestore
      await batch.commit();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Updated category to $value")));
      widget.onCategoryChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteTransaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await deleteTransactionAndRevertBalance(
      uid: uid,
      accountId: widget.transaction.accountId,
      transactionId: widget.transaction.id,
      type: widget.transaction.type,
      amount: widget.transaction.amount,
    );
    await calcTotalBalance();
  }

  void _showDetailsSheet(BuildContext context) {
    final isDebit = widget.transaction.isDebit;
    final typeLabel = isDebit ? "Expense" : "Income";
    final sourceLabel = widget.transaction.source.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final v = sheetContext.vesta;
          final current = widget.transaction.category;
          final labels = categoryLabels.toSet().toList();

          // Category changes go through _onCategoryChanged as before; the
          // sheet just redraws when it starts and when it finishes.
          Future<void> pick(String value) async {
            final update = _onCategoryChanged(value);
            setSheet(() {});
            await update;
            if (sheetContext.mounted) setSheet(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                0,
                VestaSpace.gutter,
                VestaSpace.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        categoryIcon(current),
                        size: 48,
                        circle: false,
                      ),
                      const SizedBox(width: VestaSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headingStyle(17),
                            ),
                            Text(
                              _subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VestaSpace.sm),
                      MoneyText(
                        _signedAmount,
                        currency: widget.transaction.currency,
                        size: 17,
                        showPlus: true,
                        color: isDebit ? null : v.pos,
                      ),
                    ],
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  VestaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Category',
                                style: Theme.of(sheetContext).textTheme.bodySmall,
                              ),
                            ),
                            if (_isUpdating)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (current != null && current.isNotEmpty)
                              GestureDetector(
                                onTap: () => pick("Unassign"),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(fontSize: 12, color: v.accentInk),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: VestaSpace.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final label in labels)
                              ChoiceTag(
                                label: label,
                                icon: categoryIcon(label),
                                selected: current == label,
                                onTap: _isUpdating || current == label
                                    ? null
                                    : () => pick(label),
                              ),
                          ],
                        ),
                        const SizedBox(height: VestaSpace.lg),
                        _info(sheetContext, "Type", typeLabel),
                        _info(
                          sheetContext,
                          "Merchant",
                          widget.transaction.merchantName ?? "—",
                        ),
                        _info(sheetContext, "Account", _accountText ?? "—"),
                        _info(sheetContext, "Source", sourceLabel),
                        if (widget.transaction.description?.isNotEmpty == true)
                          _info(
                            sheetContext,
                            "Description",
                            widget.transaction.description!,
                          ),
                        _info(
                          sheetContext,
                          "Date",
                          _formatDateInDetails(widget.transaction.date),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  FutureBuilder<bool>(
                    future: _checkForHouseholds(),
                    builder: (context, snapshot) {
                      if (snapshot.data != true) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlineButton(
                          label: 'Assign to household',
                          onPressed: () => _showAssignToHouseholdSheet(context),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: v.neg,
                        side: BorderSide(color: v.neg.withValues(alpha: 0.6)),
                      ),
                      onPressed: () {
                        _deleteTransaction()
                            .then((_) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Transaction deleted"),
                                ),
                              );
                              widget.onDeleted?.call();
                            })
                            .catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error deleting transaction: $e",
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            });
                      },
                      child: const Text('Delete transaction'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _info(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(title, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateInDetails(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return "—";
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}, "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showAssignToHouseholdSheet(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load user households
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final householdIds = List<String>.from(data?['householdIds'] ?? []);

    if (householdIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not part of any household.")),
        );
      }
      return;
    }

    // Fetch household details
    final householdDocs = await FirebaseFirestore.instance
        .collection('households')
        .where(FieldPath.documentId, whereIn: householdIds)
        .get();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          VestaSpace.gutter,
          0,
          VestaSpace.gutter,
          VestaSpace.gutter,
        ),
        children: [
          Text("Assign to household", style: headingStyle(17)),
          const SizedBox(height: 12),
          ...householdDocs.docs.map((doc) {
            final data = doc.data();
            final name = data['householdName'] ?? 'Unnamed Household';
            final householdId = doc.id;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.houseLine),
              title: Text(name),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final transactionRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('accounts')
                    .doc(widget.transaction.accountId)
                    .collection('transactions')
                    .doc(widget.transaction.id);

                final transactionSnapshot = await transactionRef.get();

                if (!transactionSnapshot.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction not found")),
                  );
                  return;
                }

                final transactionData = transactionSnapshot.data()!;

                final householdTransactionData = {
                  ...transactionData,
                  'assignedBy': user.uid,
                  'assignedAt': FieldValue.serverTimestamp(),
                  'originalTransactionId': widget.transaction.id,
                };

                await FirebaseFirestore.instance
                    .collection('households')
                    .doc(householdId)
                    .collection('transactions')
                    .doc(widget.transaction.id)
                    .set(householdTransactionData, SetOptions(merge: true));

                await transactionRef.update({'householdId': householdId});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Assigned to '$name' successfully!"),
                    ),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

// ==================== Household Transaction Card View ====================

class HouseholdTransactionCard extends StatefulWidget {
  const HouseholdTransactionCard({
    super.key,
    required this.transaction,
    required this.householdId,
    this.onCategoryChanged,
    this.onDeleted,
  });

  final HouseholdTransactionModel transaction;
  final String householdId;
  final VoidCallback? onCategoryChanged;
  final VoidCallback? onDeleted;

  @override
  State<HouseholdTransactionCard> createState() =>
      _HouseholdTransactionCardState();
}

class _HouseholdTransactionCardState extends State<HouseholdTransactionCard> {
  bool _isUpdating = false;
  String? _addedByName;

  @override
  void initState() {
    super.initState();
    _fetchAddedByName();
  }

  String get _title {
    final t = widget.transaction;
    for (final s in [t.merchantName, t.description, t.category]) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return t.isDebit ? 'Expense' : 'Income';
  }

  String get _subtitle {
    final t = widget.transaction;
    final category = t.category != null && t.category!.isNotEmpty
        ? t.category!
        : 'Uncategorized';
    return '$category · ${shortDateLabel(t.date)}';
  }

  num get _signedAmount => widget.transaction.isDebit
      ? -widget.transaction.amount
      : widget.transaction.amount;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final v = context.vesta;
    return InkWell(
      onTap: () => _showDetailsSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(categoryIcon(t.category)),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_addedByName != null)
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.user, size: 12, color: v.muted),
                        const SizedBox(width: VestaSpace.xs),
                        Flexible(
                          child: Text(
                            _addedByName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: VestaSpace.sm),
            _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : MoneyText(
                    _signedAmount,
                    currency: t.currency,
                    showPlus: true,
                    color: t.isDebit ? null : v.pos,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAddedByName() async {
    final addedByUid = widget.transaction.assignedBy;
    if (addedByUid == null || addedByUid.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(addedByUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final username =
            userData?['username'] ??
            userData?['displayName'] ??
            userData?['email'] ??
            addedByUid;

        if (mounted) {
          setState(() => _addedByName = username);
        }
      } else {
        if (mounted) setState(() => _addedByName = addedByUid);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching addedBy name: $e");
      if (mounted) setState(() => _addedByName = addedByUid);
    }
  }

  /// 🏷️ Category Update - Updates the household transaction
  Future<void> _onCategoryChanged(String? value) async {
    if (value == null) return;
    setState(() => _isUpdating = true);

    try {
      // Reference to the household transaction
      final txnRef = FirebaseFirestore.instance
          .collection('households')
          .doc(widget.householdId)
          .collection('transactions')
          .doc(widget.transaction.id);

      if (value == "Unassign") {
        await txnRef.update({'category': FieldValue.delete()});
        setState(() => widget.transaction.category = null);
      } else {
        await txnRef.update({'category': value});
        setState(() => widget.transaction.category = value);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Updated category to $value")));
      widget.onCategoryChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  /// 📋 Transaction Details Sheet
  Future<void> _deleteTransaction() async {
    await FirebaseFirestore.instance
        .collection('households')
        .doc(widget.householdId)
        .collection('transactions')
        .doc(widget.transaction.id)
        .delete();
  }

  void _showDetailsSheet(BuildContext context) {
    final isDebit = widget.transaction.isDebit;
    final typeLabel = isDebit ? "Expense" : "Income";
    final sourceLabel = widget.transaction.source.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final v = sheetContext.vesta;
          final current = widget.transaction.category;

          // Category changes go through _onCategoryChanged as before; the
          // sheet just redraws when it starts and when it finishes.
          Future<void> pick(String value) async {
            final update = _onCategoryChanged(value);
            setSheet(() {});
            await update;
            if (sheetContext.mounted) setSheet(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VestaSpace.gutter,
                0,
                VestaSpace.gutter,
                VestaSpace.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconBadge(categoryIcon(current), size: 48, circle: false),
                      const SizedBox(width: VestaSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headingStyle(17),
                            ),
                            Text(
                              _subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VestaSpace.sm),
                      MoneyText(
                        _signedAmount,
                        currency: widget.transaction.currency,
                        size: 17,
                        showPlus: true,
                        color: isDebit ? null : v.pos,
                      ),
                    ],
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  VestaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Category',
                                style: Theme.of(sheetContext).textTheme.bodySmall,
                              ),
                            ),
                            if (_isUpdating)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (current != null && current.isNotEmpty)
                              GestureDetector(
                                onTap: () => pick("Unassign"),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(fontSize: 12, color: v.accentInk),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: VestaSpace.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final label in categoryLabels)
                              ChoiceTag(
                                label: label,
                                icon: categoryIcon(label),
                                selected: current == label,
                                onTap: _isUpdating || current == label
                                    ? null
                                    : () => pick(label),
                              ),
                          ],
                        ),
                        const SizedBox(height: VestaSpace.lg),
                        _info(sheetContext, "Type", typeLabel),
                        _info(
                          sheetContext,
                          "Merchant",
                          widget.transaction.merchantName ?? "—",
                        ),
                        _info(
                          sheetContext,
                          "Account",
                          widget.transaction.accountLabel ?? "—",
                        ),
                        _info(sheetContext, "Source", sourceLabel),
                        if (widget.transaction.description?.isNotEmpty == true)
                          _info(
                            sheetContext,
                            "Description",
                            widget.transaction.description!,
                          ),
                        if (_addedByName != null)
                          _info(sheetContext, "Added by", _addedByName!),
                        _info(
                          sheetContext,
                          "Date",
                          _formatDateInDetails(widget.transaction.date),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VestaSpace.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: v.neg,
                        side: BorderSide(color: v.neg.withValues(alpha: 0.6)),
                      ),
                      onPressed: () {
                        _deleteTransaction()
                            .then((_) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Transaction deleted"),
                                ),
                              );
                              widget.onDeleted?.call();
                            })
                            .catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error deleting transaction: $e",
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            });
                      },
                      child: const Text('Remove from household'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _info(BuildContext context, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(title, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? "—" : value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );

  static String _formatDateInDetails(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return "—";
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}, "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }
}

// ==================== Error View ====================
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _StateMessage(
          icon: PhosphorIconsRegular.warningCircle,
          iconColor: context.vesta.neg,
          title: "Couldn't load transactions",
          message: message,
          actionLabel: "Retry",
          onAction: onRetry,
        ),
      ),
    );
  }
}

// ==================== Empty States ====================
class EmptyTransactionsState extends StatelessWidget {
  const EmptyTransactionsState({super.key, required this.onSync});

  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: PhosphorIconsRegular.receipt,
      title: "No transactions yet",
      message: "Tap + to add your first one.",
      actionLabel: "Refresh",
      onAction: onSync,
    );
  }
}

class EmptyFilterState extends StatelessWidget {
  const EmptyFilterState({super.key, required this.onClearFilter});

  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: PhosphorIconsRegular.funnelSimple,
      title: "No transactions match these filters",
      message: "Try a different account, category or date.",
      actionLabel: "Clear filters",
      onAction: onClearFilter,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VestaSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: iconColor ?? v.muted),
          const SizedBox(height: VestaSpace.md),
          Text(title, textAlign: TextAlign.center, style: headingStyle(17)),
          const SizedBox(height: VestaSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: v.muted),
          ),
          const SizedBox(height: VestaSpace.lg),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// Bottom sheet widget
class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _accounts = [];
  List<String> _categories = [];

  String? _selectedAccountId;
  String? _selectedCategory;
  TransactionType _type = TransactionType.debit;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccountsAndCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccountsAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final uid = user.uid;
      final fire = FirebaseFirestore.instance;

      // Accounts
      final accountsSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      final accounts = accountsSnap.docs.map((d) {
        final data = d.data();
        return {'id': d.id, 'name': data['accountName'] ?? d.id};
      }).toList();

      // Categories
      final categoriesSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      final categories = categoriesSnap.docs.map((d) => d.id).toList();

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categories;
          if (_accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first['id'] as String;
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error loading accounts/categories: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final rawAmount = _amountCtrl.text.trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount.")));
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select an account.")));
      return;
    }

    setState(() => _saving = true);

    try {
      final fire = FirebaseFirestore.instance;

      final txCol = fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(_selectedAccountId)
          .collection('transactions');

      final newDoc = txCol.doc();

      final txn = TransactionModel.manual(
        firestoreAccountId: _selectedAccountId!,
        id: newDoc.id,
        amount: amount,
        currency: "JOD",
        type: _type,
        date: _date,
        merchantName: _merchantCtrl.text.trim().isEmpty
            ? null
            : _merchantCtrl.text.trim(),
        description: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        accountLabel: null,
        category: _selectedCategory,
      );

      await newDoc.set(txn.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Transaction added.")));
      }
    } catch (e) {
      debugPrint("⚠️ Error saving transaction: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const Text(
                    "Add Transaction",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Account
                  if (_accounts.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: "Account",
                        border: OutlineInputBorder(),
                      ),
                      items: _accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a['id'] as String,
                              child: Text(a['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedAccountId = val);
                      },
                    )
                  else
                    const Text(
                      "No accounts found. Sync accounts first.",
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),

                  // Amount
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Type
                  Row(
                    children: [
                      const Text("Type: "),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Debit"),
                        selected: _type == TransactionType.debit,
                        onSelected: (_) {
                          setState(() => _type = TransactionType.debit);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Credit"),
                        selected: _type == TransactionType.credit,
                        onSelected: (_) {
                          setState(() => _type = TransactionType.credit);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date.isAfter(DateTime.now())
                            ? DateTime.now()
                            : _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final now = DateTime.now();
                        setState(() {
                          _date = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            now.hour,
                            now.minute,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Merchant
                  TextField(
                    controller: _merchantCtrl,
                    decoration: const InputDecoration(
                      labelText: "Merchant / From",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category
                  if (_categories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategory = val);
                      },
                    ),
                  if (_categories.isNotEmpty) const SizedBox(height: 10),

                  // Note
                  TextField(
                    controller: _noteCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Note (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  largeButton(
                    context,
                    'Add Transaction',
                    Theme.of(context).colorScheme.secondary,
                    () {
                      if (!_saving) {
                        _save();
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

String homePageGreeting() {
  final now = DateTime.now();
  final hour = now.hour;

  if (hour >= 5 && hour <= 12) {
    return 'Good morning,';
  } else if (hour > 12 && hour < 17) {
    return 'Good afternoon,';
  } else if (hour >= 17 && hour < 21) {
    return 'Good evening,';
  } else {
    return 'Late night,'; // Covers 21:00 to 04:59
  }

}
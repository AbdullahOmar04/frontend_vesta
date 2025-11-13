// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/pages/settings.dart' as app_settings;

import 'dart:async';

/// Dynamic category labels fetched from Firestore per-user.
/// Use `categoryLabelsNotifier` to rebuild UI when categories change,
/// or read the current list via `categoryLabels`.
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
void _startCategoryListener() {
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
    width: double.infinity,
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
            Image.asset(
              logoPath,
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 20),
            Text(
              bankName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget drawer(BuildContext context, String username) {
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
                              prefixIcon: const Icon(Icons.calendar_today),
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
  final controller = TextEditingController(text: currentIncome.toString());
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

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
                  // Header with icon and gradient
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
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Update Total Income",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Enter your monthly income amount",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Monthly Income",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Enhanced TextField
                          TextFormField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    55,
                                    54,
                                    67,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "JOD",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 55, 54, 67),
                                  ),
                                ),
                              ),
                              hintText: "Enter amount",
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
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value.trim());
                              if (amount == null) {
                                return 'Please enter a valid number';
                              }
                              if (amount <= 0) {
                                return 'Amount must be greater than 0';
                              }
                              if (amount > 999999) {
                                return 'Amount is too large';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Current vs New comparison
                          if (currentIncome > 0)
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
                                      "Current: JOD ${currentIncome.toStringAsFixed(0)}",
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

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        // Cancel button
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

                        // Save button
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
                                      final newValue = double.tryParse(
                                        controller.text.trim(),
                                      );
                                      if (newValue != null) {
                                        final uid = FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid;
                                        await FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(uid)
                                            .update({"totalIncome": newValue});

                                        if (context.mounted) {
                                          Navigator.pop(context);

                                          // Show success message
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
                                                    "Income updated to JOD ${newValue.toStringAsFixed(0)}",
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
                                                  "Failed to update income. Try again.",
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedAccountId,
          hint: Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'All Accounts',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('All Accounts', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            ...accounts.map((acc) {
              return DropdownMenuItem<String>(
                value: acc.id,
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        acc.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedCategory,
          hint: Row(
            children: [
              Icon(Icons.filter_alt, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'All Categories',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('All Categories', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            ...categories.map(
              (cat) => DropdownMenuItem<String>(
                value: cat,
                child: Row(
                  children: [
                    const Icon(Icons.label, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
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
  });

  final TransactionModel transaction;
  final VoidCallback? onCategoryChanged;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    _startCategoryListener();
    final isDebit = widget.transaction.isDebit;
    final amountColor = isDebit ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            Row(
              children: [
                Text(
                  "${isDebit ? '- ' : '+ '}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: amountColor,
                  ),
                ),
                const Spacer(),

                // 🔽 Check if there are households, then show a button
                FutureBuilder<bool>(
                  future: _checkForHouseholds(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final hasHouseholds = snapshot.data ?? false;

                    if (!hasHouseholds) {
                      return const SizedBox.shrink();
                    }

                    // ✅ Show the button
                    return TextButton.icon(
                      onPressed: () => _showAssignToHouseholdSheet(context),
                      icon: const Icon(Icons.house_outlined, size: 18),
                      label: const Text("Assign"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),
            // Account + Date
            Row(
              children: [
                Text(
                  "Acc • ${widget.transaction.accountId}",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(widget.transaction.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),

            const SizedBox(height: 10),

            // Category dropdown
            Stack(
              children: [
                DropdownButtonFormField<String>(
                  value: widget.transaction.category?.isNotEmpty == true
                      ? widget.transaction.category
                      : null,
                  hint: const Text("Category"),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: "Unassign",
                      child: Text("Unassign"),
                    ),
                    ...categoryLabels.map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    ),
                  ],
                  onChanged: _isUpdating ? null : _onCategoryChanged,
                ),
                if (_isUpdating)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
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
        if (oldCategory != null && oldCategory.isNotEmpty) {
          final oldRef = userRef.collection('categories').doc(oldCategory);
          final oldSnap = await oldRef.get();
          if (oldSnap.exists) {
            final total = (oldSnap.data()?['total'] ?? 0).toDouble();
            batch.update(oldRef, {'total': total - amount});
          }
        }
        batch.update(txnRef, {'category': FieldValue.delete()});
        await batch.commit();
        setState(() => widget.transaction.category = null);
      } else {
        batch.update(txnRef, {'category': value});
        final newRef = userRef.collection('categories').doc(value);
        final newSnap = await newRef.get();
        if (newSnap.exists) {
          final total = (newSnap.data()?['total'] ?? 0).toDouble();
          batch.update(newRef, {'total': total + amount});
        } else {
          batch.set(newRef, {
            'total': amount,
            'type': widget.transaction.isDebit ? 'expense' : 'income',
          });
        }
        await batch.commit();
        setState(() => widget.transaction.category = value);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Updated category to $value")));
      widget.onCategoryChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
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
            Text(
              "${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: widget.transaction.isDebit ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            _info("From", widget.transaction.fromName),
            _info("To", widget.transaction.toName),
            _info("Status", widget.transaction.status.name),
            _info("Account", widget.transaction.accountId),
            _info("Channel", widget.transaction.channel),
            if (widget.transaction.note?.isNotEmpty == true)
              _info("Note", widget.transaction.note!),
            _info("Date", _formatDateInDetails(widget.transaction.date)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text("$title:")),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
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
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
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
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Assign to Household",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...householdDocs.docs.map((doc) {
            final data = doc.data();
            final name = data['householdName'] ?? 'Unnamed Household';
            final householdId = doc.id; // ✅ define it here

            return ListTile(
              leading: const Icon(Icons.house_rounded),
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
                  ...transactionData, // include all transaction fields
                  'assignedBy': user.uid,
                  'assignedAt': FieldValue.serverTimestamp(),
                  'originalTransactionId': widget.transaction.id,
                };

                // ✅ Write to the household’s transactions collection
                await FirebaseFirestore.instance
                    .collection('households')
                    .doc(householdId)
                    .collection('transactions')
                    .doc(widget.transaction.id)
                    .set(householdTransactionData, SetOptions(merge: true));

                // ✅ Mark this transaction as assigned in the user’s record
                await transactionRef.update({'householdId': householdId});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Assigned to '$name' successfully!"),
                      backgroundColor: Colors.green,
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
    this.onCategoryChanged,
  });

  final HouseholdTransactionModel transaction;
  final VoidCallback? onCategoryChanged;

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

  @override
  Widget build(BuildContext context) {
    final isDebit = widget.transaction.isDebit;
    final amountColor = isDebit ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () => _showDetailsSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// AMOUNT
            Row(
              children: [
                Text(
                  "${isDebit ? '- ' : '+ '}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: amountColor,
                  ),
                ),
                const Spacer(),

                /// ADDED BY
                if (_addedByName != null)
                  Text(
                    "By $_addedByName",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            /// DATE
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(widget.transaction.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),

            const SizedBox(height: 10),

            /// CATEGORY DROPDOWN
            Stack(
              children: [
                DropdownButtonFormField<String>(
                  value: widget.transaction.category?.isNotEmpty == true
                      ? widget.transaction.category
                      : null,
                  hint: const Text("Category"),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: "Unassign",
                      child: Text("Unassign"),
                    ),
                    ...categoryLabels.map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    ),
                  ],
                  onChanged: _isUpdating ? null : _onCategoryChanged,
                ),
                if (_isUpdating)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
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

  /// 🏷️ Category Update
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
        if (oldCategory != null && oldCategory.isNotEmpty) {
          final oldRef = userRef.collection('categories').doc(oldCategory);
          final oldSnap = await oldRef.get();
          if (oldSnap.exists) {
            final total = (oldSnap.data()?['total'] ?? 0).toDouble();
            batch.update(oldRef, {'total': total - amount});
          }
        }
        batch.update(txnRef, {'category': FieldValue.delete()});
        await batch.commit();
        setState(() => widget.transaction.category = null);
      } else {
        batch.update(txnRef, {'category': value});
        final newRef = userRef.collection('categories').doc(value);
        final newSnap = await newRef.get();
        if (newSnap.exists) {
          final total = (newSnap.data()?['total'] ?? 0).toDouble();
          batch.update(newRef, {'total': total + amount});
        } else {
          batch.set(newRef, {
            'total': amount,
            'type': widget.transaction.isDebit ? 'expense' : 'income',
          });
        }
        await batch.commit();
        setState(() => widget.transaction.category = value);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Updated category to $value")));
      widget.onCategoryChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  /// 📋 Transaction Details Sheet
  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
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
            Text(
              "${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: widget.transaction.isDebit ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            _info("From", widget.transaction.fromName),
            _info("To", widget.transaction.toName),
            _info("Status", widget.transaction.status.name),
            _info("Channel", widget.transaction.channel),
            if (widget.transaction.note?.isNotEmpty == true)
              _info("Note", widget.transaction.note!),
            _info("Date", _formatDateInDetails(widget.transaction.date)),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text("$title:")),
        Expanded(
          child: Text(
            value.isEmpty ? "—" : value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  static String _formatDate(DateTime dt) {
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
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
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
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Failed to load transactions",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
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
    return Column(
      children: [
        Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          "No transactions yet",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Pull down to refresh or sync with your bank.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onSync,
          icon: const Icon(Icons.sync),
          label: const Text("Sync Now"),
        ),
      ],
    );
  }
}

class EmptyFilterState extends StatelessWidget {
  const EmptyFilterState({super.key, required this.onClearFilter});

  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.filter_list_off, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          "No transactions found",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Try selecting a different account or clear the filter.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onClearFilter,
          icon: const Icon(Icons.clear),
          label: const Text("Clear Filter"),
        ),
      ],
    );
  }
}

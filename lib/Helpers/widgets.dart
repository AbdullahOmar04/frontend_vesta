// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/pages/settings.dart' as app_settings;

const List<String> categoryLabels = [
  'Food And Drinks',
  'Groceries',
  'Entertainment',
  'Others',
];

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
                                    if (!formKey.currentState!.validate())
                                      return;

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
                                    if (!formKey.currentState!.validate())
                                      return;

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

Widget circularCategory(Color color, IconData icon, String text) {
  return Column(
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
      Text(text, style: TextStyle(fontSize: 12)),
    ],
  );
}

// ==================== Transaction Card ====================
// Define your categories

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
    final amountStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: widget.transaction.isDebit
          ? Colors.red.shade600
          : Colors.green.shade600,
    );

    final statusColor = _getStatusColor(widget.transaction.status);
    final statusBg = statusColor.withOpacity(0.12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountAndStatus(amountStyle, statusColor, statusBg),
          const SizedBox(height: 8),
          _buildTransactionParties(),
          const SizedBox(height: 6),
          _buildChannelAndAccount(),
          if (widget.transaction.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            _buildNote(),
          ],
          const SizedBox(height: 10),
          _buildDate(),
          const SizedBox(height: 10),
          _buildCategoryDropdown(context),
        ],
      ),
    );
  }

  Widget _buildAmountAndStatus(
    TextStyle amountStyle,
    Color statusColor,
    Color statusBg,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "${widget.transaction.isDebit ? "- " : "+ "}"
            "${widget.transaction.amount.toStringAsFixed(2)} "
            "${widget.transaction.currency}",
            style: amountStyle,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(widget.transaction.status),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionParties() {
    final fromName = widget.transaction.fromName.isEmpty
        ? 'Unknown'
        : widget.transaction.fromName;
    final toName = widget.transaction.toName.isEmpty
        ? 'Unknown'
        : widget.transaction.toName;

    return Row(
      children: [
        const Icon(Icons.swap_horiz, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "$fromName → $toName",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChannelAndAccount() {
    return Row(
      children: [
        const Icon(Icons.account_balance, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            widget.transaction.channel.isEmpty
                ? "—"
                : widget.transaction.channel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.credit_card, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            "Acc • ${widget.transaction.accountId}",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.notes, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.transaction.note!,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDate() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Text(
        _formatDate(widget.transaction.date),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: widget.transaction.category?.isNotEmpty == true
              ? widget.transaction.category
              : null,
          hint: const Text("Assign category"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: widget.transaction.category?.isNotEmpty == true
                ? Icon(
                    _getIconForCategory(widget.transaction.category!),
                    size: 20,
                    color: _getColorForCategory(widget.transaction.category!),
                  )
                : const Icon(
                    Icons.category_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: "Unassign",
              child: Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 8),
                  Text("Unassign"),
                ],
              ),
            ),
            ...categoryLabels.map(
              (label) => DropdownMenuItem<String>(
                value: label,
                child: Row(
                  children: [
                    Icon(
                      _getIconForCategory(label),
                      size: 18,
                      color: _getColorForCategory(label),
                    ),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _isUpdating ? null : (value) => _onCategoryChanged(value),
        ),

        // 🔄 Overlay when updating
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onCategoryChanged(String? value) async {
    if (value == null) return;

    setState(() => _isUpdating = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user logged in");

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final txnAmount = widget.transaction.amount;
      final txnId = widget.transaction.id;
      final oldCategory = widget.transaction.category;

      final batch = FirebaseFirestore.instance.batch();

      final txnRef = userRef
          .collection('accounts')
          .doc(widget.transaction.accountId)
          .collection('transactions')
          .doc(txnId);

      // 🟣 UNASSIGN LOGIC
      if (value == "Unassign") {
        // Remove from old category totals if exists
        if (oldCategory != null && oldCategory.isNotEmpty) {
          final oldCategoryRef = userRef
              .collection('categories')
              .doc(oldCategory);
          final oldSnap = await oldCategoryRef.get();

          if (oldSnap.exists) {
            final currentTotal = (oldSnap.data()?['total'] ?? 0).toDouble();
            final newTotal = (currentTotal - txnAmount).clamp(
              0.0,
              double.infinity,
            );
            batch.update(oldCategoryRef, {'total': newTotal});
          }
        }

        // Clear from the transaction itself
        batch.update(txnRef, {'category': FieldValue.delete()});

        await batch.commit();

        setState(() => widget.transaction.category = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaction unassigned successfully"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        widget.onCategoryChanged?.call();
        return;
      }

      // 🟢 NORMAL CATEGORY ASSIGNMENT

      // 1. Update transaction
      batch.update(txnRef, {'category': value});

      // 2. Deduct from old category total
      if (oldCategory != null && oldCategory.isNotEmpty) {
        final oldRef = userRef.collection('categories').doc(oldCategory);
        final oldSnap = await oldRef.get();

        if (oldSnap.exists) {
          final currentTotal = (oldSnap.data()?['total'] ?? 0).toDouble();
          final newTotal = (currentTotal - txnAmount).clamp(
            0.0,
            double.infinity,
          );
          batch.update(oldRef, {'total': newTotal});
        }
      }

      // 3. Add to new category total
      final newRef = userRef.collection('categories').doc(value);
      final newSnap = await newRef.get();

      if (newSnap.exists) {
        final currentTotal = (newSnap.data()?['total'] ?? 0).toDouble();
        batch.update(newRef, {'total': currentTotal + txnAmount});
      } else {
        batch.set(newRef, {
          'total': txnAmount,
          'type': widget.transaction.isDebit ? 'expense' : 'income',
        });
      }

      await batch.commit();

      setState(() => widget.transaction.category = value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Assigned to $value"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onCategoryChanged?.call();
    } catch (e) {
      debugPrint("⚠️ Category update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  static Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.accepted:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
    }
  }

  static String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.accepted:
        return "Accepted";
      case TransactionStatus.rejected:
        return "Rejected";
      case TransactionStatus.pending:
        return "Pending";
    }
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

    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";

    return "$month $day, $year • $hour:$min $ampm";
  }

  static IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case "food and drinks":
        return Icons.restaurant;
      case "groceries":
        return Icons.shopping_bag;
      case "entertainment":
        return Icons.movie;

      default:
        return Icons.category;
    }
  }

  static Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case "food and drinks":
        return Colors.blue;
      case "groceries":
        return Colors.amber;
      case "entertainment":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ==================== Sync Status Banner ====================
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    required this.syncedAccounts,
    required this.totalAccounts,
  });

  final int syncedAccounts;
  final int totalAccounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Syncing $syncedAccounts/$totalAccounts accounts...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
